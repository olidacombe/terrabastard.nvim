local ts_utils = require("nvim-treesitter.ts_utils")
local ts = vim.treesitter
local parsers = require("nvim-treesitter.parsers")
local Job = require("plenary.job")

-- local debug_node = function(node)
-- 	vim.print("----")
-- 	P(ts.get_node_text(node, 0))
-- 	vim.print("----")
-- end

local M = {}

local get_root = function()
    local parser = parsers.get_parser()
    local tree = parser:parse()[1]
    local root = tree:root()
    return root
end

-- local assume_policy_literals_query = function()
-- 	local qs = [[
--         (attribute (identifier) @id (#eq? @id "assume_role_policy") (expression) @expr)
--     ]]
-- 	local lang = parsers.get_parser():lang()
-- 	local query = ts.query.parse(lang, qs)
-- 	return query
-- end

local get_expression_from_cursor = function()
    -- get node at cursor and:
    -- - walk up until you are at an identifier
    -- - get the expression child
    -- return expression, identifier
    local root = get_root()
    local identifier = nil
    local node = ts_utils.get_node_at_cursor()
    if node == root then
        return
    end
    while node:type() ~= "attribute" do
        if node == root then
            return
        end
        node = node:parent()
    end
    -- now we have found an "attribute"
    -- get the expression
    for child in node:iter_children() do
        if child:type() == "identifier" then
            identifier = ts_utils.get_node_text(child, 0)[1]
        elseif child:type() == "expression" then
            return child, identifier
        end
    end
end

local get_raw_expression
get_raw_expression = function(node)
    -- take an expression node and return a raw,
    -- uninterpolated string.
    -- I.e. strip away heredoc nodes
    -- and combine all others into a single string
    local raw = ""

    for child in node:iter_children() do
        local t = child:type()
        if t == "template_expr" or t == "heredoc_template" then
            raw = raw .. get_raw_expression(child)
        elseif t == "template_literal" or t == "template_interpolation" then
            raw = raw .. ts.get_node_text(child, 0)
        end
    end

    return raw
end

local get_resource_from_cursor = function()
    -- get node at cursor and:
    -- - walk up until you are at a block
    -- - (skip) check child `identifier` is "resource"
    -- - grab line number L
    -- - get second child `string_lit` I
    -- - return I, L
    local node = ts_utils.get_node_at_cursor()
    local root = get_root()

    while node:type() ~= "block" do
        -- something went wrong,
        -- Return a thing that will be rubbish but work
        if node == root then
            return "change_me", 0
        end
        node = node:parent()
    end
    -- now we have found a "block"
    -- get the line number
    local line_n = ts.get_node_range(node)

    -- create a suffix.  If we figure out we're dealing with a "aws_iam_role", then add "-assume"
    local suffix = ""
    -- get the name (we will just re-use it assuming that it's for a different resource type)
    local name = "change_me"
    for child in node:iter_children() do
        if child:type() == "string_lit" then
            for grandchild in child:iter_children() do
                if grandchild:type() == "template_literal" then
                    name = ts_utils.get_node_text(grandchild, 0)[1]
                    if name == "aws_iam_role" then
                        suffix = "-assume"
                    end
                end
            end
        end
    end
    return name .. suffix, line_n
end

local policy_document_from_raw = function(raw, name)
    local out = {}
    Job:new({
        command = "terrabastard",
        args = {
            "aws",
            "iam",
            "convert-json-policy",
            "-n",
            name,
        },
        on_exit = function(j)
            P("terrabastard out")
            P(j:result())
            out = j:result()
        end,
        writer = { raw },
    }):sync()
    if #out == 0 then
        return
    end
    return out
end

local replace_node = function(node, replacement)
    local start_row, start_col, end_row, end_col = node:range(false)
    vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, replacement)
end

M.extract_hard_policy = function()
    local resource_name, insert_point = get_resource_from_cursor()
    if resource_name == nil then
        return
    end
    local data_resource_name = resource_name
    local node = get_expression_from_cursor()
    if node == nil then
        return
    end
    local raw = get_raw_expression(node)
    if raw == nil then
        return
    end
    local policy_document = policy_document_from_raw(raw, data_resource_name)
    if policy_document == nil then
        error("Failed to decode policy :'(")
        return
    end
    replace_node(node, { "data.aws_iam_policy_document." .. data_resource_name .. ".json" })
    vim.api.nvim_buf_set_lines(0, insert_point, insert_point, false, policy_document)
end

return M
