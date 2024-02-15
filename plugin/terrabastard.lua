local terrabastard = require("terrabastard")

local user_command_prefix = "Terrabastard"

vim.api.nvim_create_user_command(user_command_prefix .. "ExtractIamPolicy", function(opts)
    terrabastard.extract_hard_policy()
end, {})
