# Statusline

Custom statusline for Claude Code showing:

- Current directory (shortened to last 3 segments)
- Git branch, staged / modified / untracked counts, ahead/behind upstream
- Active model (e.g. `Opus 4.7`, `Sonnet 4.6`)
- Context window remaining (yellow <30%, red <15%)
- Session cost + accumulating response-delta cost

Example:

```
.../programs/myproject [main] [+2*5?1] [↑3] | Opus 4.7 | ctx: 42% | $1.23 (+$0.18)
```

## Install

1. **Copy the script** somewhere permanent:

   ```bash
   cp statusline-command.sh ~/.claude/statusline-command.sh
   chmod +x ~/.claude/statusline-command.sh
   ```

2. **Point Claude Code at it** — add this to `~/.claude/settings.json`:

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "/Users/YOUR_USERNAME/.claude/statusline-command.sh"
     }
   }
   ```

   Use the absolute path — `~` is not expanded in this field.

3. **Restart Claude Code** (or start a new session).

## Dependencies

Standard Unix tools, pre-installed on macOS and most Linux distros:

- `bash`
- `jq`
- `awk`
- `git`

## How the cost delta works

The `(+$X.XX)` shows cost accumulated during the current response. It resets when the statusline hasn't been called for >3 seconds (Claude Code refreshes it frequently while streaming, then pauses between turns).

State lives in `/tmp/claude-statusline/<session_id>.state` — auto-created, nothing to configure.

## Customizing

The script is ~120 lines of bash. Common tweaks:

- **Colors** — ANSI escapes like `\033[1;35m` (bold magenta). Reference: [ANSI SGR parameters](https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters).
- **Path depth** — edit the `awk` in `dir_display` (currently shows last 3 segments).
- **Sections** — each block appends to `$line`; comment one out to drop it.

## Troubleshooting

- **Statusline doesn't show** — run `claude --debug` and look for command errors. Most common causes: wrong path in `settings.json`, missing `chmod +x`.
- **Garbled characters** — your terminal may not render the `↑↓` arrows (non-UTF-8 locale) or ANSI colors. Replace with ASCII if needed.
- **`jq: command not found`** — `brew install jq` on macOS, `apt install jq` on Debian/Ubuntu.
