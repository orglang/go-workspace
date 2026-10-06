FROM golang:alpine AS builder

WORKDIR /orglang

COPY go.work ./
COPY . .

ENV GOWORK=/orglang/go.work

RUN go build -o go-engine ./engine/app

FROM alpine

WORKDIR /orglang

COPY engine/app/reference.yaml .

COPY --from=builder /orglang/go-engine .

ENTRYPOINT ["/orglang/go-engine"]
