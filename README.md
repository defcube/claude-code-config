# claude-code-config

My shared [Claude Code](https://claude.com/claude-code) configuration — statusline, global instructions, keybindings, and custom skills. Cherry-pick whatever's useful.

## What's here

| Path | What it is |
|---|---|
| `CLAUDE.md` | Global instructions injected into every session |
| `keybindings.json` | Custom keybindings (drop into `~/.claude/`) |
| `settings.example.json` | Template for `~/.claude/settings.json` — fill in your paths |
| `statusline/` | Custom statusline showing dir, git, model, context %, cost |
| `skills/` | Custom slash-command skills |

## Install everything

```bash
git clone https://github.com/YOUR_USERNAME/claude-code-config.git ~/claude-code-config
cd ~/claude-code-config

# Global CLAUDE.md and keybindings
cp CLAUDE.md ~/.claude/CLAUDE.md
cp keybindings.json ~/.claude/keybindings.json

# Statusline
cp statusline/statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh

# Skills
mkdir -p ~/.claude/skills
cp -R skills/* ~/.claude/skills/

# Settings — start from the example, then edit paths
cp settings.example.json ~/.claude/settings.json
# edit ~/.claude/settings.json and replace YOUR_USERNAME
```

Restart Claude Code after changes.

## Cherry-picking

Each piece is independent — take just the statusline, or just a skill, etc. See the per-directory READMEs where present.

## Skills included

- **`bubbletea-tui`** — guidance for building Go terminal UIs with Bubble Tea + lipgloss
- **`detach-dir`** — detaches HEAD at `origin/main` so you can't accidentally commit to main
- **`edit-file`** — opens a file in your macOS default editor via `open`
- **`revise-skills`** — reviews the current conversation for friction and proposes improvements to local skills / CLAUDE.md

## License

MIT — do whatever you want with this.
