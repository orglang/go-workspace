# Boundary Enforcement by Import-Graph Analysis

The core-must-not-import-adapter rule is checked statically, not left to review. We prototyped the check with `golang.org/x/tools/go/packages` in ~50 lines and confirmed it both passes on the current tree and reports a violation when one is planted. This matters: an unenforced boundary is a comment.

The check runs as a lint task and fails on violation. It classifies packages by path (`/core`, `/domain` → agnostic; `/adapter`, `/adapters/`, `*_pgx`, `*_echo` → specific) and asserts no agnostic package imports a specific one. Classification by path suffix is crude but sufficient while the layout is uniform; when it stops being uniform, the classifier is the thing to revisit.

We chose import-graph analysis over forbidigo, which forbids identifier patterns and cannot express "package A must not import package B". `forbidigo` was evaluated and rejected for this purpose.
