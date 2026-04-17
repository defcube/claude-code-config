#!/usr/bin/env bash
export LC_NUMERIC=C
# Claude Code status line
# Session total + response delta: both from cost.total_cost_usd (Claude's own calculation)
# Response delta resets to $0 after a >3s gap between status line calls

input=$(cat)

# --- Location / git ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
model_name=$(echo "$input" | jq -r '.model.display_name // empty')

cd "$cwd" 2>/dev/null || cd "$HOME"

dir_display=$(echo "$cwd" | awk -F'/' '{n=NF; if (n <= 3) print $0; else printf ".../%s/%s/%s", $(n-2), $(n-1), $n}')

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
branch_part=""
[ -n "$branch" ] && branch_part=$(printf "\033[1;35m[%s]\033[0m " "$branch")

status_part=""
ahead_behind_part=""
if [ -n "$branch" ]; then
  git_status=$(git --no-optional-locks status --porcelain 2>/dev/null)
  if [ -n "$git_status" ]; then
    staged=$(echo "$git_status" | grep -c '^[MARCD]')
    modified=$(echo "$git_status" | grep -c '^ M\|^MM')
    untracked=$(echo "$git_status" | grep -c '^??')
    status_symbols=""
    [ "$staged" -gt 0 ] && status_symbols="${status_symbols}+${staged}"
    [ "$modified" -gt 0 ] && status_symbols="${status_symbols}*${modified}"
    [ "$untracked" -gt 0 ] && status_symbols="${status_symbols}?${untracked}"
    [ -n "$status_symbols" ] && status_part=$(printf "\033[1;31m[%s]\033[0m " "$status_symbols")
  fi

  # Ahead/behind upstream (silent if no upstream configured)
  ab=$(git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
  if [ -n "$ab" ]; then
    ahead=$(echo "$ab" | awk '{print $1}')
    behind=$(echo "$ab" | awk '{print $2}')
    ab_symbols=""
    [ "${ahead:-0}" -gt 0 ] && ab_symbols="${ab_symbols}↑${ahead}"
    [ "${behind:-0}" -gt 0 ] && ab_symbols="${ab_symbols}↓${behind}"
    [ -n "$ab_symbols" ] && ahead_behind_part=$(printf "\033[1;36m[%s]\033[0m " "$ab_symbols")
  fi
fi

line="${dir_display} ${branch_part}${status_part}${ahead_behind_part}"

# Model (compacted: strip common prefixes/suffixes)
if [ -n "$model_name" ]; then
  model_short=$(echo "$model_name" | sed -E 's/^Claude //; s/ \(.*\)$//')
  model_part=$(printf "\033[1;34m%s\033[0m" "$model_short")
  line="${line} | ${model_part}"
fi

# Context % — yellow <30%, red <15%
if [ -n "$remaining" ]; then
  if awk "BEGIN {exit !($remaining < 15)}"; then
    ctx_part=$(printf "\033[1;31mctx: %s%%\033[0m" "$remaining")
  elif awk "BEGIN {exit !($remaining < 30)}"; then
    ctx_part=$(printf "\033[1;33mctx: %s%%\033[0m" "$remaining")
  else
    ctx_part="ctx: ${remaining}%"
  fi
  line="${line} | ${ctx_part}"
fi

# --- Cost: session total + accumulating response delta (both from Claude) ---
session_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# State file: tracks response_start_cost and last update time
# If >3s since last update, assume new response and reset accumulator
state_dir="/tmp/claude-statusline"
mkdir -p "$state_dir"
state_file="${state_dir}/${session_id}.state"
now=$(date +%s)

prev_cost=0
response_start=0
last_time=0
if [ -f "$state_file" ]; then
  prev_cost=$(grep -o 'prev_cost=[0-9.]*' "$state_file" | cut -d= -f2)
  response_start=$(grep -o 'response_start=[0-9.]*' "$state_file" | cut -d= -f2)
  last_time=$(grep -o 'last_time=[0-9]*' "$state_file" | cut -d= -f2)
  prev_cost=${prev_cost:-0}
  response_start=${response_start:-0}
  last_time=${last_time:-0}
fi

# If >3s gap, this is a new response — reset accumulator
elapsed=$(( now - last_time ))
if [ "$elapsed" -gt 3 ] || [ "$last_time" -eq 0 ]; then
  response_start=$prev_cost
fi

# Persist state
printf "prev_cost=%s response_start=%s last_time=%s\n" \
  "$session_cost" "$response_start" "$now" > "$state_file"

cost_part=$(awk \
  -v session="$session_cost" \
  -v resp_start="$response_start" \
'BEGIN {
  resp_delta = session - resp_start
  printf "$%.2f", session
  if (resp_delta > 0.0001) {
    printf " (+$%.2f)", resp_delta
  }
}')

if [ -n "$cost_part" ]; then
  line="${line} | ${cost_part}"
fi

echo "$line"
