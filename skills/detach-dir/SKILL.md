---
name: detach-dir
description: Detach HEAD at latest origin/main
disable-model-invocation: true
allowed-tools: Bash(git *)
---

Create a detached HEAD at the latest origin/main. **Proceed without asking.**

This ensures you cannot accidentally commit to main — you must explicitly create a branch before any work can be pushed.

## Workflow

**Execute these commands in sequence without pre-checking status:**

1. Fetch the latest main from origin: `git fetch -q origin main`
2. Detach HEAD at origin/main: `git checkout -q --detach origin/main`
3. (Optional) Verify with `git status` for user confirmation

**Important:** Do NOT check `git status` before step 2. The checkout command will fail safely if there are uncommitted changes that would be overwritten. Handle errors reactively, not proactively.

## Expected Outcome

After running this skill:
- HEAD is detached at `origin/main`
- Directory state matches `origin/main` exactly
- Working tree is clean (no uncommitted changes)
- You must create a branch (`git checkout -b <branch-name>`) before making any commits

## Error Handling

The `git checkout --detach` command will fail automatically if there are uncommitted changes that would be overwritten. When this error occurs:
- Report the error message to the user (git provides clear output)
- Suggest options: stash (`git stash`), commit, or discard changes
- Do NOT proceed until the user decides

This reactive approach is faster than checking status before attempting checkout.

## Performance Notes

This skill is optimized for speed:
- Uses `-q` flags to minimize output
- Skips pre-flight status checks (reactive error handling)
- Optional final verification step
- With `disable-model-invocation: true`, execution is deterministic

Expected execution: 2-3 git commands (fetch, checkout, optional status) instead of 4.
