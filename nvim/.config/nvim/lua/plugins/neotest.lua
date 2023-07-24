return {
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      -- The latest version of neotest-jest is broken, so we use a fork that
      -- has a fix for monorepos in it. See https://github.com/nvim-neotest/neotest-jest/issues/60
      -- for more info.
      -- "nvim-neotest/neotest-jest",
      { "guivazcabral/neotest-jest", commit = "fb49a6f" },
      "nvim-neotest/neotest-python",
    },
    opts = {
      adapters = {
        ["neotest-jest"] = {
          jestCommand = "npx jest",
        },
        ["neotest-python"] = {
          runner = "pytest",
        },
      },
      status = {
        enabled = true,
        signs = true,
        virtual_text = false,
      },
      icons = {
        passed = "",
        running = "",
        failed = "",
        unknown = "",
      },
    },
  },
}
