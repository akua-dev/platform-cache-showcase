import akua.ctx

schema Input:
    """Run an ephemeral, single-node Swytch cache speaking Redis RESP."""
    namespace: str = "default"
    """Target Kubernetes namespace, supplied by Akua."""

    release_name: str = "platform-cache"
    """Resource name prefix, supplied by Akua."""

    memory_mb: int = 128
    """Cache memory budget in MiB. Pod memory includes server overhead."""

    check:
        memory_mb >= 64, "memory_mb must be at least 64"
        memory_mb <= 1024, "memory_mb must be at most 1024"

input: Input = ctx.input()
_labels = {"app.kubernetes.io/name": "platform-cache", "app.kubernetes.io/instance": input.release_name}
resources = [
    {
        apiVersion: "apps/v1"
        kind: "Deployment"
        metadata: {name: input.release_name, namespace: input.namespace, labels: _labels}
        spec: {
            replicas: 1
            strategy.type: "Recreate"
            selector.matchLabels: _labels
            template: {
                metadata.labels: _labels
                spec: {
                    automountServiceAccountToken: False
                    securityContext: {runAsNonRoot: True, runAsUser: 65532, runAsGroup: 65532, seccompProfile.type: "RuntimeDefault"}
                    containers: [{
                        name: "cache"
                        image: "ghcr.io/swytchdb/swytch@sha256:7a9f8eeb4c315f5b97de777a135a4a8d95d831b96faac2da5b9f86a27b856fca"
                        args: ["redis", "--bind", "0.0.0.0", "--port", "6379", "--threads", "2", "--no-telemetry", "--maxmemory", "${input.memory_mb}mb"]
                        ports: [{name: "redis", containerPort: 6379}]
                        resources: {
                            requests: {cpu: "100m", memory: "${input.memory_mb + 64}Mi"}
                            limits: {cpu: "1", memory: "${input.memory_mb + 128}Mi"}
                        }
                        securityContext: {allowPrivilegeEscalation: False, readOnlyRootFilesystem: True, capabilities.drop: ["ALL"]}
                        readinessProbe: {tcpSocket.port: "redis", initialDelaySeconds: 2, periodSeconds: 5}
                        livenessProbe: {tcpSocket.port: "redis", initialDelaySeconds: 10, periodSeconds: 10}
                    }]
                }
            }
        }
    }
    {
        apiVersion: "v1"
        kind: "Service"
        metadata: {name: input.release_name, namespace: input.namespace, labels: _labels}
        spec: {type: "ClusterIP", selector: _labels, ports: [{name: "redis", port: 6379, targetPort: "redis"}]}
    }
]
