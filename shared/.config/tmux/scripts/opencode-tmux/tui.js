// Mirrors this TUI's session state into tmux (@claude_state) via claude-state.sh.
// Tabs are per TUI process; the server's event stream is shared by every opencode window.
import { execFile, execFileSync } from "node:child_process"
import { homedir } from "node:os"

const script = `${homedir()}/.config/tmux/scripts/claude-state.sh`

export default {
  id: "tmux-state",
  setup: (ctx) => {
    if (!process.env.TMUX_PANE) return
    let last = "idle"
    const tick = () => {
      let tabs = []
      try { tabs = ctx.ui.tabs.list() } catch {}
      const state = tabs.some((t) => t.attention) ? "wait" : tabs.some((t) => t.busy) ? "busy" : "idle"
      if (state === last) return
      last = state
      execFile(script, [state], () => {})
    }
    const clear = () => {
      try { execFileSync(script, ["clear"]) } catch {}
    }
    const timer = setInterval(tick, 250)
    process.once("exit", clear)
    return () => {
      clearInterval(timer)
      process.removeListener("exit", clear)
      clear()
    }
  },
}
