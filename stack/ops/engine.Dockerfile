# syntax=docker/dockerfile:1

FROM golang:1.27.0-alpine AS builder

WORKDIR /orglang

# Keep dependency metadata separate from source so source-only changes reuse this layer.
COPY go.work go.work.sum ./
COPY engine/go.mod engine/go.sum ./engine/
COPY sdk/go.mod sdk/go.sum ./sdk/

RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY . .

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o go-engine engine/app/main.go

FROM alpine:3.22

WORKDIR /orglang

COPY engine/app/reference.yaml .

COPY --from=builder /orglang/go-engine .

ENTRYPOINT ["/orglang/go-engine"]
