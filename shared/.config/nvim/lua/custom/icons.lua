local ok, webicons = pcall(require, "nvim-web-devicons")
if not ok then
    return
end

webicons.set_icon({
    move = {
        icon = "○", -- ganti sesuai icon yang kamu suka
        color = "#4FC3F7",
        name = "Move",
    },
})
