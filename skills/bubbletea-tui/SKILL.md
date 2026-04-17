---
name: bubbletea-tui
description: Use when building a terminal UI in Go with Bubble Tea and lipgloss
---

## 1. Overview

Bubble Tea follows MVU (Model-Update-View). Structure your model around panes and focus state, wire vim keybindings in Update, compose styled panes in View.

**Dependencies:** `github.com/charmbracelet/bubbletea`, `github.com/charmbracelet/lipgloss`

**When to use:** Any terminal dashboard, log viewer, inspector, or monitoring tool that needs a dual-pane layout with keyboard navigation.

## 2. Model Structure

```go
// Item represents a single entry in the list — define per project.
type Item struct {
    Label   string
    Content string
}

type pane int

const (
    paneLeft pane = iota
    paneRight
)

type model struct {
    // Layout
    width, height int
    focus         pane

    // Left pane — list
    cursor int
    items  []Item

    // Right pane — detail
    detailScroll int
    altView      bool // toggle between two detail renderings

    // Search
    searching   bool
    searchQuery string
    searchLines []int // line indices with matches
    searchIndex int   // current match index (-1 = none)
}
```

**Pane enum** controls which pane receives key events. **cursor** tracks the selected list item. **detailScroll** is the vertical offset for the right pane. **Search state** tracks incremental search across detail content.

Helper methods used by Update and View:

```go
func (m model) Init() tea.Cmd { return nil }

func (m model) contentHeight() int {
    return max(m.height-3, 1)
}

func (m model) maxDetailScroll(contentHeight int) int {
    totalLines := len(m.currentDetailLines())
    return max(totalLines-contentHeight, 0)
}

func (m model) updateSearchMatches() model {
    lines := m.currentDetailLines() // your detail content as []string
    m.searchLines = findSearchMatches(lines, m.searchQuery)
    if len(m.searchLines) > 0 {
        m.searchIndex = 0
    } else {
        m.searchIndex = -1
    }
    return m
}
```

**Note:** `renderList()`, `renderDetail()`, `renderStatusBar()`, and `currentDetailLines()` are project-specific — implement per your domain. They depend on your `Item` type and display requirements.

## 3. Update Loop

Top-level Update switches on `tea.Msg` type, delegates `tea.KeyMsg` to `handleKey()`. handleKey checks search mode first, then dispatches by key string.

```go
func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    switch msg := msg.(type) {
    case tea.WindowSizeMsg:
        m.width, m.height = msg.Width, msg.Height
    case itemMsg:
        // Auto-follow: advance cursor if already at end
        atEnd := m.cursor == len(m.items)-1 || len(m.items) == 0
        m.items = append(m.items, msg.Item)
        if atEnd {
            m.cursor = len(m.items) - 1
            m.detailScroll = 0
        }
    case tea.KeyMsg:
        return m.handleKey(msg)
    }
    return m, nil
}

func (m model) handleKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
    if m.searching {
        return m.handleSearchInput(msg)
    }
    contentHeight := m.contentHeight()
    switch msg.String() {
    case "q", "ctrl+c":
        return m, tea.Quit
    case "/":
        m.searching = true
        m.searchQuery = ""
        m.searchLines = nil
        m.searchIndex = -1
    case "tab":
        if m.focus == paneLeft { m.focus = paneRight } else { m.focus = paneLeft }
    case "left", "h":
        m.focus = paneLeft
    case "right", "l":
        m.focus = paneRight
    case "up", "k":
        if m.focus == paneLeft {
            if m.cursor > 0 { m.cursor--; m.detailScroll = 0 }
        } else {
            m.detailScroll = max(0, m.detailScroll-1)
        }
    case "down", "j":
        if m.focus == paneLeft {
            if m.cursor < len(m.items)-1 { m.cursor++; m.detailScroll = 0 }
        } else {
            m.detailScroll = min(m.maxDetailScroll(contentHeight), m.detailScroll+1)
        }
    case " ", "pgdown":
        if m.focus == paneLeft {
            m.cursor = min(len(m.items)-1, m.cursor+contentHeight)
            m.detailScroll = 0
        } else {
            m.detailScroll = min(m.maxDetailScroll(contentHeight), m.detailScroll+contentHeight)
        }
    case "pgup":
        if m.focus == paneLeft {
            m.cursor = max(0, m.cursor-contentHeight)
            m.detailScroll = 0
        } else {
            m.detailScroll = max(0, m.detailScroll-contentHeight)
        }
    case "g", "home":
        if m.focus == paneLeft { m.cursor = 0 }
        m.detailScroll = 0
    case "G", "end":
        if m.focus == paneLeft {
            m.cursor = len(m.items) - 1
        } else {
            m.detailScroll = m.maxDetailScroll(contentHeight)
        }
    case "J":
        m.altView = !m.altView
        m.detailScroll = 0
    case "n":
        if len(m.searchLines) > 0 {
            m.searchIndex = (m.searchIndex + 1) % len(m.searchLines)
            m = m.scrollToMatch(contentHeight)
        }
    case "N":
        if len(m.searchLines) > 0 {
            m.searchIndex--
            if m.searchIndex < 0 { m.searchIndex = len(m.searchLines) - 1 }
            m = m.scrollToMatch(contentHeight)
        }
    case "esc":
        m.searchQuery = ""
        m.searchLines = nil
        m.searchIndex = -1
    }
    return m, nil
}
```

Search input handler — separate function to keep handleKey clean:

```go
func (m model) handleSearchInput(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
    switch msg.Type {
    case tea.KeyEnter:
        m.searching = false
    case tea.KeyEscape:
        m.searching = false
        m.searchQuery = ""
        m.searchLines = nil
        m.searchIndex = -1
    case tea.KeyBackspace:
        if len(m.searchQuery) > 0 {
            m.searchQuery = m.searchQuery[:len(m.searchQuery)-1]
            m = m.updateSearchMatches()
        }
    case tea.KeyRunes:
        m.searchQuery += string(msg.Runes)
        m.updateSearchMatches()
    }
    return m, nil
}
```

## 4. View Rendering

Layout: left pane = 1/4 width, right = remainder. Inner width subtracts 4 for borders + padding. Content height subtracts 3 for status bar + borders.

```go
func (m model) View() string {
    if m.width == 0 {
        return "Initializing..."
    }
    contentHeight := m.contentHeight()

    leftOuter := m.width / 4
    rightOuter := m.width - leftOuter
    leftInner := max(leftOuter-4, 1)  // subtract border (2) + padding (2)
    rightInner := max(rightOuter-4, 1)

    leftContent := m.renderList(leftInner, contentHeight)
    rightContent := m.renderDetail(rightInner, contentHeight)

    // Active pane gets bright border
    ls, rs := normalBorder, normalBorder
    if m.focus == paneLeft { ls = activeBorder } else { rs = activeBorder }

    left := ls.Width(leftInner).Height(contentHeight).Render(leftContent)
    right := rs.Width(rightInner).Height(contentHeight).Render(rightContent)

    panes := lipgloss.JoinHorizontal(lipgloss.Top, left, right)
    return panes + "\n" + m.renderStatusBar()
}
```

Word-wrap helper for detail content:

```go
func wrapLine(line string, maxWidth int) []string {
    if maxWidth <= 0 || len(line) <= maxWidth {
        return []string{line}
    }
    var wrapped []string
    for len(line) > maxWidth {
        breakAt := maxWidth
        for i := maxWidth - 1; i >= 0; i-- { // find last space
            if line[i] == ' ' { breakAt = i; break }
        }
        wrapped = append(wrapped, line[:breakAt])
        line = line[breakAt:]
        if len(line) > 0 && line[0] == ' ' { line = line[1:] }
    }
    if len(line) > 0 { wrapped = append(wrapped, line) }
    return wrapped
}
```

Scroll clamping: `maxScroll = max(totalLines - contentHeight, 0)`.

## 5. Lipgloss Styling

Define styles as package-level vars. Two-tier border pattern: dim for inactive pane, bright for active.

```go
var (
    // Borders — two tiers: dim (inactive) and bright (active)
    normalBorder = lipgloss.NewStyle().
        Border(lipgloss.RoundedBorder()).
        BorderForeground(lipgloss.Color("240")).
        Padding(0, 1)

    activeBorder = lipgloss.NewStyle().
        Border(lipgloss.RoundedBorder()).
        BorderForeground(lipgloss.Color("205")). // bright pink/magenta
        Padding(0, 1)

    // List items
    selectedStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("205")).Bold(true)
    dimStyle      = lipgloss.NewStyle().Foreground(lipgloss.Color("240"))

    // Search highlighting — two tiers: all matches vs active match
    searchMatchStyle  = lipgloss.NewStyle().Background(lipgloss.Color("58")).Foreground(lipgloss.Color("230"))
    currentMatchStyle = lipgloss.NewStyle().Background(lipgloss.Color("208")).Foreground(lipgloss.Color("0")).Bold(true)

    // Structural
    sectionStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("33")).Bold(true)
    statusBarStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("240")).Padding(0, 1)
)
```

## 6. Goroutine Integration

Launch the TUI on the main goroutine, run background work in a separate goroutine. Communicate via `p.Send()` with custom message types.

```go
func main() {
    p := tea.NewProgram(newModel(), tea.WithAltScreen())
    go runWorker(p) // background goroutine
    if _, err := p.Run(); err != nil {
        log.Fatal(err)
    }
}

// Custom message types — simple structs
type itemMsg struct{ Item Item }
type stateMsg struct{ State string }

func runWorker(p *tea.Program) {
    p.Send(stateMsg{State: "running"})
    for item := range produceItems() {
        p.Send(itemMsg{Item: item})
    }
    p.Send(stateMsg{State: "done"})
}
```

**Auto-follow pattern:** Before appending a new item, check if cursor is already at the end. If so, advance cursor after append so the user stays at the latest entry.

```go
case itemMsg:
    atEnd := m.cursor == len(m.items)-1 || len(m.items) == 0
    m.items = append(m.items, msg.Item)
    if atEnd {
        m.cursor = len(m.items) - 1
        m.detailScroll = 0
    }
```

## 7. Search System

Incremental case-insensitive search over detail pane content. `/` enters search mode, characters build the query, matches update on each keystroke.

```go
func findSearchMatches(lines []string, query string) []int {
    lower := strings.ToLower(query)
    var matches []int
    for i, line := range lines {
        if strings.Contains(strings.ToLower(line), lower) {
            matches = append(matches, i)
        }
    }
    return matches
}

// Center match in viewport — value receiver, returns updated model.
// Callers should use: m = m.scrollToMatch(contentHeight)
func (m model) scrollToMatch(contentHeight int) model {
    matchLine := m.searchLines[m.searchIndex]
    m.detailScroll = max(matchLine-contentHeight/2, 0)
    m.detailScroll = min(m.detailScroll, m.maxDetailScroll(contentHeight))
    return m
}
```

Two-tier highlighting: iterate through line text, find query occurrences case-insensitively, wrap each in `searchMatchStyle` or `currentMatchStyle` depending on whether that line is the active match.

```go
func highlightSearchInLine(line, query string, isCurrentMatch bool) string {
    style := searchMatchStyle
    if isCurrentMatch { style = currentMatchStyle }

    lowerLine, lowerQuery := strings.ToLower(line), strings.ToLower(query)
    var result strings.Builder
    pos := 0
    for {
        idx := strings.Index(lowerLine[pos:], lowerQuery)
        if idx < 0 { result.WriteString(line[pos:]); break }
        result.WriteString(line[pos : pos+idx])
        result.WriteString(style.Render(line[pos+idx : pos+idx+len(query)]))
        pos += idx + len(query)
    }
    return result.String()
}
```

`n`/`N` cycle matches with wraparound. `scrollToMatch()` centers the match in the viewport.

## 8. Quick Reference

| Key | Left pane (list) | Right pane (detail) |
|-----|-------------------|---------------------|
| j/down | Cursor down | Scroll down 1 line |
| k/up | Cursor up | Scroll up 1 line |
| space/pgdn | Page down | Page down |
| pgup | Page up | Page up |
| g/home | Jump to first | Jump to top |
| G/end | Jump to last | Jump to bottom |
| h/left | -- | Focus left pane |
| l/right | Focus right pane | -- |
| tab | Toggle focus | Toggle focus |
| J | Toggle alt view | Toggle alt view |
| / | Enter search | Enter search |
| n/N | -- | Next/prev match |
| Esc | Clear search | Clear search |
| (search mode) type | -- | Append to query |
| (search mode) backspace | -- | Delete last char |
| (search mode) enter | -- | Confirm & exit search |
| (search mode) esc | -- | Cancel & clear search |
| q/ctrl+c | Quit | Quit |
