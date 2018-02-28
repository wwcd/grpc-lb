# 说明

[gRPC服务发现&负载均衡](https://segmentfault.com/a/1190000008672912)中的例子, 修订如下问题

- register中重复PUT, watch时没有释放导致的内存泄漏
- 不能正常unregister

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

## 编译启动测试程序

    go build cmd/cli
    go build cmd/svr

    # 分别启动服务端
    ./svr -port 50001
    ./svr -port 50002
    ./svr -port 50003

    # 启动客户端
    ./cli
