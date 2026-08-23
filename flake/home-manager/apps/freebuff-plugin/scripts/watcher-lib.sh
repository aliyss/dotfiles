#!/bin/sh
# Shared functions for the freebuff status watcher.
# Sourced by status-watcher.sh and by tests.
#
# Provides: classify, detect_blocked, last_matching_ts, json_get, find_newest_chat

# JSON field extractor: usage: json_get key.path < file
json_get() {
  node -e '
    let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{
      try{const j=JSON.parse(d);const p=process.argv[1].split(".");let v=j;for(const k of p)v=v&&v[k];process.stdout.write(v==null?"":String(v))}catch{}
    })
  ' "$1"
}

# Resolve herdr binary path (used by detect_blocked_screen and status-watcher).
herdr_cmd() {
  if [ -n "${HERDR_BIN_PATH:-}" ]; then
    printf '%s' "$HERDR_BIN_PATH"
  else
    printf 'herdr'
  fi
}

# Read pane visible content and classify the on-screen state.
# freebuff flushes chat files only at end-of-turn, so file-based detection
# cannot see transient UI states (live question popup, answer echo immediately
# after submission, response-interrupted text after Esc). Screen content fills
# those gaps.
#
# The ask_user popup renders a bordered dialog with a Submit button and the
# hint "↑↓ navigate • Enter select"; suggest_followups (optional end-of-turn
# follow-ups) does not. Either of those strings uniquely identifies the live
# ask_user state.
#
# After the user answers, freebuff echoes the choice: "Your answer: <text>"
# followed within <=2 lines by a bordered box around the chosen answer.
# After Esc, freebuff prints "[response interrupted]" directly.
#
# Argument: pane_id. Echoes one of: blocked | interrupted | answered | ""
detect_screen_state() {
  pane_id="$1"
  [ -z "$pane_id" ] && return
  content=$("$(herdr_cmd)" pane read "$pane_id" --source visible --lines 200 2>/dev/null) || return

  # 1. Live popup — highest precedence
  printf '%s' "$content" | grep -qE "Enter select|↑↓ navigate" && { printf blocked; return; }

  # 2. Response interrupted (Esc) — chat files are still stale at this point
  printf '%s' "$content" | grep -qF '[response interrupted]' && { printf interrupted; return; }

  # 3. Answer just chosen — "Your answer:" followed within <=2 lines by
  #    a bordered box. The box is a strong signal that the answer-echo was
  #    rendered and the popup was dismissed.
  if printf '%s' "$content" | grep -A2 'Your answer:' | grep -qE '[╭│╰└┌]'; then
    printf answered
    return
  fi

  # 4. AI processing heartbeat — "• Thinking", "Thinking...", or "Working..."
  #     on screen. These persist for the entire duration of AI processing,
  #     bridging the gap between the "Your answer:" box scrolling off and
  #     file-based classification catching up (next Main prompt finished).
  #     The bullet "•" is Unicode U+2022.
  printf '%s' "$content" | grep -qE '• Thinking|Thinking\.\.\.|Working\.\.\.' && { printf thinking; return; }

  # 5. No signal — explicitly return 0 so callers with set -e don't abort
  return 0
}

# Detect if the latest ai message has an unresolved ask-user block.
# Reads chat-messages.json from stdin, echoes "blocked" or "".
detect_blocked() {
  node -e '
    let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{
      try{
        const msgs=JSON.parse(d);
        if(!Array.isArray(msgs))return;
        let lastAiIdx=-1,lastUserIdx=-1;
        for(let i=0;i<msgs.length;i++){
          const m=msgs[i];
          if(m.variant==="ai")lastAiIdx=i;
          if(m.variant==="user")lastUserIdx=i;
        }
        if(lastAiIdx<0)return;
        const lastAi=msgs[lastAiIdx];
        const hasAsk=Array.isArray(lastAi.blocks)&&lastAi.blocks.some(function(b){
          if(b.type==="ask-user")return true;
          if(b.type==="tool"&&b.toolName==="ask_user"){
            const q=b.input&&b.input.questions;
            return Array.isArray(q)&&q.length>0;
          }
          return false;
        });
        if(hasAsk&&lastAiIdx>lastUserIdx){
          process.stdout.write("blocked");
        }
      }catch(e){}
    })
  '
}

# Find the last timestamp of a log line whose msg field contains the given pattern.
# Reads log.jsonl from stdin, echoes the ISO timestamp or "".
last_matching_ts() {
  node -e '
    let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{
      const lines=d.trim().split("\n").filter(Boolean);
      let last="";const pat=process.argv[1];
      for(let i=lines.length-1;i>=0;i--){
        try{const j=JSON.parse(lines[i]);if(j.msg&&j.msg.indexOf(pat)>=0&&j.timestamp){last=j.timestamp;break;}}catch{}
      }
      process.stdout.write(last);
    })
  ' "$1"
}

# Find the newest chat directory across ALL projects in manicode config.
# Scans ~/.config/manicode/projects/*/chats/ for the most recently modified dir.
# Echoes the full path, or empty string if none found.
find_newest_chat() {
  node -e '
    const fs=require("fs"),path=require("path");
    const base=path.join(process.env.HOME,".config","manicode","projects");
    let newest="",newestTime=0;
    try{
      const projs=fs.readdirSync(base);
      for(const proj of projs){
        const chatsDir=path.join(base,proj,"chats");
        if(!fs.existsSync(chatsDir))continue;
        const chats=fs.readdirSync(chatsDir);
        for(const chat of chats){
          const p=path.join(chatsDir,chat);
          try{const s=fs.statSync(p);if(s.isDirectory()&&s.mtimeMs>newestTime){newestTime=s.mtimeMs;newest=p;}}catch{}
        }
      }
    }catch(e){}
    process.stdout.write(newest);
  ' 2>/dev/null
}

# Classify freebuff's current state from log.jsonl timeline only.
# No blocked check — just working vs idle based on log timestamps.
# Argument: chat directory path. Echoes: working | idle.
_classify_timeline() {
  chat_dir="$1"
  [ -d "$chat_dir" ] || { printf idle; return; }

  logf="$chat_dir/log.jsonl"
  last_start=""
  last_finish=""

  if [ -f "$logf" ]; then
    start_ts=$(last_matching_ts "Start agent" < "$logf")
    send_ts=$(last_matching_ts "[send-message]" < "$logf")
    finish_ts=$(last_matching_ts "Main prompt finished" < "$logf")

    [ -n "$start_ts" ] && last_start="$start_ts"
    if [ -n "$send_ts" ]; then
      if [ -z "$last_start" ] || [ "$(expr "$send_ts" \> "$last_start" 2>/dev/null)" = 1 ]; then
        last_start="$send_ts"
      fi
    fi

    last_finish="$finish_ts"
  fi

  if [ -n "$last_start" ] && [ -n "$last_finish" ]; then
    if [ "$(expr "$last_start" \> "$last_finish" 2>/dev/null)" = 1 ]; then
      printf working
    else
      printf idle
    fi
    return
  fi

  [ -n "$last_start" ] && { printf working; return; }
  [ -n "$last_finish" ] && { printf idle; return; }

  printf idle
}

# Classify freebuff's current state from chat files only.
# Argument: chat directory path. Echoes: blocked | working | idle.
_classify_files() {
  chat_dir="$1"
  [ -d "$chat_dir" ] || { printf idle; return; }

  msgs="$chat_dir/chat-messages.json"

  # 1. Blocked: unresolved ask-user block.
  # freebuff finishes the turn (Main prompt finished) BEFORE showing an ask-user
  # multiple-choice question, so blocked must be checked first regardless of
  # turn state. Once the user replies, lastUserIdx > lastAiIdx and blocked clears.
  if [ -f "$msgs" ]; then
    blocked=$(detect_blocked < "$msgs" 2>/dev/null)
    [ "$blocked" = "blocked" ] && { printf blocked; return; }
  fi

  # 2. Timeline-based working / idle
  _classify_timeline "$chat_dir"
}

# Classify freebuff's current state.
#
# When pane_id is available, the visible screen content is authoritative:
#   - ask_user popup visible  → blocked
#   - answer echo / thinking heartbeat on screen → working
#   - [response interrupted] on screen → idle
#   - no screen signal → use timeline from log files (stale blocked is ignored
#     since the popup is visually absent)
#
# Without pane_id, falls back to full file-based detection (including the
# ask_user block check from chat-messages.json).
classify() {
  chat_dir="$1"
  pane_id="${2:-}"

  if [ -n "$pane_id" ]; then
    sig=$(detect_screen_state "$pane_id")   # blocked | interrupted | answered | thinking | ""

    # Screen signals are authoritative
    case "$sig" in
      blocked)
        printf blocked
        return
        ;;
      interrupted)
        printf idle
        return
        ;;
      answered|thinking)
        printf working
        return
        ;;
      "")
        # No screen signal — popup is visually absent so any file-based
        # "blocked" would be stale. Use the log timeline directly.
        _classify_timeline "$chat_dir"
        return
        ;;
    esac
  fi

  # No pane_id: file-based detection (including blocked check from messages)
  _classify_files "$chat_dir"
}
