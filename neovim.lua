return {
  {
    "omacom/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg = "#141615",
        dark_bg = "#0f1110",
        darker_bg = "#0a0b0a",
        lighter_bg = "#1e2220",

        fg = "#c4ddd0",
        dark_fg = "#7d9689",
        light_fg = "#d8ebe1",
        bright_fg = "#eef7f2",
        muted = "#54685e",

        red = "#ff4526",
        yellow = "#e5a93c",
        orange = "#ff5a1f",
        green = "#9ecab3",
        cyan = "#7db5a3",
        blue = "#6e9896",
        magenta = "#d96b43",
        brown = "#7a3b24",

        bright_red = "#ff6b52",
        bright_yellow = "#f5c25b",
        bright_green = "#b8dfcb",
        bright_cyan = "#9fd4c3",
        bright_blue = "#8ab8b5",
        bright_magenta = "#f0855d",

        accent = "#ff5a1f",
        cursor = "#eef7f2",
        foreground = "#c4ddd0",
        background = "#141615",
        selection = "#25332c",
        selection_foreground = "#eef7f2",
        selection_background = "#25332c",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}
