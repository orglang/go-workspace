# Environment Guidance

Use the repository's documented toolchain and Taskfiles as the source of truth.

Before running expensive or destructive checks, verify the local prerequisites and the task definition. Typical prerequisites include the required Go toolchain, Task, Docker, and service dependencies such as PostgreSQL.

Do not assume production environment variables or credentials are available or appropriate. If a command needs secrets or external infrastructure, stop at the permission boundary and make the requirement explicit.

Prefer reproducible project commands over machine-specific global configuration.
