-- supersonic/config.lua - Minimal configuration
local M = {}

local default_config = {
  auto_install = false,
  binary_path = 'hgrep'
}

local user_config = {}

function M.setup(opts)
  user_config = vim.tbl_extend('force', default_config, opts or {})
end

function M.get(key)
  return user_config[key] or default_config[key]
end

return M