#!/bin/bash

# disable go mod
export GO111MODULE=off

GOGO_PROTO_TAG="v1.2.1"
GRPC_GATEWAY_TAG="v1.9.2"


PROTOC_ROOT="/opt/protoc"
GOGOPROTO_ROOT="${GOPATH}/src/github.com/gogo/protobuf"
GOGOPROTO_PATH="${GOGOPROTO_ROOT}:${GOGOPROTO_ROOT}/protobuf"
GRPC_GATEWAY_ROOT="${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway"

go get -u github.com/gogo/protobuf/{proto,protoc-gen-gogo,gogoproto}
pushd "${GOGOPROTO_ROOT}"
    git reset --hard "${GOGO_PROTO_TAG}"
    go install ./proto
    go install ./protoc-gen-gogo
    go install ./gogoproto
popd

go get -u github.com/grpc-ecosystem/grpc-gateway/{protoc-gen-grpc-gateway,protoc-gen-swagger}
pushd "${GRPC_GATEWAY_ROOT}"
    git reset --hard "${GRPC_GATEWAY_TAG}"
    go install ./protoc-gen-grpc-gateway
    go install ./protoc-gen-swagger
popd

DIRS="./"

for dir in ${DIRS}; do
    pushd "${dir}"
    ${PROTOC_ROOT}/bin/protoc -I".:${PROTOC_ROOT}/include:${GOGOPROTO_PATH}:${GRPC_GATEWAY_ROOT}/third_party/googleapis" ./*.proto --go_out=plugins=grpc:.
    ${PROTOC_ROOT}/bin/protoc -I".:${PROTOC_ROOT}/include:${GOGOPROTO_PATH}:${GRPC_GATEWAY_ROOT}/third_party/googleapis" ./*.proto --swagger_out=logtostderr=true:. --grpc-gateway_out=logtostderr=true:.
    popd
done
