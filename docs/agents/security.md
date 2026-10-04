# Security Guidance

- Treat tokens, passwords, API keys, private keys, certificates, cookies, and sensitive environment files as secrets.
- Never print, copy, commit, or paste secrets into issues, PRs, logs, patches, or generated artifacts.
- Do not use production credentials for local development or tests.
- Keep security-sensitive changes explicit and narrowly scoped.
- Do not disable authentication, authorization, TLS, validation, dependency scanning, or other security controls merely to get a check green.
- Avoid sending repository data or credentials to external services unless the task explicitly requires it and the destination is trusted.

Destructive operations require explicit authorization, including database deletion, `docker compose down -v`, `git reset --hard`, `git clean -fd`, force-pushes, cloud-resource deletion, and package publication.
