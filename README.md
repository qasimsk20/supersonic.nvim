<h1 align=center>supersonic.nvim</h1><div align="center">

![GitHub last commit](https://img.shields.io/github/last-commit/qasimsk20/supersonic.nvim?style=for-the-badge&labelColor=101418&color=%2389b4fa)
![GitHub Repo stars](https://img.shields.io/github/stars/qasimsk20/supersonic.nvim?style=for-the-badge&labelColor=101418&color=%23cba6f7)
![Repo size](https://img.shields.io/github/repo-size/qasimsk20/supersonic.nvim?style=for-the-badge&labelColor=101418&color=%23d3bfe6)
![License](https://img.shields.io/github/license/qasimsk20/supersonic.nvim?style=for-the-badge&labelColor=101418&color=%23cba6f7)

</div>
A Neovim plugin that integrates [hypergrep](https://github.com/p-ranav/hypergrep) for faster searching.

## 📋 Requirements

- [hypergrep](https://github.com/p-ranav/hypergrep) binary in PATH
- Neovim >= 0.7
- CPU with AVX2 support (for optimal SIMD performance)

## Installation

### Step 1: Install hypergrep

```bash
# Download from official repository
curl -L https://github.com/p-ranav/hypergrep/releases/download/v0.1.1/hg_0.1.1.zip -o hypergrep.zip
unzip hypergrep.zip
sudo mv hg /usr/local/bin/hgrep
chmod +x /usr/local/bin/hgrep

# Verify installation
hgrep --version
```

### Step 2: Install Plugin

#### LazyVim (Recommended)
```lua
-- lua/plugins/supersonic.lua
return {
  "qasimsk20/supersonic.nvim",
  config = function()
    require("supersonic").setup({
      auto_install = true  -- Enable automatic hypergrep installation
    })
  end,
}
```

#### Manual
```lua
use 'qasimsk20/supersonic.nvim'
require('supersonic').setup({
  auto_install = true
})
```

## 📖 Usage

### Usage

After installation, the plugin automatically replaces Neovim's grep with hypergrep:

```vim
:grep "pattern"           " Uses hypergrep
:lgrep "pattern"          " Uses hypergrep
:vimgrep "pattern"        " Uses hypergrep
<cword> search            " Uses hypergrep
```

### LazyVim Integration

Works with LazyVim's `leader /` search functionality.

### Commands

```vim
:SupersonicInstallCheck    " Verify hypergrep is working
:SupersonicVersion         " Show hypergrep version
:SupersonicAutoInstall     " Automatically install latest hypergrep
:SupersonicUninstall       " Remove installed hypergrep
:SupersonicHealth          " Run health checks
```

## ⚙️ Configuration

```lua
require('supersonic').setup({
  binary_path = 'hgrep',           -- Path to hypergrep binary
  install_path = '~/.local/bin',   -- Where to install hypergrep if auto-installing
  auto_install = false,            -- Automatically download and install hypergrep
  grep_flags = '--line-number --column --hidden',  -- Additional flags for hypergrep
  version = 'latest'               -- Version of hypergrep to install ('latest' or specific vX.Y.Z)
})
```

## Performance

Hypergrep provides improved search performance compared to traditional tools:

| Search Type | ripgrep | hypergrep |
|-------------|---------|-----------|
| Simple literal | 1.5s | 0.7s |
| Complex regex | 6.9s | 0.8s |
| Git repos | 0.15s | 0.14s |
| Large files | Limited | Optimized |

*Based on official hypergrep benchmarks*

## Architecture

### Design

1. **Single Responsibility** - Plugin only handles Neovim integration
2. **Clean Dependencies** - Depends on official hypergrep tool
3. **No Duplication** - No C++ code in plugin repository
4. **Standard Patterns** - Follows common plugin practices

### Repository Structure

```
supersonic.nvim/
├── lua/supersonic/
│   └── init.lua         # Core plugin logic
├── README.md            # Documentation
├── lazyvim.lua          # LazyVim integration
└── LICENSE
```

hypergrep/               # Official tool repository
├── src/                # C++ source (p-ranav/hypergrep)
├── CMakeLists.txt      # Build system
└── releases/           # Pre-built binaries
```

## 🐛 Troubleshooting

### "hypergrep not found"
```bash
# Install from official repository
curl -L https://github.com/p-ranav/hypergrep/releases/download/v0.1.1/hg_0.1.1.zip -o hypergrep.zip
unzip hypergrep.zip
sudo mv hg /usr/local/bin/hgrep
chmod +x /usr/local/bin/hgrep
```

### Plugin not working

```lua
:SupersonicInstallCheck  # Check if hypergrep is available
:SupersonicVersion       # Show hypergrep version
:SupersonicAutoInstall   # Install hypergrep automatically
:hgrep --version         # Verify binary works
```

### Performance issues
Hypergrep uses Intel Hyperscan SIMD acceleration. Make sure your CPU supports AVX2. Run `:SupersonicHealth` to check compatibility.

## 🤝 Inspirations and Foundation 

- **[hypergrep](https://github.com/p-ranav/hypergrep)** - Official C++ tool (222⭐)
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** - Alternative fast grep
- **[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)** - Fuzzy finder

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **[p-ranav](https://github.com/p-ranav)** - Creator of hypergrep
- **[Intel Hyperscan](https://github.com/intel/hyperscan)** - SIMD regex acceleration
- **Neovim Community** - For the best text editor

---
