-- Orion N5 — Sharp industrial hardware geometry & aerospace border gradient
local active_border_color = hl.gradient("rgba(ff5a1fff)", "rgba(e5a93cff)", "rgba(9ecab3ff)", 45)
local inactive_border_color = hl.rgba(0x25332caa)

hl.config({
  general = {
    border_size = 2,
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },

  decoration = {
    rounding = 2,
    active_opacity = 1.0,
    inactive_opacity = 0.94,
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
})
