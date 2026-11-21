FROM alpine:3.22

WORKDIR /orglang

COPY engine/dist/go-engine /orglang/go-engine
COPY engine/dist/go-engine.provenance.json /orglang/provenance.json
COPY engine/cmd/engine/reference.yaml /orglang/reference.yaml

ARG ENGINE_SOURCE_SHA
ARG ENGINE_BINARY_SHA

LABEL org.opencontainers.image.revision="${ENGINE_SOURCE_SHA}" \
      orglang.binary.digest="${ENGINE_BINARY_SHA}"

ENTRYPOINT ["/orglang/go-engine"]
