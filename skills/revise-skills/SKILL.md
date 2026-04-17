---
name: revise-skills
description: Review the current conversation for friction, suggest improvements to local skills and CLAUDE.md, then apply approved changes. Use when a session felt clunky or after completing a workflow to capture improvements.
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Skill
---

# Revise Skills

Review the current conversation for friction. Present findings one at a time with skeptical analysis. Apply small fixes inline; escalate behavioral changes to `/brainstorming`.

## Step 1: Discover Local Files

1. Glob for `.claude/skills/*/SKILL.md` in the project root to find all local skills
2. Glob for `CLAUDE.md` in the project root

Do not read files now — read a file only when you are about to edit it in Step 3c.

## Step 2: Analyze Conversation

Review the full conversation history for friction. Look for:

- Input formats the skill didn't handle correctly
- Wrong assumptions or defaults that needed overriding
- Missing context that caused incorrect behavior
- Unnecessary confirmation steps or extra round-trips
- Ambiguity in skill instructions that led to wrong interpretation
- Preferences or rules that should be documented but aren't
- Edge cases that weren't covered

Internally rank findings by severity (most impactful first). Auto-skip findings where your recommended option is "skip" — don't present these to the user. Only present findings that warrant an actual change. Include auto-skipped items in the final summary so the user knows what was considered.

## Step 3: Iterate Through Findings

Present findings **one at a time**. For each finding, follow this loop:

### 3a: Present with Skepticism

Before proposing a fix, apply two lenses:

**Lens 1 — "Is the fix worth the complexity?"**
- What does the fix add to the skill file (lines, conditions, new steps)?
- Does it handle a one-off situation or a recurring pattern?
- Will it make the skill harder to follow?

**Lens 2 — "Is there a simpler root cause?"**
- Could the friction be solved by fixing something upstream instead?
- Would a change to CLAUDE.md cover it without touching the skill at all?
- Is the friction actually a symptom of a different, deeper problem?

Present the finding as a short text block explaining the friction and your skeptical take, then use **AskUserQuestion** with 2-3 options. Put your recommended option first with "(Recommended)" appended. Each option label should be the solution name, and the description should include the rationale and trade-offs. It is OK to include "Skip this" as one of the options if you genuinely think the fix isn't worth it.

### 3b: Dialogue

Have a back-and-forth conversation with the user. Explore alternatives. Push back if you think a suggestion adds more complexity than value. The user can override your skepticism.

### 3c: Resolve

Once the user and you agree on an outcome, classify the fix:

**Small fix** — apply directly:
- Wording clarifications in skill text
- Adding a missing edge case to an existing step
- Updating CLAUDE.md with a new preference or rule
- Fixing a default value

Read the target file first if you haven't already, then apply the edit immediately and confirm in one line:
"Applied: [what changed] in `[file]`. Next finding..."

**Behavioral change** — escalate automatically:
- Adding or removing a step in a skill's flow
- Changing how a skill makes decisions (new filtering logic, new data sources)
- Adding a new concept the skill needs to track
- Anything that would change the skill's output for the same inputs

Do not ask — just announce and escalate:
"This changes how the skill behaves, not just what it says. Escalating to /brainstorming to design it properly."

Invoke `/brainstorming` with the finding as context. When brainstorming completes, return to the next finding.

**Skip** — move on:
"Skipping this one. Next finding..."

### 3d: Next

Move to the next finding. If the user says "that's enough" at any point, stop iterating.

## Step 4: Close

When all findings are exhausted or the user stops early, present a summary:

"Done. Here's what happened:
- Applied: [list of small fixes with files]
- Escalated: [list of behavioral changes sent to /brainstorming]
- Skipped: [list of findings that weren't worth the complexity]"
