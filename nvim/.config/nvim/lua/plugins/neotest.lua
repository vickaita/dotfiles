return {
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "nvim-neotest/neotest-jest",
      "nvim-neotest/neotest-python",
      "marilari88/neotest-vitest",
    },
    opts = {
      adapters = {
        ["neotest-jest"] = {
          jestCommand = "npx jest",
        },
        ["neotest-python"] = {
          runner = "pytest",
        },
        ["neotest-vitest"] = {
          command = "vitest",
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
