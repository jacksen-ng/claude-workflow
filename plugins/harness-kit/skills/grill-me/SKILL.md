---
name: grill-me
description: Interview the user relentlessly about a plan, design, or vague requirement until reaching shared understanding, resolving each branch of the decision tree. Used by harness-engineering Phase 1 (clarity gate) whenever a requirement.md cannot be filled without guessing; also use directly when the user wants to stress-test a plan, get grilled on a design, or says "grill me" / "帮我理清需求".
---

<!-- Vendored from https://github.com/mattpocock/skills (MIT), adapted for harness-kit. -->

# Grill Me — Requirement Interrogation

Interview the user relentlessly about every aspect of this plan until you reach a shared
understanding. Walk down each branch of the design tree, resolving dependencies between
decisions one-by-one. For each question, provide your recommended answer.

Ask the questions **ONE at a time**.

If a question can be answered by exploring the codebase, explore the codebase instead of asking.

## Bounded grilling (harness adaptation — do NOT interrogate endlessly)

- Ask the user only the questions that genuinely change what gets built. For low-stakes
  choices, take your own recommended answer and record it as a **delegated decision** —
  don't spend a question on it.
- The user can delegate at any point ("按你推荐的来" / "use your recommendation") — record
  every delegated choice explicitly (the choice + the recommendation taken), never silently.
- **Exit criterion (mechanical, not a feeling):** stop as soon as the requirement can be
  written down without guessing — when used by `harness-engineering`, that means every
  section of `requirement.md` (problem, in/out of scope, acceptance criteria) writes itself
  and its "Open questions" section is empty.
