# syntax=docker/dockerfile:1

# --- Build stage ---
ARG GO_VERSION=1.27.2
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS builder

ARG TARGETOS
ARG TARGETARCH

WORKDIR /src

# Cache dependencies
COPY go.mod go.sum* ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download

# Build
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /app ./cmd/{{PROJECT_NAME}}

# --- Runtime stage ---
FROM alpine:3.20

RUN apk add --no-cache ca-certificates tzdata

COPY --from=builder /app /usr/local/bin/app

EXPOSE 8080

# Uncomment when the app has a health endpoint:
# HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
#   CMD wget -qO- http://localhost:8080/healthz || exit 1

ENTRYPOINT ["app"]
