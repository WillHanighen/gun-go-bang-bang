# AGENTS.md

This repository should not feel like a project that takes itself too seriously.

## Naming

`Gun Go Bang Bang` is a codename, not the final project name.

Do not treat it as locked branding, the shipped title, or a deliberate serious identity unless the user explicitly says that has changed.

## Creative direction

Aim for a **goofy-tech** identity:

- **Goofy like TABG**: playful, toyetic, a little absurd, willing to be silly on purpose
- **Techy like STRAFTAT**: sharp movement, clean readability, crisp weapon feel, strong mechanical clarity
- Lean into **pill-shaped player models** as part of the visual identity instead of treating them like a placeholder to be replaced with serious humanoids
    - The pills should have distinct features, such as visors, hats, and other accessories

The result should feel like a sandbox full of clever guns and chaotic ideas, not a grim milsim.

## When making changes

Prefer:

- punchy, readable feedback over strict realism
- distinct weapon personality over military authenticity
- playful UI text and presentation over sterile or tacticool tone
- pill silhouettes and toy-like character readability over realistic soldier proportions
- fast iteration and experimentation over lore or worldbuilding seriousness
- mechanics that are easy to understand but still have room for mastery

Avoid:

- self-important military framing
- overly serious naming, copy, or presentation
- realism that makes the game less fun
- systems that become tedious just to feel authentic

## Project memory

Use `learnings/*.md` as project-specific memory for things the agent should remember next time.

These files should be used to document:

- specific details about how systems are supposed to work
- behavior expectations the user has clarified
- places where the agent got something wrong and the corrected understanding
- recurring implementation or tone decisions that future work should follow

When the user points out a mistake, clarifies intended behavior, or gives a durable project rule, the agent should prefer adding or updating a focused file in `learnings/` so the codebase becomes easier to work in over time.

When making changes, check the learnings folder for potentially relevant information.

## Rule of thumb

If a change can be either:

1. serious, grounded, and "realistic"
2. funny, stylish, and mechanically interesting

the project should usually lean toward option 2.
