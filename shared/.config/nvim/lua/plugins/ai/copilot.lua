return {
    "github/copilot.vim",
    enabled = function()
        local ok, profile = pcall(require, "utils.profile")
        return not (ok and profile.is_minimal)
    end,
    lazy = false,
}
