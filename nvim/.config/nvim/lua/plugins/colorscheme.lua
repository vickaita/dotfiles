if vim.g.vscode then
  return {}
end

local default = "catppuccin"
local scheme = (os.getenv("NEOVIM_COLORSCHEME") or default):lower()

local themes = {
  { slug = "EdenEast/nightfox.nvim", pat = "fox" },
  { slug = "catppuccin/nvim", pat = "catppuccin" },
  { slug = "ellisonleao/gruvbox.nvim", pat = "gruvbox" },
  { slug = "embark-theme/vim", pat = "embark" },
  { slug = "folke/tokyonight.nvim", pat = "tokyonight" },
  { slug = "ishan9299/nvim-solarized-lua", pat = "solarized" },
  { slug = "lifepillar/vim-solarized8", pat = "solarized" },
  { slug = "rafamadriz/neon", pat = "neon" },
  { slug = "sainnhe/everforest", pat = "everforest" },
  { slug = "sainnhe/sonokai", pat = "sonokai" },
}

local result = {}

for _, t in ipairs(themes) do
  table.insert(result, {
    t.slug,
    lazy = not scheme:match(t.pat),
    priority = 1000,
    config = function()
      if scheme:match(t.pat) then
        if scheme:match("%f[%a]light%f[^%a]") then
          vim.o.background = "light"
        end
        local ok, err = pcall(vim.cmd, "colorscheme " .. scheme)
        if not ok then
          vim.notify("Colorscheme " .. scheme .. " not found: " .. err, vim.log.levels.WARN)
        else
          -- Make ~ characters match line number colors
          local function set_endbuffer_highlight()
            -- Get LineNr highlight and apply it to EndOfBuffer
            local linenr_hl = vim.api.nvim_get_hl(0, { name = "LineNr" })
            if linenr_hl and linenr_hl.fg then
              vim.api.nvim_set_hl(0, "EndOfBuffer", { fg = linenr_hl.fg, bg = linenr_hl.bg })
            else
              -- Fallback: try linking if we can't get the colors
              vim.cmd("highlight link EndOfBuffer LineNr")
            end
          end

          vim.schedule(set_endbuffer_highlight)

          -- Also set up autocmd to handle colorscheme changes
          vim.api.nvim_create_autocmd("ColorScheme", {
            callback = set_endbuffer_highlight,
            desc = "Make EndOfBuffer match LineNr colors",
          })
        end
      end
    end,
  })
end

return result
