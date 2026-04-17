---
name: edit-file
description: Open a file in the default system editor (macOS)
disable-model-invocation: true
---

# edit-file

Opens the specified file in the default macOS editor using the `open` command.

## Usage

```
/edit-file <file-path>
```

## Arguments

- `<file-path>`: Path to the file to open (can be relative or absolute)

## What it does

1. Runs `open <file-path>` to open the file in your default editor
2. The file opens in your configured default application for that file type
3. You can make changes and save them in your editor
4. Return to Claude when you're done

## Examples

Open a markdown file:
```
/edit-file CLAUDE.md
```

Open a TypeScript file:
```
/edit-file src/lib/stores/bandPool.ts
```

Open a config file:
```
/edit-file package.json
```

## Notes

- Works on macOS with the `open` command
- The file will open in whatever application is set as the default for that file type
- For text files, this is typically your default text editor (VS Code, TextEdit, etc.)
- The command returns immediately; you edit the file outside of Claude
