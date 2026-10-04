# Domain Documentation

Use the repository's glossary and ADRs to recover domain language and architectural decisions before exploring or changing code.

## Read first

- `GLOSSARY.md`, or `GLOSSARY-MAP.md` when present. In a multi-context repository, read the glossary relevant to the topic.
- Relevant files under `docs/adr/`.
- In a multi-context repository, also check `src/<context>/docs/adr/` for context-scoped decisions.

If these files do not exist, proceed without treating their absence as a problem. The domain-modeling skills create them when a real terminology or decision gap is found.

## Vocabulary

Use glossary terms for domain concepts in issue titles, proposals, hypotheses, test names, and other agent output. Do not invent synonyms for concepts the glossary already names.

If a needed concept is missing, first check whether the project genuinely lacks the concept before introducing new terminology.

## ADR conflicts

If proposed work contradicts an existing ADR, surface the conflict explicitly rather than silently overriding it. Name the ADR and explain why it may need to be revisited.
