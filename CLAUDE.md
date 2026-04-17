# Global CLAUDE.md

## Tech Stack

- Primary languages: Go (backend/agents), TypeScript (frontend/userscripts), Svelte (UI components). Use TypeScript strict mode. Follow TDD practices — write/update tests alongside code changes.
- Go: Do not run `go build` or `go run` unless explicitly asked. Use `go vet ./...` to check compilation and `go test ./...` to run tests.

## Design Principles

- YAGNI — don't carry dead weight. If something is unused or the system already handles it, remove it or don't build it.
- KISS — prefer the simplest correct solution. If you can delete code and behavior stays the same, delete it. If the server already does something, don't also do it client-side.

## Git

- Never use `git -C`. Always run git commands from the working directory, not other worktrees.
- Commit plan documents (`docs/plans/`) alongside implementation changes — don't leave them uncommitted.

