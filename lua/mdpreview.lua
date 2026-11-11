-- mdpreview.lua — yazi-style previews for markdown, rendered INSIDE neovim.
-- Pipeline: markdown → PDF (pandoc + weasyprint) → PNG (pdftoppm) → image.nvim
-- (uses kitty's graphics protocol, like yazi's previews).
--
--   :MdPreview [page]    preview current md as a rendered document (default page 1)
--   :MdSlides [page]     preview as slides (each ## = one page)
--   :MdExport <fmt>      export docx|pptx|pdf|html next to the md file (no viewer)
--   :MdOpen              one-shot external open of the last rendered PDF (Preview.app)
--
-- After the first preview, every :w re-renders and refreshes the image.
-- Keymaps: <leader>mp preview, <leader>ms slides, <leader>me export,
--          <leader>mo open external, <leader>mv toggle markview inline render

local M = {}

local pandoc = "/opt/homebrew/bin/pandoc"
local pdftoppm = "/opt/homebrew/bin/pdftoppm"

local function cache(name)
  return vim.fn.stdpath("cache") .. "/" .. name
end

local function write_css(name, content)
  local path = cache(name)
  local f = io.open(path, "w")
  if f then
    f:write(content)
    f:close()
  end
  return path
end

local function doc_css()
  return write_css("mdpreview-doc.css", [[
body { font-family: Helvetica, Arial, sans-serif; line-height: 1.5; color: #222; }
h1, h2, h3 { color: #111; }
table { border-collapse: collapse; width: 100%; margin: 1em 0; }
th, td { border: 1px solid #bbb; padding: 6px 10px; }
th { background: #f2f2f2; }
code { background: #f5f5f5; padding: 2px 4px; border-radius: 3px; }
pre { background: #f5f5f5; padding: 10px; border-radius: 4px; }
pre code { background: none; padding: 0; }
blockquote { border-left: 4px solid #ccc; margin-left: 0; padding-left: 12px; color: #555; }
]])
end

local function slide_css()
  return write_css("mdpreview-slides.css", [[
@page { size: 1280px 720px; margin: 60px; }
body { font-size: 24px; line-height: 1.5; }
h1 { font-size: 52px; }
h2 { page-break-before: always; font-size: 42px; margin-top: 0; }
table { border-collapse: collapse; margin: 1em 0; }
th, td { border: 1px solid #bbb; padding: 6px 12px; }
]])
end

local function md_to_pdf(src, pdf, css)
  local cmd = { pandoc, src, "--from=gfm", "-o", pdf, "--pdf-engine=weasyprint" }
  if css then
    vim.list_extend(cmd, { "--css", css })
  end
  local res = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("mdpreview: pandoc failed: " .. vim.trim(res), vim.log.levels.ERROR)
    return false
  end
  return true
end

local function pdf_to_pngs(pdf, prefix)
  local res = vim.fn.system({ pdftoppm, "-png", "-r", "110", pdf, prefix })
  if vim.v.shell_error ~= 0 then
    vim.notify("mdpreview: pdftoppm failed: " .. vim.trim(res), vim.log.levels.ERROR)
    return nil
  end
  return vim.fn.glob(prefix .. "-*.png", false, true)
end

function M.show_image(path)
  local ok, image = pcall(require, "image")
  if not ok then
    vim.notify("mdpreview: image.nvim not available", vim.log.levels.ERROR)
    return
  end
  -- Reuse a single preview window instead of stacking new splits
  if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
    local win = vim.fn.bufwinid(M.buf)
    if win ~= -1 then vim.api.nvim_win_close(win, true) end
    pcall(vim.api.nvim_buf_delete, M.buf, { force = true })
  end
  local ok2, buf = pcall(image.from_file, path)
  if not ok2 then
    vim.notify("mdpreview: cannot render images in this terminal (needs kitty/wezterm/ghostty)", vim.log.levels.WARN)
    return
  end
  if type(buf) == "number" then M.buf = buf end
end

function M.preview(kind, page)
  if vim.bo.filetype ~= "markdown" and vim.bo.filetype ~= "" then
    vim.notify("mdpreview: buffer is not markdown (filetype: " .. vim.bo.filetype .. ")", vim.log.levels.WARN)
  end
  local src = vim.fn.expand("%:p")
  local name = vim.fn.fnamemodify(src, ":t:r")
  local pdf = cache("mdpreview-" .. name .. ".pdf")
  local prefix = cache("mdpreview-" .. name)
  local ok = md_to_pdf(src, pdf, kind == "slides" and slide_css() or doc_css())
  if not ok then return end
  local pngs = pdf_to_pngs(pdf, prefix)
  if not pngs or #pngs == 0 then return end
  page = page or 1
  if page > #pngs then page = #pngs end
  M.show_image(pngs[page])
  vim.b.md_preview_kind = kind
  vim.b.md_preview_page = page
  vim.notify("mdpreview: " .. kind .. " preview — page " .. page .. "/" .. #pngs .. " (updates on save)", vim.log.levels.INFO)
end

function M.export(fmt)
  local src = vim.fn.expand("%:p")
  local out = vim.fn.expand("%:p:r") .. "." .. fmt
  local cmd
  if fmt == "docx" then
    cmd = { pandoc, src, "--from=gfm", "-o", out }
  elseif fmt == "pptx" then
    cmd = { pandoc, src, "--from=gfm", "-o", out, "--slide-level=2" }
  elseif fmt == "pdf" then
    cmd = { pandoc, src, "--from=gfm", "-o", out, "--pdf-engine=weasyprint", "--css", doc_css() }
  elseif fmt == "html" then
    cmd = { pandoc, src, "--from=gfm", "-s", "-o", out }
  else
    vim.notify("mdpreview: unknown export format '" .. tostring(fmt) .. "' (docx|pptx|pdf|html)", vim.log.levels.ERROR)
    return
  end
  local res = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("mdpreview: export failed: " .. vim.trim(res), vim.log.levels.ERROR)
    return
  end
  vim.notify("mdpreview: exported → " .. out, vim.log.levels.INFO)
end

function M.open_external()
  local src = vim.fn.expand("%:p")
  local name = vim.fn.fnamemodify(src, ":t:r")
  local pdf = cache("mdpreview-" .. name .. ".pdf")
  if vim.fn.filereadable(pdf) ~= 1 then
    M.preview("doc")
    pdf = cache("mdpreview-" .. name .. ".pdf")
  end
  vim.fn.system({ "open", pdf })
  vim.notify("mdpreview: opened " .. pdf, vim.log.levels.INFO)
end

-- ===== Commands =====
vim.api.nvim_create_user_command("MdPreview", function(opts)
  M.preview("doc", tonumber(opts.args))
end, { nargs = "?", desc = "Render current md as a document preview inside neovim" })

vim.api.nvim_create_user_command("MdSlides", function(opts)
  M.preview("slides", tonumber(opts.args))
end, { nargs = "?", desc = "Render current md as slides inside neovim (each ## = a page)" })

vim.api.nvim_create_user_command("MdExport", function(opts)
  M.export(opts.args)
end, {
  nargs = 1,
  complete = function() return { "docx", "pptx", "pdf", "html" } end,
  desc = "Export md to docx/pptx/pdf/html next to the file",
})

vim.api.nvim_create_user_command("MdOpen", function()
  M.open_external()
end, { desc = "Open the rendered PDF externally (one-shot)" })

-- ===== Regenerate on save =====
vim.api.nvim_create_autocmd("BufWritePost", {
  desc = "mdpreview: refresh active preview",
  callback = function()
    if vim.b.md_preview_kind then
      M.preview(vim.b.md_preview_kind, vim.b.md_preview_page)
    end
  end,
})

-- ===== Keymaps =====
vim.keymap.set("n", "<leader>mp", "<cmd>MdPreview<CR>", { desc = "Preview md in nvim" })
vim.keymap.set("n", "<leader>ms", "<cmd>MdSlides<CR>", { desc = "Preview md as slides" })
vim.keymap.set("n", "<leader>me", "<cmd>MdExport ", { desc = "Export md (docx/pptx/pdf/html)" })
vim.keymap.set("n", "<leader>mo", "<cmd>MdOpen<CR>", { desc = "Open rendered PDF externally" })
vim.keymap.set("n", "<leader>mv", function() require("markview").toggle() end, { desc = "Toggle inline markdown render" })

return M
