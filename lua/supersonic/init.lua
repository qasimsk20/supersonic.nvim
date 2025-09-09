-- supersonic.nvim - Neovim plugin for hypergrep
-- Depends on official hypergrep: https://github.com/p-ranav/hypergrep

local M = {}

function M.setup(opts)
  opts = opts or {}

  -- Validate configuration
  local config = M.validate_config(opts)

  -- Ensure install path exists
  M.ensure_install_path(config.install_path)

  local installed_this_session = false

  -- Check if hypergrep is available
  if not M.has_hypergrep(config.binary_path) then
    if config.auto_install then
      local success, err = M.install_hypergrep(config)
      if success then
        vim.notify('supersonic.nvim: hypergrep installed successfully!', vim.log.levels.INFO)
        installed_this_session = true
      else
        vim.notify('supersonic.nvim: Failed to install hypergrep - ' .. (err or 'Unknown error'), vim.log.levels.ERROR)
        return
      end
    else
      M.show_install_instructions()
      return
    end
  end

  -- Setup enhanced grep integration
  M.setup_grep_integration(config.binary_path, config.grep_flags)

  -- Add install path to PATH if needed
  M.manage_path(config.install_path)

  -- Show activation notification only once after installation
  if installed_this_session or not M.has_shown_activation_notification() then
    vim.notify('supersonic.nvim: Search performance activated with hypergrep', vim.log.levels.INFO)
    M.mark_activation_notification_shown()
  end
end

function M.validate_config(opts)
  local config = {
    binary_path = opts.binary_path or 'hgrep',
    install_path = opts.install_path or vim.fn.expand('~/.local/bin'),
    auto_install = opts.auto_install or false,
    grep_flags = opts.grep_flags or '--line-number --column --hidden',
    version = opts.version or 'latest'
  }

  -- Validate paths
  if type(config.install_path) ~= 'string' or config.install_path == '' then
    error('Invalid install_path: must be a non-empty string')
  end

  -- Validate flags
  if type(config.grep_flags) ~= 'string' then
    error('Invalid grep_flags: must be a string')
  end

  -- Sanitize version
  if config.version ~= 'latest' and not config.version:match('^v%d+%.%d+%.%d+$') then
    error('Invalid version: must be "latest" or format vX.Y.Z')
  end

  return config
end

function M.has_hypergrep(binary_path)
  return vim.fn.executable(binary_path) == 1
end

function M.ensure_install_path(path)
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, 'p')
  end
end

function M.fetch_latest_version()
  local api_url = 'https://api.github.com/repos/p-ranav/hypergrep/releases/latest'
  local cmd = 'curl -s ' .. api_url
  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    return nil, 'Failed to fetch latest version'
  end

  local data = vim.json.decode(result)
  if data and data.tag_name then
    return data.tag_name
  end
  return nil, 'Invalid API response'
end

function M.detect_tools()
  local tools = {
    downloader = M.has_tool('curl') and 'curl' or M.has_tool('wget') and 'wget',
    extractor = M.has_tool('unzip') and 'unzip' or M.has_tool('tar') and 'tar'
  }
  return tools
end

function M.has_tool(tool)
  return vim.fn.executable(tool) == 1
end

function M.show_install_instructions()
  local message = [[
hypergrep not found! Install the official hypergrep tool:

1. Download from GitHub releases:
   https://github.com/p-ranav/hypergrep/releases

2. Or run :SupersonicAutoInstall for automatic installation

3. Make sure 'hgrep' is in your PATH

Then restart Neovim and run :SupersonicInstallCheck
]]
  vim.notify(message, vim.log.levels.WARN)
end

function M.install_hypergrep(config)
  local version = config.version
  if version == 'latest' then
    local latest, err = M.fetch_latest_version()
    if not latest then
      return false, 'Failed to fetch latest version: ' .. (err or 'Unknown')
    end
    version = latest
  end

  vim.notify('supersonic.nvim: Installing hypergrep ' .. version .. '...', vim.log.levels.INFO)

  local platform = M.detect_platform()
  if not platform then
    return false, 'Unsupported platform for auto-installation'
  end

  local tools = M.detect_tools()
  if not tools.downloader then
    return false, 'No downloader found (curl or wget required)'
  end
  if not tools.extractor then
    return false, 'No extractor found (unzip or tar required)'
  end

  -- Download and install
  local success, err = M.download_and_install(platform, config, version, tools)
  if success then
    vim.notify('hypergrep installed to ' .. config.install_path .. '/hgrep', vim.log.levels.INFO)
    return true
  else
    return false, err or 'Installation failed'
  end
end

function M.detect_platform()
  local uname = vim.loop.os_uname()
  local sys = uname.sysname:lower()
  local arch = uname.machine:lower()

  local platform
  if sys:match('linux') then
    platform = 'linux'
  elseif sys:match('darwin') then
    platform = 'macos'
  elseif sys:match('windows') then
    platform = 'windows'
  else
    return nil
  end

  -- Include architecture
  if arch:match('x86_64') or arch:match('amd64') then
    return platform .. '-x64'
  elseif arch:match('aarch64') or arch:match('arm64') then
    return platform .. '-arm64'
  else
    return platform .. '-x64'  -- fallback
  end
end

function M.download_and_install(platform, config, version, tools)
  local base_url = "https://github.com/p-ranav/hypergrep/releases/download/" .. version
  local zip_name = "hg_" .. version:gsub('v', '') .. ".zip"
  local zip_url = base_url .. "/" .. zip_name

  local temp_dir = vim.fn.tempname()
  vim.fn.mkdir(temp_dir, 'p')

  -- Download zip
  local download_cmd
  if tools.downloader == 'curl' then
    download_cmd = string.format('curl -L "%s" -o "%s/%s"', zip_url, temp_dir, zip_name)
  elseif tools.downloader == 'wget' then
    download_cmd = string.format('wget -O "%s/%s" "%s"', temp_dir, zip_name, zip_url)
  end

  local download_result = vim.fn.system(download_cmd)
  if vim.v.shell_error ~= 0 then
    vim.fn.delete(temp_dir, 'rf')
    return false, 'Download failed: ' .. download_result
  end

  -- Extract
  local extract_cmd
  if tools.extractor == 'unzip' then
    extract_cmd = string.format('unzip -q "%s/%s" -d "%s"', temp_dir, zip_name, temp_dir)
  elseif tools.extractor == 'tar' then
    extract_cmd = string.format('tar -xf "%s/%s" -C "%s"', temp_dir, zip_name, temp_dir)
  end

  local extract_result = vim.fn.system(extract_cmd)
  if vim.v.shell_error ~= 0 then
    vim.fn.delete(temp_dir, 'rf')
    return false, 'Extraction failed: ' .. extract_result
  end

  -- Move binary
  local binary_path = config.install_path .. '/hgrep'
  local move_cmd = string.format('mv "%s/hg" "%s"', temp_dir, binary_path)
  local move_result = vim.fn.system(move_cmd)
  if vim.v.shell_error ~= 0 then
    vim.fn.delete(temp_dir, 'rf')
    return false, 'Move failed: ' .. move_result
  end

  -- Make executable (skip on Windows)
  if not platform:match('windows') then
    local chmod_cmd = string.format('chmod +x "%s"', binary_path)
    vim.fn.system(chmod_cmd)
  end

  -- Cleanup
  vim.fn.delete(temp_dir, 'rf')

  return true
end

function M.setup_grep_integration(binary_path, flags)
  -- Enhanced integration for multiple grep commands
  vim.o.grepprg = binary_path .. ' ' .. flags
  vim.o.grepformat = '%f:%l:%c:%m'

  -- Also set for lgrep and vimgrep if available
  if vim.fn.exists(':lgrep') == 2 then
    vim.o.grepprg = binary_path .. ' ' .. flags
  end
  if vim.fn.exists(':vimgrep') == 2 then
    vim.o.grepprg = binary_path .. ' ' .. flags
  end
end

function M.manage_path(install_path)
  local path_env = vim.env.PATH or ''
  if not path_env:find(install_path, 1, true) then
    vim.env.PATH = install_path .. ':' .. path_env
    vim.notify('Added ' .. install_path .. ' to PATH', vim.log.levels.INFO)
  end
end

function M.get_notification_flag_path()
  local data_dir = vim.fn.stdpath('data')
  return data_dir .. '/supersonic_activation_shown'
end

function M.has_shown_activation_notification()
  local flag_path = M.get_notification_flag_path()
  return vim.fn.filereadable(flag_path) == 1
end

function M.mark_activation_notification_shown()
  local flag_path = M.get_notification_flag_path()
  local file = io.open(flag_path, 'w')
  if file then
    file:write('1')
    file:close()
  end
end

function M.uninstall_hypergrep(config)
  local binary_path = config.install_path .. '/hgrep'
  if vim.fn.filereadable(binary_path) == 1 then
    vim.fn.delete(binary_path)
    vim.notify('hypergrep uninstalled from ' .. binary_path, vim.log.levels.INFO)
    return true
  else
    vim.notify('hypergrep not found at ' .. binary_path, vim.log.levels.WARN)
    return false
  end
end

function M.check_cpu_support()
  -- Check for AVX2 support (basic check)
  local cpu_info = vim.fn.system('grep -q avx2 /proc/cpuinfo && echo "yes" || echo "no"')
  return cpu_info:gsub('\n', '') == 'yes'
end

function M.health_check()
  local issues = {}

  if not M.has_hypergrep('hgrep') then
    table.insert(issues, 'hypergrep binary not found')
  end

  local tools = M.detect_tools()
  if not tools.downloader then
    table.insert(issues, 'No downloader (curl/wget) available')
  end
  if not tools.extractor then
    table.insert(issues, 'No extractor (unzip/tar) available')
  end

  if not M.check_cpu_support() then
    table.insert(issues, 'CPU may not support AVX2 (required for optimal hypergrep performance)')
  end

  if #issues == 0 then
    vim.notify('supersonic.nvim: All checks passed!', vim.log.levels.INFO)
  else
    vim.notify('supersonic.nvim issues: ' .. table.concat(issues, ', '), vim.log.levels.WARN)
  end
end

-- Commands
vim.api.nvim_create_user_command('SupersonicInstallCheck', function()
  if M.has_hypergrep('hgrep') then
    local version = vim.fn.system('hgrep --version 2>/dev/null')
    if vim.v.shell_error == 0 then
      vim.notify('✅ hypergrep is installed: ' .. version:gsub('\n', ''), vim.log.levels.INFO)
    else
      vim.notify('hypergrep found but not working', vim.log.levels.WARN)
    end
  else
    M.show_install_instructions()
  end
end, {})

vim.api.nvim_create_user_command('SupersonicAutoInstall', function()
  local config = M.validate_config({ install_path = vim.fn.expand('~/.local/bin'), version = 'latest' })
  local success, err = M.install_hypergrep(config)
  if not success then
    vim.notify('Auto-install failed: ' .. (err or 'Unknown'), vim.log.levels.ERROR)
  end
end, {})

vim.api.nvim_create_user_command('SupersonicVersion', function()
  local version = vim.fn.system('hgrep --version 2>/dev/null')
  if vim.v.shell_error == 0 then
    vim.notify('hypergrep version: ' .. version:gsub('\n', ''), vim.log.levels.INFO)
  else
    vim.notify('hypergrep not found', vim.log.levels.WARN)
  end
end, {})

vim.api.nvim_create_user_command('SupersonicUninstall', function()
  local config = M.validate_config({ install_path = vim.fn.expand('~/.local/bin') })
  M.uninstall_hypergrep(config)
end, {})

vim.api.nvim_create_user_command('SupersonicHealth', function()
  M.health_check()
end, {})

return M