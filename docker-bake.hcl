group "default" {
  targets = ["engine", "postgres"]
}

target "engine" {
  cache-from = ["type=gha,scope=engine"]
  cache-to = ["type=gha,scope=engine,mode=max"]
  dockerfile = "stack/ops/engine.Dockerfile"
  tags = ["orglang/go-engine:latest"]
  context = "."
  output = ["type=docker"]
}

target "postgres" {
  cache-from = ["type=gha,scope=postgres"]
  cache-to = ["type=gha,scope=postgres,mode=max"]
  dockerfile = "migrations.Dockerfile"
  tags = ["orglang/pg-operator:latest"]
  context = "engine/db/postgres"
  output = ["type=docker"]
}
