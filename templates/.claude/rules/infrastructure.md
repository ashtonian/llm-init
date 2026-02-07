---
paths:
  - "**/Dockerfile*"
  - "**/*.yml"
  - "**/*.yaml"
  - "**/terraform/**"
  - "**/k8s/**"
  - "**/helm/**"
  - "**/.github/**"
---

# Infrastructure Standards

Mandatory patterns for Docker, Kubernetes, Terraform, CI/CD pipelines, and cloud infrastructure. Everything is code. Nothing is manual.

## Docker

### Multi-Stage Build Template

```dockerfile
# Stage 1: Build
FROM golang:1.25-alpine AS builder
RUN apk add --no-cache git ca-certificates
WORKDIR /app

# Dependencies first (layer caching)
COPY go.mod go.sum* ./
RUN if [ -f go.sum ]; then go mod download; fi

# Source code
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-s -w -X main.version=${VERSION}" \
    -o /app/server ./cmd/server

# Stage 2: Runtime (minimal)
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /app/server /server
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
USER nonroot:nonroot
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD ["/server", "healthcheck"]
ENTRYPOINT ["/server"]
```

### Node.js Multi-Stage Build

```dockerfile
# Stage 1: Dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --production=false

# Stage 2: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Stage 3: Runtime
FROM node:20-alpine AS runner
WORKDIR /app
RUN addgroup --system --gid 1001 appgroup && \
    adduser --system --uid 1001 appuser
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
USER appuser
EXPOSE 3000
ENV NODE_ENV=production
CMD ["node", "server.js"]
```

### Docker Rules

| Rule | Rationale |
|------|-----------|
| Multi-stage builds | Separate build deps from runtime, smaller images |
| Non-root USER | Security: limit container privileges |
| Pin base image tags | Reproducibility: `node:20.11.0-alpine`, not `node:latest` |
| COPY deps before source | Layer caching: deps change less often than source |
| `.dockerignore` required | Exclude .git, node_modules, .env, test files, docs |
| No secrets in images | Use runtime env vars or secret mounts |
| HEALTHCHECK instruction | Enable orchestrator health monitoring |
| Minimal runtime image | Use distroless, alpine, or slim. Never full Debian/Ubuntu |

### .dockerignore

```
.git
.github
.env*
node_modules
*.md
docs
tests
**/*.test.*
**/*.spec.*
.dockerignore
Dockerfile
docker-compose*.yml
```

## Kubernetes

### Deployment Template

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  labels:
    app.kubernetes.io/name: app
    app.kubernetes.io/version: "1.0.0"
spec:
  replicas: 3
  selector:
    matchLabels:
      app.kubernetes.io/name: app
  template:
    metadata:
      labels:
        app.kubernetes.io/name: app
    spec:
      serviceAccountName: app
      securityContext:
        runAsNonRoot: true
        runAsUser: 65534
        fsGroup: 65534
      containers:
        - name: app
          image: registry/app:1.0.0
          ports:
            - containerPort: 8080
              protocol: TCP
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: database-url
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
          readinessProbe:
            httpGet:
              path: /readyz
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 10
            failureThreshold: 3
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 15
            periodSeconds: 20
            failureThreshold: 5
          securityContext:
            readOnlyRootFilesystem: true
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: app
```

### Kubernetes Rules

| Rule | Description |
|------|------------|
| Resource requests AND limits | Both required. Requests for scheduling, limits for protection |
| Health probes | Readiness (can accept traffic?) + Liveness (is it stuck?) |
| Security context | `runAsNonRoot`, `readOnlyRootFilesystem`, drop ALL capabilities |
| Pod topology spread | Spread pods across nodes for availability |
| Service account | Dedicated SA per service, least privilege RBAC |
| Pod Disruption Budget | `minAvailable: 1` minimum for HA services |
| Network policies | Default deny ingress/egress, explicit allow rules |
| Resource quotas | Per-namespace limits to prevent resource exhaustion |

### Pod Disruption Budget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: app
```

### Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 min before scaling down
```

## Terraform / Infrastructure as Code

### Module Structure

```
terraform/
  modules/
    vpc/
      main.tf
      variables.tf
      outputs.tf
    database/
      main.tf
      variables.tf
      outputs.tf
    cache/
    compute/
    monitoring/
  environments/
    dev/
      main.tf           # References modules
      variables.tf
      terraform.tfvars
      backend.tf         # Remote state config
    staging/
    production/
```

### Terraform Rules

| Rule | Description |
|------|------------|
| Remote state | S3 + DynamoDB lock (AWS) or equivalent. Never local state |
| State per environment | Separate state files for dev, staging, production |
| Modules for reuse | One module per logical component |
| No hardcoded values | Everything parameterized via variables |
| Plan before apply | Always `terraform plan`, require approval for production |
| Resource tagging | `environment`, `service`, `team`, `cost-center` on every resource |
| Outputs | Export IDs, endpoints, ARNs for downstream modules |
| Sensitive values | Mark with `sensitive = true`, never log |

### Backend Configuration

```hcl
terraform {
  backend "s3" {
    bucket         = "myorg-terraform-state"
    key            = "services/app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

## CI/CD Pipeline

### Pipeline Stages

```yaml
# GitHub Actions example
name: CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Lint
        run: make lint

  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - name: Test
        run: make test

  security:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - name: Dependency scan
        run: make security-scan
      - name: Container scan
        run: make container-scan

  build:
    runs-on: ubuntu-latest
    needs: [test, security]
    steps:
      - uses: actions/checkout@v4
      - name: Build and push image
        run: make docker-push

  deploy-dev:
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    environment: development
    steps:
      - name: Deploy to dev
        run: make deploy ENV=dev

  deploy-staging:
    runs-on: ubuntu-latest
    needs: deploy-dev
    if: github.ref == 'refs/heads/main'
    environment: staging  # Requires approval
    steps:
      - name: Deploy to staging
        run: make deploy ENV=staging

  deploy-production:
    runs-on: ubuntu-latest
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'
    environment: production  # Requires approval
    steps:
      - name: Deploy to production
        run: make deploy ENV=production
```

### CI/CD Rules

| Rule | Description |
|------|------------|
| Fail fast | Lint first (cheapest), then test, then build (most expensive) |
| Cache dependencies | Cache go modules, node_modules, Docker layers |
| Build once, deploy everywhere | Same artifact for all environments |
| Separate infra pipeline | Infrastructure changes in their own pipeline |
| Environment approval | Staging requires approval, production requires approval |
| Automated rollback | Health check failure triggers automatic rollback |
| Artifact signing | Sign Docker images for production deployment verification |

### Environment Promotion

```
main branch -> auto-deploy to dev -> manual promote to staging -> approval for production
```

- **Dev**: Auto-deploy on merge to main. Developers can test freely.
- **Staging**: Manual promotion. Full integration testing, performance testing.
- **Production**: Requires approval from 1+ designated reviewers. Canary deploy with monitoring.

## Secret Management

| Practice | Standard |
|----------|----------|
| Storage | Cloud secret manager (AWS SSM, GCP Secret Manager, Vault) |
| Access | Service-specific IAM roles, least privilege |
| Rotation | Automated rotation quarterly minimum, password on every compromise |
| Code | NEVER commit secrets. Git hooks to prevent accidental commits |
| CI/CD | Use GitHub/GitLab secrets or external secret manager |
| Audit | Log all secret access and rotation events |
| Detection | Use tools like `trufflehog` or `gitleaks` in CI |

## Database Operations

| Operation | Standard |
|-----------|----------|
| Backups | Automated daily full + continuous WAL archiving |
| Point-in-time recovery | Test monthly, document procedure |
| Migrations | Automated in CI/CD, before code deploy |
| Read replicas | For analytics queries and read-heavy workloads |
| Connection pooling | PgBouncer, max connections = 2 * cores |
| Monitoring | Connection count, query latency, replication lag, disk usage |

## CDN and Static Assets

| Rule | Description |
|------|------------|
| Static assets | Served via CDN (CloudFront, Cloudflare) |
| Cache headers | `Cache-Control: public, max-age=31536000, immutable` for hashed assets |
| Cache purge | Automated on deploy for non-hashed assets |
| Compression | Brotli preferred, gzip fallback |
| Image optimization | WebP/AVIF with fallbacks, responsive srcsets |

## Monitoring

| Check | Frequency | Alert On |
|-------|-----------|----------|
| Uptime (external) | 1 minute | Downtime > 2 minutes |
| SSL certificate | Daily | Expiry < 30 days |
| Dependency health | 5 minutes | Any critical dependency down |
| Resource usage | 1 minute | CPU > 80%, memory > 85%, disk > 90% |
| Cost | Daily | Exceeds 110% of projected daily cost |
| Replication lag | 1 minute | Lag > 30 seconds |

## Anti-Patterns

| Anti-Pattern | Correct Pattern |
|--------------|----------------|
| Manual infrastructure changes | Infrastructure as Code (Terraform/Pulumi) |
| `latest` Docker image tags | Specific version tags (`1.0.0`, `sha-abc123`) |
| Root user in containers | Non-root user, read-only filesystem |
| Secrets in environment files | Cloud secret manager |
| No health checks | Liveness + readiness probes |
| Same binary rebuilt per environment | Build once, deploy everywhere |
| No rollback plan | Documented + tested rollback for every deploy |
| Shared credentials between services | Service-specific credentials |
| No resource limits in k8s | Always set requests and limits |
| Manual database operations | Automated migrations, backups, monitoring |
