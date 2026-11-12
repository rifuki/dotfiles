// Mirrors the session open in this TUI into tmux (@claude_state) via claude-state.sh.
// Tabs are shared by every opencode window, so only the routed session and its subagents count.
import { execFile, execFileSync } from "node:child_process"
import { homedir } from "node:os"

const script = `${homedir()}/.config/tmux/scripts/claude-state.sh`

export default {
  id: "tmux-state",
  setup: (ctx) => {
    if (!process.env.TMUX_PANE) return
    const ses = ctx.data.session
    let last = "idle"
    const tick = () => {
      let state = "idle"
      try {
        const id = ctx.ui.router.current().sessionID
        const family = id ? ses.family(id) : []
        if (family.some((s) => ses.permission.list(s).length || ses.form.list(s).length)) state = "wait"
        else if (family.some((s) => (ses.status(s) ?? "idle") !== "idle")) state = "busy"
      } catch {}
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
