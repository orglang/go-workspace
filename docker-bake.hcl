group "default" {
  targets = ["engine", "postgres"]
}

target "engine" {
  dockerfile = "stack/ops/engine.Dockerfile"
  tags = ["orglang/go-engine:latest"]
  context = "."
}

target "postgres" {
  cache-from = ["type=gha"]
  cache-to = ["type=gha,mode=max"]
  dockerfile = "liquibase.Dockerfile"
  tags = ["orglang/pg-operator:latest"]
  context = "engine/db/postgres"
}
