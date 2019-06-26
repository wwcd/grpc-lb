
[![Build Status](https://travis-ci.org/wwcd/grpc-lb.svg?branch=master)](https://travis-ci.org/wwcd/grpc-lb)

# 说明

[gRPC服务发现&负载均衡](https://segmentfault.com/a/1190000008672912)中的例子, 修订如下

- register中重复PUT, watch时没有释放导致的内存泄漏
- 退出时不能正常unregister
- 接收到etcd的delete事件时，未删除数据[#1](https://github.com/wwcd/grpc-lb/issues/1)
- 使用resolver包替换naming包，此包状态已变为Deprecated
- 增加[grpc-gateway](https://github.com/grpc-ecosystem/grpc-gateway)例子

# 测试

## 启动ETCD

	# https://coreos.com/etcd/docs/latest/op-guide/container.html#docker

	export NODE1=192.168.1.21

	docker volume create --name etcd-data
	export DATA_DIR="etcd-data"

	REGISTRY=quay.io/coreos/etcd
	# available from v3.2.5
	# REGISTRY=gcr.io/etcd-development/etcd

	docker run -d\
	  -p 2379:2379 \
	  -p 2380:2380 \
	  --volume=${DATA_DIR}:/etcd-data \
	  --name etcd ${REGISTRY}:latest \
	  /usr/local/bin/etcd \
	  --data-dir=/etcd-data --name node1 \
	  --initial-advertise-peer-urls http://${NODE1}:2380 --listen-peer-urls http://0.0.0.0:2380 \
	  --advertise-client-urls http://${NODE1}:2379 --listen-client-urls http://0.0.0.0:2379 \
	  --initial-cluster node1=http://${NODE1}:2380

## 启动测试程序

    *注: golang1.11以上版本进行测试*

    # 分别启动服务端
    go run -mod vendor cmd/svr/svr.go -port 50001
    go run -mod vendor cmd/svr/svr.go -port 50002
    go run -mod vendor cmd/svr/svr.go -port 50003

    # 启动客户端
    go run -mod vendor cmd/cli/cli.go


    # 启动grpc-gateway代理，提供HTTP-RESTful服务
    go run -mod vendor cmd/gw/gw.go
    curl -X POST http://localhost:60001/hello -d '{"name": "fromGW"}'
