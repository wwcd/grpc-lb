package etcdv3

import (
	"context"
	"fmt"
	"net"
	"strings"
	"time"

	"github.com/coreos/etcd/clientv3"
)

// Prefix should start and end with no slash
var Deregister = make(chan struct{})

// Register
func Register(target, service, host, port string, interval time.Duration, ttl int) error {
	serviceValue := net.JoinHostPort(host, port)
	serviceKey := fmt.Sprintf("/%s/%s/%s", schema, service, serviceValue)

	// get endpoints for register dial address
	var err error
	cli, err := clientv3.New(clientv3.Config{
		Endpoints: strings.Split(target, ","),
	})
	if err != nil {
		return fmt.Errorf("grpclb: create clientv3 client failed: %v", err)
	}
	resp, err := cli.Grant(context.TODO(), int64(ttl))
	if err != nil {
		return fmt.Errorf("grpclb: create clientv3 lease failed: %v", err)
	}

	if _, err := cli.Put(context.TODO(), serviceKey, serviceValue, clientv3.WithLease(resp.ID)); err != nil {
		return fmt.Errorf("grpclb: set service '%s' with ttl to clientv3 failed: %s", service, err.Error())
	}

	if _, err := cli.KeepAlive(context.TODO(), resp.ID); err != nil {
		return fmt.Errorf("grpclb: refresh service '%s' with ttl to clientv3 failed: %s", service, err.Error())
	}

	// wait deregister then delete
	go func() {
		<-Deregister
		cli.Delete(context.Background(), serviceKey)
		Deregister <- struct{}{}
	}()

	return nil
}

// UnRegister delete registered service from etcd
func UnRegister() {
	Deregister <- struct{}{}
	<-Deregister
}
