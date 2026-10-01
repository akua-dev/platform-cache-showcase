# Swytch on Akua

A small Akua Package for trying the open-source [Swytch](https://github.com/swytchdb/swytch) Redis-compatible cache on Kubernetes. This showcase is maintained by Akua; it is not an official Swytch distribution.

The Package runs one Swytch 1.5.0 server and a ClusterIP Service. The image is pinned to its multi-architecture digest. The customer chooses a cache memory budget from 64 to 1024 MiB; Akua supplies the namespace and release name. Pod memory includes additional server overhead.

This is an ephemeral demo: restarting the server loses cached data. It has no Redis authentication and should run in an isolated demo namespace on a trusted cluster. Access it through a local port-forward. Multi-node clustering, persistent storage, and commercial Swytch features are outside this example. Anonymous upstream telemetry is disabled.

## Try on OrbStack

Enable Kubernetes in OrbStack and install the [Akua CLI](https://akua.dev/docs/cli). Clone this repository, then run:

```console
akua pkg check
akua pkg lint
akua pkg test
akua pkg render --package package.k --inputs inputs.example.yaml --out deploy --strict
kubectl --kubeconfig "$HOME/.orbstack/k8s/config.yml" create namespace platform-cache-showcase
kubectl --kubeconfig "$HOME/.orbstack/k8s/config.yml" apply -f deploy
kubectl --kubeconfig "$HOME/.orbstack/k8s/config.yml" rollout status deployment/platform-cache -n platform-cache-showcase --timeout=60s
kubectl --kubeconfig "$HOME/.orbstack/k8s/config.yml" port-forward -n platform-cache-showcase service/platform-cache 16379:6379
```

In another terminal, use a Redis client:

```console
redis-cli -p 16379 PING
redis-cli -p 16379 SET showcase:welcome "Hello from Swytch on Akua"
redis-cli -p 16379 GET showcase:welcome
redis-cli -p 16379 EXPIRE showcase:welcome 60
```

Expected responses: `PONG`, `OK`, `Hello from Swytch on Akua`, and `1`.

If you do not have `redis-cli`, run the pinned client inside the cluster:

```console
kubectl --kubeconfig "$HOME/.orbstack/k8s/config.yml" run platform-cache-client -n platform-cache-showcase --image=redis@sha256:987c376c727652f99625c7d205a1cba3cb2c53b92b0b62aade2bd48ee1593232 --restart=Never --command -- sh -ec 'redis-cli -h platform-cache PING; redis-cli -h platform-cache SET showcase:welcome "Hello from Swytch on Akua"; test "$(redis-cli -h platform-cache GET showcase:welcome)" = "Hello from Swytch on Akua"; redis-cli -h platform-cache GET showcase:welcome; redis-cli -h platform-cache EXPIRE showcase:welcome 60'
kubectl --kubeconfig "$HOME/.orbstack/k8s/config.yml" wait --for=jsonpath='{.status.phase}'=Succeeded pod/platform-cache-client -n platform-cache-showcase --timeout=60s
kubectl --kubeconfig "$HOME/.orbstack/k8s/config.yml" logs platform-cache-client -n platform-cache-showcase
kubectl --kubeconfig "$HOME/.orbstack/k8s/config.yml" delete pod platform-cache-client -n platform-cache-showcase
```

## Akua customer demo

The planned hosted demo uses the same authored Package, an unlisted Product, and a trial Offer. The intended customer flow is to open the Offer, sign in, select a Workspace and compatible Cluster, choose memory, and submit the Install. They then inspect its operation and resources and run the Redis commands above against their installed Service. This hosted flow has not yet been verified end to end.

Local OrbStack verification proves the Package runs; it does not prove a hosted Akua Install or remote cluster connectivity. A laptop cluster is reachable locally only until it is connected through a supported Akua cluster registration path.

## Verification

On 1 October 2026, the Package passed check, lint, assertion tests, strict rendering, and Kubernetes server-side dry-run. The Deployment became Ready on OrbStack Kubernetes 1.35.6, and an in-cluster Redis client verified PING, SET, GET, and EXPIRE.

Swytch image: `ghcr.io/swytchdb/swytch@sha256:7a9f8eeb4c315f5b97de777a135a4a8d95d831b96faac2da5b9f86a27b856fca`.

Upstream source: [Swytch v1.5.0](https://github.com/swytchdb/swytch/tree/v1.5.0), commit `79be1b07ebc0ba043a1def418a5e9cf70443bbef`. Swytch is licensed under AGPL-3.0; this repository references its upstream image and does not include its source or binary. The Package files in this repository are licensed under MIT.

## Cleanup

```console
kubectl --kubeconfig "$HOME/.orbstack/k8s/config.yml" delete namespace platform-cache-showcase
```
