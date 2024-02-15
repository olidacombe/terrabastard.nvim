local health = vim.health or require("health")

local M = {}

local required_binary = "terrabastard"

local function lualib_installed(lib_name)
	local res, _ = pcall(require, lib_name)
	return res
end

local required_plugins = {
	{ lib = "nvim-treesitter", optional = false },
	{ lib = "plenary", optional = false },
}

M.check = function()
	health.report_start("Checking for required plugins")
	for _, plugin in ipairs(required_plugins) do
		if lualib_installed(plugin.lib) then
			health.report_ok(plugin.lib .. " installed.")
		else
			local lib_not_installed = plugin.lib .. " not found."
			if plugin.optional then
				health.report_warn(("%s %s"):format(lib_not_installed, plugin.info))
			else
				health.report_error(lib_not_installed)
			end
		end
	end
	health.report_start("Checking for `" .. required_binary .. "` binary")
	if vim.fn.executable(required_binary) == 1 then
		health.report_ok("`" .. required_binary .. "` found.")
	else
		health.report_error("Required binary `" .. required_binary .. "` missing")
	end
end

return M
