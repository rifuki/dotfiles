-- Opt-in: loads only once ~/.wakatime.cfg holds an API key.
return {
    "wakatime/vim-wakatime",
    lazy = false,
    cond = vim.uv.fs_stat(vim.fn.expand("~/.wakatime.cfg")) ~= nil,
}
