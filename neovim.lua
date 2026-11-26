-- Orion N5 // D350 Orbital Data System — Complete Neovim Theme & Industrial Telemetry UI
local palette = {
  bg = "#141615",
  dark_bg = "#0f1110",
  darker_bg = "#0a0b0a",
  lighter_bg = "#1e2220",
  selection = "#25332c",
  fg = "#c4ddd0",
  dark_fg = "#7d9689",
  light_fg = "#d8ebe1",
  bright_fg = "#eef7f2",
  muted = "#54685e",
  accent = "#ff5a1f",
  orange = "#ff5a1f",
  yellow = "#e5a93c",
  green = "#9ecab3",
  cyan = "#7db5a3",
  blue = "#6e9896",
  red = "#ff4526",
}

local function apply_orion_highlights()
  local hl = vim.api.nvim_set_hl

  -- Orion N5 banner highlights
  hl(0, "OrionN5Border", { fg = palette.muted })
  hl(0, "OrionN5Hex", { fg = palette.green, bold = true })
  hl(0, "OrionN5Title", { fg = palette.bright_fg, bold = true })
  hl(0, "OrionN5Accent", { fg = palette.accent, bold = true })
  hl(0, "OrionN5Sub", { fg = palette.dark_fg })
  hl(0, "OrionN5Amber", { fg = palette.yellow, bold = true })
  hl(0, "OrionN5Pill", { fg = palette.darker_bg, bg = palette.accent, bold = true })

  -- Sharp industrial borders and window chrome
  hl(0, "FloatBorder", { fg = palette.muted })
  hl(0, "FloatTitle", { fg = palette.bright_fg, bg = palette.lighter_bg, bold = true })
  hl(0, "WinSeparator", { fg = palette.selection })
  hl(0, "VertSplit", { fg = palette.selection })
  hl(0, "NeoTreeWinSeparator", { fg = palette.selection })
  hl(0, "CursorLineNr", { fg = palette.accent, bold = true })
  hl(0, "LineNr", { fg = palette.muted })

  -- Snacks dashboard hierarchy
  hl(0, "SnacksDashboardHeader", { fg = palette.green })
  hl(0, "SnacksDashboardIcon", { fg = palette.accent })
  hl(0, "SnacksDashboardKey", { fg = palette.bright_fg, bold = true })
  hl(0, "SnacksDashboardDesc", { fg = palette.fg })
  hl(0, "SnacksDashboardFile", { fg = palette.light_fg })
  hl(0, "SnacksDashboardDir", { fg = palette.dark_fg })
  hl(0, "SnacksDashboardSpecial", { fg = palette.accent, bold = true })
  hl(0, "SnacksDashboardFooter", { fg = palette.muted })

  -- Snacks indent & picker chrome
  hl(0, "SnacksIndent", { fg = palette.lighter_bg })
  hl(0, "SnacksIndentScope", { fg = palette.muted })
  hl(0, "SnacksPickerBorder", { fg = palette.muted })
  hl(0, "SnacksPickerTitle", { fg = palette.bright_fg, bg = palette.lighter_bg, bold = true })
  hl(0, "SnacksPickerPrompt", { fg = palette.accent, bold = true })

  -- WhichKey & Noice borders
  hl(0, "WhichKeyBorder", { fg = palette.muted })
  hl(0, "WhichKeyTitle", { fg = palette.bright_fg, bg = palette.lighter_bg, bold = true })
  hl(0, "NoiceCmdlinePopupBorder", { fg = palette.accent })
  hl(0, "NoiceCmdlinePopupTitle", { fg = palette.bright_fg, bg = palette.lighter_bg, bold = true })
  hl(0, "NoiceCmdlineIcon", { fg = palette.accent })
end

local function orion_banner_section()
  return {
    align = "center",
    padding = 1,
    text = {
      { "┌────────────────────────────────────────────────────────────────────┐\n", hl = "OrionN5Border" },
      { "│  ", hl = "OrionN5Border" },
      { "  ⬡⬡  ", hl = "OrionN5Hex" },
      { "  ORION N5 // D350", hl = "OrionN5Title" },
      { "                          ", hl = "OrionN5Sub" },
      { " SPEC 07.12 ", hl = "OrionN5Pill" },
      { "  │\n", hl = "OrionN5Border" },
      { "│  ", hl = "OrionN5Border" },
      { " ⬡", hl = "OrionN5Hex" },
      { "◈", hl = "OrionN5Accent" },
      { "⬡ ", hl = "OrionN5Hex" },
      { "  ORBITAL DATA SYSTEM", hl = "OrionN5Hex" },
      { "  //  GLOBAL TELEMETRY INDEX          │\n", hl = "OrionN5Sub" },
      { "│  ", hl = "OrionN5Border" },
      { "  ⬡⬡  ", hl = "OrionN5Hex" },
      { "  ━━━━━━━━━━━━━━", hl = "OrionN5Accent" },
      { "──────────────────────────────────────────  │\n", hl = "OrionN5Border" },
      { "├──────────────────┬──────────────────┬────────────────┬─────────────┤\n", hl = "OrionN5Border" },
      { "│ ", hl = "OrionN5Border" },
      { "SECTOR: ", hl = "OrionN5Sub" },
      { "UPLO-07 ", hl = "OrionN5Hex" },
      { " │ ", hl = "OrionN5Border" },
      { "LOCK: ", hl = "OrionN5Sub" },
      { "34 / 95   ", hl = "OrionN5Amber" },
      { " │ ", hl = "OrionN5Border" },
      { "ORBITS: ", hl = "OrionN5Sub" },
      { "12 GEO", hl = "OrionN5Title" },
      { " │ ", hl = "OrionN5Border" },
      { "LIVE.REC ● ", hl = "OrionN5Accent" },
      { "│\n", hl = "OrionN5Border" },
      { "└──────────────────┴──────────────────┴────────────────┴─────────────┘", hl = "OrionN5Border" },
    },
  }
end

vim.o.winborder = "single"

local group = vim.api.nvim_create_augroup("OrionN5UI", { clear = true })
vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  group = group,
  callback = apply_orion_highlights,
})
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "snacks_dashboard",
  callback = apply_orion_highlights,
})

return {
  {
    "omacom/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg = palette.bg,
        dark_bg = palette.dark_bg,
        darker_bg = palette.darker_bg,
        lighter_bg = palette.lighter_bg,

        fg = palette.fg,
        dark_fg = palette.dark_fg,
        light_fg = palette.light_fg,
        bright_fg = palette.bright_fg,
        muted = palette.muted,

        red = palette.red,
        yellow = palette.yellow,
        orange = palette.orange,
        green = palette.green,
        cyan = palette.cyan,
        blue = palette.blue,
        magenta = "#d96b43",
        brown = "#7a3b24",

        bright_red = "#ff6b52",
        bright_yellow = "#f5c25b",
        bright_green = "#b8dfcb",
        bright_cyan = "#9fd4c3",
        bright_blue = "#8ab8b5",
        bright_magenta = "#f0855d",

        accent = palette.accent,
        cursor = palette.bright_fg,
        foreground = palette.fg,
        background = palette.bg,
        selection = palette.selection,
        selection_foreground = palette.bright_fg,
        selection_background = palette.selection,
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      image = {
        enabled = true,
      },
      dashboard = {
        width = 70,
        preset = {
          keys = {
            { icon = " ", key = "f", desc = "FIND_FILE     // Locate Orbital Target", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "NEW_BUFFER    // Initialize Telemetry Sector", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "GREP_SOURCE   // Scan Repository Index", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "RECENT_LOGS   // Recall Accessed Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "c", desc = "SYS_CONFIG    // Edit Terminal Parameters", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = " ", key = "s", desc = "RESTORE_STATE // Resume Last Session", section = "session" },
            { icon = " ", key = "x", desc = "LAZY_EXTRAS   // Subsystem Modules", action = ":LazyExtras" },
            { icon = "󰒲 ", key = "l", desc = "LAZY_SYNC     // Package Manifest", action = ":Lazy" },
            { icon = " ", key = "q", desc = "TERMINATE     // Close D350 Session", action = ":qa" },
          },
        },
        sections = {
          function()
            apply_orion_highlights()
            return orion_banner_section()
          end,
          { section = "keys", gap = 0, padding = 1 },
          { section = "startup", padding = 0 },
          {
            text = {
              { "──[ ORION N5 // D350 ORBITAL DATA SYSTEM — UPLO-07 ]──", hl = "SnacksDashboardSpecial" },
            },
            align = "center",
          },
        },
      },
      indent = {
        indent = { char = "│" },
        scope = { char = "┃" },
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      win = {
        border = "single",
        title = " D350 // KEYMAP MATRIX ",
        title_pos = "center",
      },
    },
  },
  {
    "folke/noice.nvim",
    opts = {
      presets = {
        lsp_doc_border = true,
      },
      views = {
        cmdline_popup = {
          border = {
            style = "single",
            padding = { 0, 1 },
          },
        },
      },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      popup_border_style = "single",
    },
  },
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        separator_style = "thin",
        indicator = {
          icon = "▌",
          style = "icon",
        },
      },
    },
  },
}
