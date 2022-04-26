FROM debian
RUN apt-get upgrade -y && apt-get update -y && \
    apt-get install make gcc nano unzip wget curl git -y 

# create workspace
RUN mkdir /workspace

ADD installers installers

# install go version 1.17
RUN chmod +x installers/go_installer.sh
RUN /bin/bash -c installers/go_installer.sh
ENV PATH "/usr/local/go/bin:$PATH"
ENV GOPATH "/opt/go/"
ENV PATH "$PATH:$GOPATH/bin"

# build krakend api gateway
RUN chmod +x installers/krakend_installer.sh
RUN /bin/bash -c installers/krakend_installer.sh

# init new golang modeule
RUN mkdir /workspace/src && \
    cd /workspace/src && \
    go mod init bitbucket.com/boligmappa/apigateway

ADD src/tools.go /workspace/src
RUN cd /workspace/src && go mod tidy -compat=1.17 && go install \
    github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway \
    github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2 \
    google.golang.org/protobuf/cmd/protoc-gen-go \
    google.golang.org/grpc/cmd/protoc-gen-go-grpc

# copy source
ADD src/gateway /workspace/src/gateway
ADD src/plugin /workspace/src/plugin
ADD src/protos /workspace/src/protos

# install protoc and buf
RUN chmod +x installers/protoc_installer.sh
RUN chmod +x installers/buf_installer.sh
RUN /bin/bash -c installers/protoc_installer.sh && \
    /bin/bash -c installers/buf_installer.sh

# generate grpc handlers for grpc gateway
RUN cd /workspace/src/protos && buf mod update
RUN cd /workspace/src/protos && buf generate

# these golang modules needs to be changed
RUN cd /workspace/src && go get google.golang.org/grpc@v1.40.0
RUN cd /workspace/src && go get google.golang.org/protobuf@v1.27.1
RUN cd /workspace/src && go get google.golang.org/genproto@v0.0.0-20210831024726-fe130286e0e2
RUN cd /workspace/src && go get github.com/devopsfaith/krakend-ce/v2

# update modules and build pluging
RUN cd /workspace/src && go mod tidy -v
RUN cd /workspace/src && go build -buildmode=plugin -o grpc-gateway.so ./plugin

# run krakend api gateway
ADD src/krakend.json /workspace/src
CMD ["/workspace/krakend/krakend","run", "-d", "-c", "/workspace/src/krakend.json"]

# build image -> docker build -t <IMAGE>:<TAG> <path to Dockerfile>
# run container -> docker run --rm -ti <IMAGE>:<TAG> /bin/bash
