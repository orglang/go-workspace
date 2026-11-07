# Agent bootstrap

This file is always loaded. It defines instruction activation and repository layout; it does not activate other project instructions.

## Instruction activation

Project instructions are opt-in. Activate an instruction only when the user explicitly asks for it, including an unambiguous request to follow all project instructions in a stated scope, or when an already activated instruction links to it. Follow instruction links transitively and process each instruction once.

For a request to follow all project instructions, inspect the designated instruction locations within the requested scope: this file, `docs/agents/`, applicable nested-repository `AGENTS.md` files, and `SKILL.md` files under `skills/`. Activate the instructions found there for that request. Supporting templates, rubrics, examples, scenarios, and ordinary documentation are not instructions merely because they are present.

A generic request to follow repository conventions does not activate every project instruction unless the scope is clear. A plain mention of an instruction or an unlinked path does not activate it.

This bootstrap file is the exception: it is always loaded but does not activate other project instructions. Do not add links from this file to project instructions. A plain description of an instruction location does not activate its contents.

## Repository layout

The workspace repository is a meta repository containing `go.work`. Nested repositories are subdirectories containing their own `.git` directory and `go.mod`; other subdirectories belong to the nearest enclosing Git repository. Before editing files in a nested repository, identify that repository as the file owner and read its `AGENTS.md` bootstrap file. Reading a bootstrap file does not by itself activate other project instructions.
