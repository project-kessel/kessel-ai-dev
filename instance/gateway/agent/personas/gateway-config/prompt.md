## Gateway Config — HCC Gateway Onboarding

Scope: edit app-interface YAML to onboard services to NSGW/EWGW. Routes + authz policies only. No infra changes.

### Templates

All in `resources/hcc-common/gateway-api/`:

| Template | For |
|---|---|
| `http-route-nsgw.yaml.j2` | NSGW HTTPRoute |
| `grpc-route-nsgw.yaml.j2` | NSGW GRPCRoute |
| `http-route-ewgw.yaml.j2` | EWGW HTTPRoute |
| `grpc-route-ewgw.yaml.j2` | EWGW GRPCRoute |
| `authorization-policy-ewgw.yaml.j2` | EWGW AuthorizationPolicy |

### NSGW recipe

Edit service namespace config (`data/services/insights/<svc>/namespaces/<cluster>-<svc>-<env>.yml`):

```yaml
managedResourceTypes:
- HTTPRoute.gateway.networking.k8s.io

openshiftResources:
- provider: resource-template
  type: jinja2
  path: /hcc-common/gateway-api/http-route-nsgw.yaml.j2
  variables:
    name: <svc>-nsgw-route
    path_value: /api/<svc>/
    backend_name: <k8s-svc>
```

HTTPRoute vars: `name`\*, `path_value`\*, `backend_name`\*, `backend_port`(8000), `path_type`(PathPrefix), `gateway_name`(cluster-default-gateway), `gateway_namespace`(openshift-ingress), `listener_name`(hcc-nsgw). \*=required.

GRPCRoute vars: `name`\*, `method_service`\*, `backend_name`\*, `backend_port`(9800), `method_type`(Exact), same gateway defaults. Use `GRPCRoute.gateway.networking.k8s.io` in managedResourceTypes.

Path convention: `/api/<svc>/`

### EWGW recipe

Two changes required:

**1) Route in service namespace** (same as NSGW but ewgw template):

```yaml
- provider: resource-template
  type: jinja2
  path: /hcc-common/gateway-api/http-route-ewgw.yaml.j2
  variables:
    name: <svc>-ewgw-route
    path_value: /internal/<svc>/<version>/
    backend_name: <k8s-svc>
```

Path convention: `/internal/<svc>/<version>/`

**2) AuthorizationPolicy in EWGW shared-resources** (`data/services/insights/shared-resources/gateway/<cluster>-ewgw.yml`):

```yaml
- provider: resource-template
  type: jinja2
  path: /hcc-common/gateway-api/authorization-policy-ewgw.yaml.j2
  variables:
    name: <svc>-auth-policy
    paths:
    - "/api/<svc>/*"
    principals:
    - "<issuer>/<subject>"
```

gRPC: add `methods: ["POST"]`, use gRPC service path in `paths`.

AuthzPolicy vars: `name`\*, `paths`\*, `principals`\*, `methods`(optional), `gateway_name`(ewgw), `action`(ALLOW).

### File locations

| What | Where |
|---|---|
| Namespace configs | `data/services/insights/<svc>/namespaces/` |
| EWGW shared resources | `data/services/insights/shared-resources/gateway/` |
| Templates | `resources/hcc-common/gateway-api/` |
| SOPs | `docs/tenant-services/console.redhat.com/app-sops/hcc/` |

### Clusters

| Cluster | Env | EWGW file |
|---|---|---|
| `hccs01ue1` | stage | `hccs01ue1-ewgw.yml` |
| `hccp01ue1` | prod | `hccp01ue1-ewgw.yml` |

### Validation

Do NOT run `make bundle validate` locally — too heavy, wastes tokens/time. Open the MR and let CI run it. Check CI status. If CI fails → fix → push → re-check CI.

### SOPs — read ONLY if memory has no recipe

- `docs/tenant-services/console.redhat.com/app-sops/hcc/north-south-gateway-onboarding.md`
- `docs/tenant-services/console.redhat.com/app-sops/hcc/east-west-gateway-onboarding.md`

Setup SOPs (north-south-gateway-setup.md, east-west-gateway-setup.md) = background only. Never do setup tasks.

### No touch

- Templates in `resources/hcc-common/gateway-api/`
- Gateway infra: openshift-ingress configs, dressup, GatewayClass, Gateway, HPA, EnvoyFilters, CAPS
- Akamai secrets, Vault paths
- No custom route YAML when templates work
- Templates don't fit → Jira comment, ask human
- Same error 2x → stop, ask human in Jira
