package gateway

import (
	"context"
	"net/http"

	"github.com/grpc-ecosystem/grpc-gateway/v2/runtime"
	"google.golang.org/grpc"

	pb "bitbucket.com/boligmappa/apigateway/protos/gen/go"
)

func New(ctx context.Context, typeEndpoint string) (http.Handler, error) {
	gw := runtime.NewServeMux()
	opts := []grpc.DialOption{grpc.WithInsecure()}

	if err := pb.RegisterTypeGrpcServiceHandlerFromEndpoint(ctx, gw, typeEndpoint, opts); err != nil {
		return nil, err
	}

	return gw, nil
}
