```
 |                       |                |                 |
 __|  _ \  __|  __| _` | __ \   _` |  __| __|  _` |  __| _` |
 |    __/ |    |   (   | |   | (   |\__ \ |   (   | |   (   |
\__|\___|_|   _|  \__,_|_.__/ \__,_|____/\__|\__,_|_|  \__,_|
                                                             
```

# Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "olidacombe/terrabastard.nvim",
    dependencies = {
        { "nvim-lua/plenary.nvim" },
        { "nvim-treesitter/nvim-treesitter" },
    },
},
```

# Example keymap

You could add this to `after/ftplugin/terraform.lua`:

```lua
vim.keymap.set("n", "<leader><leader>p", ":TerrabastardExtractIamPolicy<cr>", {
    desc = "Extract IAM Policy",
    noremap = true,
    nowait = true,
    silent = true,
})
```
