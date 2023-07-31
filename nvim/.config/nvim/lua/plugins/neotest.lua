return {
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "nvim-neotest/neotest-jest",
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
