-- lazyvim.lua - LazyVim integration for supersonic.nvim
return {
  "qasimsk20/supersonic.nvim",
  config = function()
    require("supersonic").setup({
      -- Simple, clean configuration
      -- Plugin automatically detects LazyVim and integrates with leader /
      -- No complex setup needed - just works!
    })
  end,

  -- Optional: Add the install check command
  cmd = { "SupersonicInstallCheck" },
}