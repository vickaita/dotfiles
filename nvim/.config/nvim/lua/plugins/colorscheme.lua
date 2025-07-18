if vim.g.vscode then
  return {}
end

local default = "catppuccin"
local scheme  = (os.getenv("NEOVIM_COLORSCHEME") or default):lower()

local themes = {
  { slug = "EdenEast/nightfox.nvim",      pat = "fox"         },
  { slug = "catppuccin/nvim",             pat = "catppuccin"  },
  { slug = "ellisonleao/gruvbox.nvim",    pat = "gruvbox"     },
  { slug = "embark-theme/vim",            pat = "embark"      },
  { slug = "folke/tokyonight.nvim",       pat = "tokyonight"  },
  { slug = "ishan9299/nvim-solarized-lua",pat = "solarized"   },
  { slug = "lifepillar/vim-solarized8",   pat = "solarized"   },
  { slug = "rafamadriz/neon",             pat = "neon"        },
  { slug = "sainnhe/everforest",          pat = "everforest"  },
  { slug = "sainnhe/sonokai",             pat = "sonokai"     },
}

local result = {}

for _, t in ipairs(themes) do
  table.insert(result, {
    t.slug,
    lazy     = not scheme:match(t.pat),
    priority = 1000,
    config   = function()
      if scheme:match(t.pat) then
        if scheme:match("%f[%a]light%f[^%a]") then
          vim.o.background = "light"
        end
        local ok, err = pcall(vim.cmd, "colorscheme " .. scheme)
        if not ok then
          vim.notify("Colorscheme "..scheme.." not found: "..err, vim.log.levels.WARN)
        end
      end
    end,
  })
end

return result
