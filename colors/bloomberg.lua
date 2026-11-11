if vim.g.colors_name then
  vim.cmd("hi clear")
end
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "bloomberg"
vim.o.termguicolors = true

local function hi(group, fg, bg, style)
  vim.api.nvim_set_hl(0, group, {
    fg = fg,
    bg = bg or "none",
    bold = style == "bold",
    italic = style == "italic",
  })
end

hi("Normal", "#e0e0e0")
hi("Comment", "#666666", nil, "italic")
hi("String", "#33cc88")
hi("Number", "#ffc844")
hi("Boolean", "#ffc844")
hi("Constant", "#ffc844")
hi("Keyword", "#ff6a00", nil, "bold")
hi("Statement", "#ff6a00", nil, "bold")
hi("Function", "#4488cc")
hi("Type", "#33bbcc")
hi("Identifier", "#e0e0e0")
hi("Operator", "#ff6a00")
hi("PreProc", "#cc66aa")
hi("Special", "#ff8833")
hi("Todo", "#ff6a00", nil, "bold")
hi("LineNr", "#444444")
hi("CursorLineNr", "#ff6a00", nil, "bold")
hi("CursorLine", nil, "#1a1a1a")
hi("Cursor", "#ff6a00")
hi("SignColumn", nil, "none")
hi("VertSplit", "#444444")
hi("StatusLine", "#0d0d0d", "#ff6a00")
hi("StatusLineNC", "#666666", "#1a1a1a")
hi("Pmenu", "#e0e0e0", "#1a1a1a")
hi("PmenuSel", "#0d0d0d", "#ff6a00")
hi("PmenuSbar", nil, "#1a1a1a")
hi("PmenuThumb", nil, "#ff6a00")
hi("Search", "#0d0d0d", "#ffc844")
hi("IncSearch", "#0d0d0d", "#ff6a00")
hi("Visual", nil, "#333333")
hi("Directory", "#ff6a00")
hi("MatchParen", "#ff6a00", nil, "bold")
hi("DiagnosticError", "#ff6a00")
hi("DiagnosticWarn", "#ffc844")
hi("DiagnosticInfo", "#4488cc")
hi("DiagnosticHint", "#666666")
hi("FloatBorder", "#444444")
hi("NeoTreeNormal", nil, "none")
hi("NeoTreeNormalNC", nil, "none")
hi("NeoTreeFloatBorder", "#444444")
