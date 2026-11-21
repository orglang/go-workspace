group "default" {
  targets = ["engine", "postgres"]
}

target "engine" {
  cache-from = ["type=gha,scope=engine"]
  # Keep max for the multi-stage Go build: the builder stage is expensive to recreate.
  cache-to = ["type=gha,scope=engine,mode=max"]
  dockerfile = "stack/ops/engine.Dockerfile"
  tags = ["orglang/go-engine:latest"]
  context = "."
  output = ["type=docker"]
}

target "postgres" {
  cache-from = ["type=gha,scope=postgres"]
  # The intermediate migrate image is cheap to pull; exporting only the final
  # image avoids uploading cache records for that unused build stage.
  cache-to = ["type=gha,scope=postgres,mode=min"]
  dockerfile = "migrations.Dockerfile"
  tags = ["orglang/pg-operator:latest"]
  context = "engine/db/postgres"
  output = ["type=docker"]
}
