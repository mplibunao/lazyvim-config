#!/usr/bin/env bash
# nvim-locate.sh - Locate Neovim configuration files and resources
#
# Usage:
#   nvim-locate.sh                    # Show current config and paths
#   nvim-locate.sh configs            # List all available configs
#   nvim-locate.sh plugins [config]   # List plugins for config
#   nvim-locate.sh file <pattern>     # Find config files matching pattern
#   nvim-locate.sh lsp [config]       # Show LSP server locations
#   nvim-locate.sh logs [config]      # Show log file locations

set -euo pipefail

# Colors (disabled if not a terminal or NO_COLOR is set)
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Normalize a config argument into an NVIM_APPNAME-style name
normalize_config() {
    local config="${1:-}"
    if [[ -z "$config" ]]; then
        get_current_config
        return
    fi

    case "$config" in
        default|nvim)
            echo "nvim"
            ;;
        nvim-*)
            echo "$config"
            ;;
        *)
            echo "nvim-$config"
            ;;
    esac
}

# Get current NVIM_APPNAME
get_current_config() {
    if [[ -n "${NVIM_APPNAME:-}" ]]; then
        echo "$NVIM_APPNAME"
    else
        echo "nvim"
    fi
}

# Get config directory for a given config name
get_config_dir() {
    local config="${1:-$(get_current_config)}"
    echo "$HOME/.config/$config"
}

# Show current configuration info
show_current() {
    local current
    current=$(get_current_config)
    local config_dir
    config_dir=$(get_config_dir "$current")

    echo -e "${BLUE}Current Neovim Configuration${NC}"
    echo "================================"
    echo -e "Config name:  ${GREEN}$current${NC}"
    echo -e "Config dir:   ${config_dir}"

    if [[ -d "$config_dir" ]]; then
        echo -e "Status:       ${GREEN}exists${NC}"

        # Show key files
        echo ""
        echo "Key files:"
        for file in init.lua lazyvim.json lazy-lock.json; do
            if [[ -f "$config_dir/$file" ]]; then
                echo -e "  ${GREEN}✓${NC} $file"
            else
                echo -e "  ${YELLOW}○${NC} $file (not found)"
            fi
        done

        # Show lua directories
        echo ""
        echo "Lua directories:"
        for dir in lua/config lua/plugins; do
            if [[ -d "$config_dir/$dir" ]]; then
                local count
                count=$(find "$config_dir/$dir" -name "*.lua" 2>/dev/null | wc -l | tr -d ' ')
                echo -e "  ${GREEN}✓${NC} $dir ($count files)"
            else
                echo -e "  ${YELLOW}○${NC} $dir (not found)"
            fi
        done
    else
        echo -e "Status:       ${RED}not found${NC}"
    fi
}

# List all available configs
list_configs() {
    echo -e "${BLUE}Available Neovim Configurations${NC}"
    echo "=================================="

    local current
    current=$(get_current_config)

    for dir in "$HOME/.config"/nvim*; do
        if [[ -d "$dir" ]]; then
            local name
            name=$(basename "$dir")
            local marker=""

            if [[ "$name" == "$current" ]]; then
                marker=" ${GREEN}(current)${NC}"
            fi

            # Check if it's a LazyVim config
            local type="custom"
            if [[ -f "$dir/lazyvim.json" ]]; then
                type="LazyVim"
            elif [[ -f "$dir/init.lua" ]] && grep -q "lazy" "$dir/init.lua" 2>/dev/null; then
                type="lazy.nvim"
            fi

            echo -e "  ${name}${marker}"
            echo "    Path: $dir"
            echo "    Type: $type"
        fi
    done
}

# List plugins for a config
list_plugins() {
    local config="${1:-$(get_current_config)}"
    local config_dir
    config_dir=$(get_config_dir "$config")

    echo -e "${BLUE}Plugins for $config${NC}"
    echo "===================="

    # Check lazy-lock.json for installed plugins
    local lockfile="$config_dir/lazy-lock.json"
    if [[ -f "$lockfile" ]]; then
        echo "From lazy-lock.json:"
        jq -r 'keys[]' "$lockfile" 2>/dev/null | sort | while read -r plugin; do
            echo "  $plugin"
        done
    else
        echo -e "${YELLOW}No lazy-lock.json found${NC}"
    fi

    # Show plugin spec files
    local plugins_dir="$config_dir/lua/plugins"
    if [[ -d "$plugins_dir" ]]; then
        echo ""
        echo "Plugin spec files:"
        find "$plugins_dir" -name "*.lua" -type f | while read -r file; do
            echo "  $(basename "$file")"
        done
    fi
}

# Find config files matching pattern
find_files() {
    local pattern="${1:-}"

    if [[ -z "$pattern" ]]; then
        echo "Usage: nvim-locate.sh file <pattern>"
        exit 1
    fi

    echo -e "${BLUE}Finding files matching: $pattern${NC}"
    echo "======================================"

    for dir in "$HOME/.config"/nvim*; do
        if [[ -d "$dir" ]]; then
            local name
            name=$(basename "$dir")
            local results
            results=$(find "$dir" -type f -name "*$pattern*" 2>/dev/null)

            if [[ -n "$results" ]]; then
                echo ""
                echo -e "${GREEN}$name:${NC}"
                echo "$results" | while read -r file; do
                    echo "  ${file#"$dir"/}"
                done
            fi
        fi
    done
}

# Show LSP server locations
show_lsp() {
    echo -e "${BLUE}LSP Server Locations${NC}"
    echo "====================="

    local config
    config=$(normalize_config "${1:-}")
    local mason_dir="$HOME/.local/share/$config/mason"

    if [[ -d "$mason_dir" ]]; then
        echo "Mason directory: $mason_dir"
        echo ""

        local bin_dir="$mason_dir/bin"
        if [[ -d "$bin_dir" ]]; then
            echo "Installed servers:"
            # shellcheck disable=SC2012 # mason bin entries are alphanumeric server names
            ls -1 "$bin_dir" 2>/dev/null | while read -r server; do
                echo "  $server"
            done
        fi
    else
        echo -e "${YELLOW}Mason not installed or no servers installed${NC}"
    fi
}

# Show log locations
show_logs() {
    echo -e "${BLUE}Neovim Log Locations${NC}"
    echo "====================="

    local config
    config=$(normalize_config "${1:-}")

    local logs=(
        "$HOME/.local/state/$config/log:Neovim log"
        "$HOME/.local/state/$config/lsp.log:LSP log"
        "$HOME/.local/share/$config/mason/mason.log:Mason log"
        "$HOME/.cache/$config/lazy/pkg.log:Lazy pkg log"
    )

    for entry in "${logs[@]}"; do
        local path="${entry%%:*}"
        local desc="${entry#*:}"

        if [[ -f "$path" ]]; then
            local size
            size=$(du -h "$path" 2>/dev/null | cut -f1)
            echo -e "${GREEN}✓${NC} $desc"
            echo "    $path ($size)"
        else
            echo -e "${YELLOW}○${NC} $desc"
            echo "    $path (not found)"
        fi
    done
}

# Main
case "${1:-}" in
    configs|config|list)
        list_configs
        ;;
    plugins|plugin)
        list_plugins "${2:-}"
        ;;
    file|find)
        find_files "${2:-}"
        ;;
    lsp|servers)
        show_lsp "${2:-}"
        ;;
    logs|log)
        show_logs "${2:-}"
        ;;
    help|--help|-h)
        echo "Usage: nvim-locate.sh [command] [args]"
        echo ""
    echo "Commands:"
    echo "  (none)          Show current config and paths"
    echo "  configs         List all available configs"
    echo "  plugins [name]  List plugins for config"
    echo "  file <pattern>  Find config files matching pattern"
    echo "  lsp [config]    Show LSP server locations"
    echo "  logs [config]   Show log file locations"
    ;;
    *)
        show_current
        ;;
esac
