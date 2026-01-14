if vim.g.vscode then
  return {}
end

return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/mcphub.nvim", -- MCP integration
    },
    opts = {
      adapters = {
        -- GitHub Copilot (default - uses existing copilot.lua auth)
        copilot = function()
          return require("codecompanion.adapters").extend("copilot", {
            schema = {
              model = {
                default = "claude-sonnet-4.5",
              },
            },
          })
        end,

        -- OpenAI (requires OPENAI_API_KEY env var)
        -- To use: export OPENAI_API_KEY='your-key-here'
        openai = function()
          return require("codecompanion.adapters").extend("openai", {
            env = {
              api_key = "OPENAI_API_KEY",
            },
            schema = {
              model = {
                default = "gpt-4o", -- Note: Codex models are deprecated, using gpt-4o
              },
            },
          })
        end,

        -- Claude Code via Agent Client Protocol
        -- Requires: npm install -g @zed-industries/claude-code-acp
        -- Authentication: Uses ANTHROPIC_API_KEY env var
        claude_code = function()
          return require("codecompanion.adapters").extend("agent", {
            name = "claude_code",
            command = "claude-code-acp",
            env = {
              ANTHROPIC_API_KEY = vim.env.ANTHROPIC_API_KEY,
            },
          })
        end,

        -- Gemini CLI via Agent Client Protocol
        -- Requires: gemini-cli installed
        -- Install: npm install -g @google/generative-ai-cli
        -- Requires: GOOGLE_API_KEY env var
        gemini = function()
          return require("codecompanion.adapters").extend("agent", {
            name = "gemini",
            command = "gemini",
            args = { "chat", "--stdio" },
            env = {
              GOOGLE_API_KEY = vim.env.GOOGLE_API_KEY,
            },
            schema = {
              model = {
                default = "gemini-2.0-flash-exp",
              },
            },
          })
        end,
      },

      strategies = {
        chat = {
          adapter = "copilot", -- Default to copilot for chat
        },
        inline = {
          adapter = "copilot", -- Default to copilot for inline editing
        },
        agent = {
          adapter = "claude_code", -- Default agent
        },
      },

      display = {
        chat = {
          window = {
            layout = "vertical",
            width = 0.4,
            relative = "editor",
          },
          show_settings = false,
        },
        diff = {
          provider = "mini_diff",
        },
      },
    },

    keys = {
      -- Chat interface (replacing CopilotChat bindings)
      {
        "<leader>aa",
        "<cmd>CodeCompanionChat Toggle<cr>",
        desc = "Toggle Chat (CodeCompanion)",
        mode = { "n", "v" },
      },
      {
        "<leader>ax",
        function()
          vim.cmd("CodeCompanionChat")
          vim.cmd("normal! ggdG") -- Clear buffer
        end,
        desc = "Clear Chat (CodeCompanion)",
        mode = { "n", "v" },
      },
      {
        "<leader>aq",
        function()
          vim.ui.input({
            prompt = "Quick Chat: ",
          }, function(input)
            if input and input ~= "" then
              vim.cmd("CodeCompanionChat " .. input)
            end
          end)
        end,
        desc = "Quick Chat (CodeCompanion)",
        mode = { "n", "v" },
      },
      {
        "<leader>ap",
        "<cmd>CodeCompanionActions<cr>",
        desc = "Action Palette (CodeCompanion)",
        mode = { "n", "v" },
      },

      -- New CodeCompanion features
      {
        "<leader>at",
        "<cmd>CodeCompanion<cr>",
        desc = "Inline Assistant",
        mode = { "n", "v" },
      },
      {
        "<leader>av",
        "<cmd>CodeCompanionChat Add<cr>",
        desc = "Add to Chat",
        mode = "v",
      },

      -- Quick actions with prompts
      { "<leader>ae", "<cmd>CodeCompanion /explain<cr>", desc = "Explain Code", mode = "v" },
      { "<leader>ao", "<cmd>CodeCompanion /optimize<cr>", desc = "Optimize Code", mode = "v" },
      { "<leader>aT", "<cmd>CodeCompanion /tests<cr>", desc = "Generate Tests", mode = "v" },
    },

    config = function(_, opts)
      require("codecompanion").setup(opts)

      -- Buffer styling for codecompanion chat (like CopilotChat)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "codecompanion",
        callback = function()
          vim.opt_local.relativenumber = false
          vim.opt_local.number = false
        end,
      })
    end,
  },
}
