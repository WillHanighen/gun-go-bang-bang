# AGENTS.md

This repository should not feel like a project that takes itself too seriously.

## Naming

`Gun Go Bang Bang` is a codename, not the final project name.

Do not treat it as locked branding, the shipped title, or a deliberate serious identity unless the user explicitly says that has changed.

## Creative direction

Aim for **playful survival** — zombies, scarcity, threat, and scavenging are fine, but the vibe stays **goofy and toyetic**, not grim tactical or nitty-gritty simulation.

- **Goofy like TABG**: playful, absurd on purpose, willing to be stupid-fun; pill people with visors, hats, and accessories stay the look (not “realistic survivors”)
- **Survival framing**: readable stakes (gear, danger, pressure) without misery realism, inventory soup, or self-important military fantasy
- **Feel**: grounded movement and **mechanical clarity** (weapon feedback, UI, combat read) — crisp where it helps playability, not “arcade skill-movement” for its own sake

The result should feel like a **survival-ish** toy box, not a gray milsim or a hardcore life sim.

## When making changes

Prefer:

- punchy, readable feedback over strict realism
- distinct weapon personality over military authenticity
- playful UI text and presentation over sterile or tacticool tone
- pill silhouettes and toy-like character readability over realistic soldier proportions
- fast iteration and experimentation over lore or worldbuilding seriousness
- mechanics that are easy to understand but still have room for mastery
- survival ideas (loot, threats, light resource pressure) when they stay **light and readable**, not sim-for-sim’s-sake

Avoid:

- self-important military framing
- overly serious naming, copy, or presentation
- realism that makes the game less fun
- systems that become tedious just to feel authentic
- grim, gritty, or “authentic suffering” tone — keep it cheeky

Also update docs about changes, preventing them from becoming outdated or inaccurate.

## Project memory

Use `learnings/*.md` as project-specific memory for things the agent should remember next time.

Use `learnings/local/*.md` for machine-specific or user-specific local notes that should stay on this computer and should not be committed.

These files should be used to document:

- specific details about how systems are supposed to work
- behavior expectations the user has clarified
- places where the agent got something wrong and the corrected understanding
- recurring implementation or tone decisions that future work should follow

When the user points out a mistake, clarifies intended behavior, or gives a durable project rule, the agent should prefer adding or updating a focused file in `learnings/` so the codebase becomes easier to work in over time.

Local environment details like tool install paths, machine quirks, or personal workflow notes belong in `learnings/local/` instead of the shared `learnings/` docs.

When making changes, check the learnings folder for potentially relevant information, including `learnings/local/` when local setup details might matter.

## Rule of thumb

If a change can be either:

1. serious, grounded, and "realistic"
2. funny, stylish, and mechanically interesting

the project should usually lean toward option 2.
