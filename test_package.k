import .package as pkg

assert len(pkg.resources) == 2, "render a Deployment and Service"
assert pkg.resources[0].kind == "Deployment", "run the native Swytch server"
assert pkg.resources[0].spec.replicas == 1, "standalone cache has one replica"
assert pkg.resources[0].spec.selector.matchLabels == pkg.resources[0].spec.template.metadata.labels, "deployment selects its pods"
assert pkg.resources[1].spec.selector == pkg.resources[0].spec.template.metadata.labels, "service routes to this release"
assert pkg.resources[1].spec.type == "ClusterIP", "cache stays inside the cluster"
assert pkg.resources[0].spec.template.spec.containers[0].args[-1] == "128mb", "default cache budget is bounded"
