return {
  { import = "lazyvim.plugins.extras.lang.python" },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "isort",
        "black",
        "ruff",
      },
    },
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    opts = function(_, opts)
      local nls = require("null-ls")
      table.insert(opts.sources, nls.builtins.formatting.isort)
      table.insert(opts.sources, nls.builtins.formatting.black)
    end,
  },
}
