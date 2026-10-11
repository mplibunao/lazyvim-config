# Switching Neovim Configurations

This document explains how Neovim configuration switching works via `NVIM_APPNAME`.

## How NVIM_APPNAME Works

Neovim looks for its configuration in `~/.config/$NVIM_APPNAME/`. When `NVIM_APPNAME` is unset, it defaults to `nvim`, using `~/.config/nvim/`.

By setting `NVIM_APPNAME`, you can maintain multiple independent configurations:

```
NVIM_APPNAME=nvim-lazy   → ~/.config/nvim-lazy/
NVIM_APPNAME=nvim-chad   → ~/.config/nvim-chad/
NVIM_APPNAME=nvim-astro  → ~/.config/nvim-astro/
(unset)                  → ~/.config/nvim/
```

Data directories also follow this pattern:

- `~/.local/share/$NVIM_APPNAME/`
- `~/.local/state/$NVIM_APPNAME/`
- `~/.cache/$NVIM_APPNAME/`

## The nvim-config Fish Function

Located at: `~/Projects/personal/dotfiles/fish/functions/a_mp/nvim-config.fish`

### Usage

```fish
nvim-config          # Show current configuration
nvim-config lazy     # Set to use ~/.config/nvim-lazy/
nvim-config chad     # Set to use ~/.config/nvim-chad/
nvim-config astro    # Set to use ~/.config/nvim-astro/
nvim-config default  # Reset to default ~/.config/nvim/
nvim-config reset    # Same as default
```

### Implementation Details

The function uses Fish universal variables (`-U`) and exports them (`-x`):

```fish
set -Ux NVIM_APPNAME "nvim-$argv[1]"
```

- `-U`: Universal variable - persists across sessions
- `-x`: Exported - available to child processes (including nvim)

Once set, the configuration persists until explicitly changed.

### Verification

```fish
# Check current setting
echo $NVIM_APPNAME

# See all universal variables
set -U | grep NVIM

# Manually unset
set -e NVIM_APPNAME
```

## Available Configurations

| Config     | Directory               | Description            |
| ---------- | ----------------------- | ---------------------- |
| default    | `~/.config/nvim/`       | Personal main config   |
| nvim-lazy  | `~/.config/nvim-lazy/`  | LazyVim distribution   |
| nvim-lua   | `~/.config/nvim-lua/`   | Legacy lua config      |
| nvim-chad  | `~/.config/nvim-chad/`  | NvChad distribution    |
| nvim-astro | `~/.config/nvim-astro/` | AstroNvim distribution |

## Common Gotcha: lv Abbreviation

The Fish abbreviation `lv` expands to `NVIM_APPNAME=nvim-lua nvim`, NOT `nvim-lazy`.

To use LazyVim:

```fish
nvim-config lazy
nvim  # or use 'v' abbreviation
```

## Running with Specific Config (One-off)

For a single invocation without changing the persistent setting:

```bash
# Run with specific config
NVIM_APPNAME=nvim-lazy nvim

# Run with default config (ignore current setting)
NVIM_APPNAME=nvim nvim

# Run without any config
nvim -u NONE
```

## Sharing Data Between Configs

By default, each config has isolated data directories (plugins, Mason installs, caches, logs) because Neovim’s `stdpath()` roots follow `NVIM_APPNAME`.

If you want to share Mason installs across configs, you must explicitly configure Mason’s install root (e.g. point multiple configs at a shared directory). Do not assume sharing without verifying the Mason path for the active config:

```bash
ls ~/.local/share/${NVIM_APPNAME:-nvim}/mason/
```

## Troubleshooting

### Wrong config loading

1. Check current setting: `echo $NVIM_APPNAME`
2. Verify directory exists: `ls ~/.config/$NVIM_APPNAME`
3. Check for typos in the name

### Config not persisting

1. Ensure using `nvim-config` function (not manual export)
2. Check universal variables: `set -U | grep NVIM`
3. New terminals should inherit the setting

### Resetting everything

```fish
# Clear the variable
set -e NVIM_APPNAME

# Verify
nvim-config  # Should show "Using default nvim"
```
