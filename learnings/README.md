# Learnings

This folder is for project-specific memory that should survive beyond a single chat.

Use focused files in `learnings/*.md` to record:

- stable behavior expectations for systems in this repo
- clarifications the user had to make after an initial implementation
- places where the agent misunderstood intent and the corrected version
- durable tone, naming, UX, or design direction

Prefer small, topic-specific files over one giant notes file.

## Good structure

Each learning doc should usually include:

- what the topic is
- what is easy to get wrong
- the corrected understanding
- what future changes should preserve

## When to update

Update or add a learning when:

- the user says the agent got something wrong
- the user has to restate or refine behavior after a first pass
- a system has non-obvious rules that are easy to break
- a creative or product decision should guide future work
