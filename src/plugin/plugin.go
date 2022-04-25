package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/http"

	"bitbucket.com/boligmappa/apigateway/gateway"
)

// ClientRegisterer is the symbol the plugin loader will try to load. It must implement the RegisterClient interface
var ClientRegisterer registrable = registrable("grpc-services")

type registrable string

func (r registrable) RegisterClients(f func(
	name string,
	handler func(context.Context, map[string]interface{}) (http.Handler, error),
)) {
	f(string(r), r.registerClients)
}

func (r registrable) registerClients(ctx context.Context, extra map[string]interface{}) (http.Handler, error) {

	name, ok := extra["name"].(string)

	if !ok {
		return nil, errors.New("wrong config")
	}

	if name != string(r) {
		return nil, fmt.Errorf("unknown register %s", name)
	}

	rawEs, ok := extra["endpoints"]
	if !ok {
		return nil, errors.New("empty endpoints 1")
	}
	es, ok := rawEs.([]interface{})
	if !ok {
		return nil, errors.New("empty endpoints 2")
	}
	endpoints := make([]string, len(es))
	for i, e := range es {
		endpoints[i] = e.(string)
		log.Printf("endpoint logs: %s", endpoints[0])
	}

	fmt.Printf("ctx: %v\n", ctx)

	return gateway.New(ctx, endpoints[0])
}

func init() {
	fmt.Println("krakend-example client plugin loaded!!!")
}

func main() {}
