local Util = require("lazyvim.util")

return {
  {
    "akinsho/bufferline.nvim",
    keys = {
      {
        "<leader>ut",
        function()
          Util.toggle("showtabline", true, { 0, 2 })
        end,
        desc = "Toggle Tabs",
      },
    },
  },
}
