# Issue Tracker Guidance

GitHub issues are the repository's tracker for work items and specifications. Use the repository's normal GitHub tooling for issue operations.

## Issue lifecycle

Keep issue operations explicit and reproducible:

- create with a clear title and problem-oriented body;
- read the issue together with its comments and labels;
- list/filter issues by state and relevant labels;
- add comments for decisions or requested information;
- add or remove labels deliberately;
- close only when the issue's work or decision is resolved.

When a task refers to a ticket, resolve the repository and issue number before acting. GitHub uses one number space for issues and pull requests, so verify which kind of object a bare `#N` refers to.

## Pull requests as triage input

This repository does **not** currently treat pull requests as a separate feature-request surface for triage.

If that policy changes, apply the same issue states and triage labels to external PRs, while excluding repository owners, members, and collaborators from the external-contributor queue.

## Triage labels

Use the repository's actual label names:

| Role | Label | Meaning |
| --- | --- | --- |
| Needs evaluation | `needs-triage` | Maintainer should evaluate the issue |
| Needs information | `needs-info` | Waiting for reporter information |
| Agent-ready | `ready-for-agent` | Fully specified for agent work |
| Human-ready | `ready-for-human` | Requires human implementation |
| Won't fix | `wontfix` | Will not be actioned |

The label names above are the repository vocabulary; do not introduce a second alias layer in other guidance.

## Wayfinding

The `/wayfinder` workflow uses a map issue and child tickets.

- **Map**: one issue labelled `wayfinder:map`, containing notes, decisions-so-far, and current uncertainty.
- **Child**: a ticket linked to the map as a GitHub sub-issue when supported; otherwise reference `Part of #<map>` in the body.
- **Blocking**: prefer GitHub's native issue dependencies. If unavailable, use an explicit `Blocked by: #N` marker.
- **Frontier**: choose the first open child in map order that has no open blocker and no assignee.
- **Claim**: assign the ticket before doing the work.
- **Resolve**: record the answer in a comment, close the ticket, then add the durable context pointer to the map.

Detailed command syntax belongs to the skill that performs the operation, not to this repository-wide guidance.
