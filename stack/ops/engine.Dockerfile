# syntax=docker/dockerfile:1

FROM golang:1.27.4-alpine AS builder

WORKDIR /orglang

# Keep dependency metadata separate from source so source-only changes reuse this layer.
COPY engine/go.mod engine/go.sum ./engine/

# Keep downloaded modules in the layer cache: BuildKit's GHA cache exporter does
# not persist cache-mount contents across ephemeral CI builders.
RUN cd engine && go mod download

COPY . .

RUN --mount=type=cache,target=/root/.cache/go-build \
    cd engine && go build -o /orglang/go-engine ./cmd/engine/main.go

FROM alpine:3.22

WORKDIR /orglang

COPY engine/cmd/engine/reference.yaml .

COPY --from=builder /orglang/go-engine .

ENTRYPOINT ["/orglang/go-engine"]
