#!/usr/bin/env bash
# nvim-headless.sh - Headless Neovim validation for agents
#
# Provides non-interactive validation of Neovim configurations.
# Designed for agent use where interactive tmux/GUI is not available.
#
# Usage:
#   nvim-headless.sh check [config]       # Basic syntax check
#   nvim-headless.sh plugins [config]     # Verify plugins load
#   nvim-headless.sh health [config]      # Run checkhealth
#   nvim-headless.sh startup [config]     # Profile startup time
#   nvim-headless.sh lsp [config]         # Check LSP status
#   nvim-headless.sh cmd <ex-command>     # Run an ex command
#   nvim-headless.sh lua <lua-code>       # Run lua code

set -euo pipefail

# Colors (disabled if not a terminal or NO_COLOR is set)
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

# Get NVIM_APPNAME for a config
get_appname() {
    local config="${1:-}"
    if [[ -n "$config" && "$config" != "default" && "$config" != "nvim" ]]; then
        # Ensure it has nvim- prefix
        if [[ "$config" == nvim-* ]]; then
            echo "$config"
        else
            echo "nvim-$config"
        fi
    else
        echo ""
    fi
}

# Run nvim with optional NVIM_APPNAME
run_nvim() {
    local config="${1:-}"
    shift

    local appname
    appname=$(get_appname "$config")

    if [[ -n "$appname" ]]; then
        NVIM_APPNAME="$appname" nvim "$@"
    else
        nvim "$@"
    fi
}

# Basic syntax/load check
check_config() {
    local config="${1:-}"

    echo -e "${YELLOW}Checking Neovim configuration...${NC}"

    local appname
    appname=$(get_appname "$config")
    local config_dir="$HOME/.config/${appname:-nvim}"

    echo "Config: ${appname:-nvim}"
    echo "Directory: $config_dir"
    echo ""

    # Check if config directory exists
    if [[ ! -d "$config_dir" ]]; then
        echo -e "${RED}ERROR: Config directory not found${NC}"
        exit 1
    fi

    # Check init.lua exists
    if [[ ! -f "$config_dir/init.lua" ]]; then
        echo -e "${RED}ERROR: init.lua not found${NC}"
        exit 1
    fi

    # Try to load config
    local output
    if output=$(run_nvim "$config" --headless -c 'lua print("CONFIG_OK")' -c 'qa' 2>&1); then
        if echo "$output" | grep -q "CONFIG_OK"; then
            echo -e "${GREEN}✓ Configuration loads successfully${NC}"
        else
            echo -e "${YELLOW}⚠ Configuration loaded but output unexpected${NC}"
            echo "$output"
        fi
    else
        echo -e "${RED}✗ Configuration failed to load${NC}"
        echo "$output"
        exit 1
    fi
}

# Verify plugins load
check_plugins() {
    local config="${1:-}"

    echo -e "${YELLOW}Checking plugins...${NC}"

    local output
    output=$(run_nvim "$config" --headless -c 'lua local s=require("lazy").stats(); print("PLUGINS:" .. s.count)' -c 'qa' 2>&1) || true

    if echo "$output" | grep -q "PLUGINS:"; then
        local count
        count=$(echo "$output" | grep -o 'PLUGINS:[0-9]*' | cut -d: -f2)
        echo -e "${GREEN}✓ Lazy.nvim loaded with $count plugins${NC}"
    else
        echo -e "${RED}✗ Failed to load lazy.nvim${NC}"
        echo "$output"
        exit 1
    fi

    # Check for plugin errors in lazy
    local errors
    errors=$(run_nvim "$config" --headless -c 'lua local s=require("lazy").stats(); print("LOADED:" .. s.loaded .. "/" .. s.count)' -c 'qa' 2>&1) || true

    if echo "$errors" | grep -q "LOADED:"; then
        local stats
        stats=$(echo "$errors" | grep -o 'LOADED:[0-9]*/[0-9]*' | cut -d: -f2)
        echo "Plugin load stats: $stats loaded/total"
    fi
}

# Run checkhealth
check_health() {
    local config="${1:-}"
    local filter="${2:-}"

    echo -e "${YELLOW}Running checkhealth...${NC}"
    echo ""

    local cmd="checkhealth"
    if [[ -n "$filter" ]]; then
        cmd="checkhealth $filter"
    fi

    # Capture health output - this is verbose
    run_nvim "$config" --headless -c "$cmd" -c 'qa' 2>&1 | head -200
}

# Profile startup time
check_startup() {
    local config="${1:-}"
    local tmpfile="/tmp/nvim-startup-$$.log"

    echo -e "${YELLOW}Profiling startup time...${NC}"
    echo ""

    run_nvim "$config" --startuptime "$tmpfile" --headless -c 'qa' 2>&1 || true

    if [[ -f "$tmpfile" ]]; then
        # Show total time
        local total
        total=$(tail -1 "$tmpfile" | awk '{print $1}')
        echo -e "Total startup time: ${GREEN}${total}ms${NC}"
        echo ""

        # Show slowest items
        echo "Slowest items:"
        sort -k2 -n "$tmpfile" | tail -15 | while read -r line; do
            echo "  $line"
        done

        rm -f "$tmpfile"
    else
        echo -e "${RED}Failed to generate startup profile${NC}"
    fi
}

# Check LSP status
check_lsp() {
    local config="${1:-}"

    echo -e "${YELLOW}Checking LSP configuration...${NC}"
    echo ""

    local appname
    appname=$(get_appname "$config")
    local data_dir="$HOME/.local/share/${appname:-nvim}"

    # List configured servers via Mason
    local mason_dir="$data_dir/mason/bin"
    if [[ -d "$mason_dir" ]]; then
        echo "Installed LSP servers (Mason):"
        # shellcheck disable=SC2012 # mason bin entries are alphanumeric server names
        ls -1 "$mason_dir" 2>/dev/null | head -20 | while read -r server; do
            echo "  $server"
        done
    else
        echo "Mason bin directory not found"
    fi

    echo ""

    # Try to get LSP config info
    local output
    output=$(run_nvim "$config" --headless -c 'lua vim.print(vim.lsp.get_clients())' -c 'qa' 2>&1) || true

    if [[ -n "$output" ]]; then
        echo "LSP clients (empty on headless - no file loaded):"
        echo "$output" | head -20
    fi
}

# Run an ex command
run_command() {
    shift  # Remove 'cmd' from args
    local cmd="$*"

    if [[ -z "$cmd" ]]; then
        echo "Usage: nvim-headless.sh cmd <ex-command>"
        exit 1
    fi

    nvim --headless -c "$cmd" -c 'qa' 2>&1
}

# Run lua code
run_lua() {
    shift  # Remove 'lua' from args
    local code="$*"

    if [[ -z "$code" ]]; then
        echo "Usage: nvim-headless.sh lua <lua-code>"
        exit 1
    fi

    nvim --headless -c "lua $code" -c 'qa' 2>&1
}

# Show help
show_help() {
    echo "nvim-headless.sh - Headless Neovim validation"
    echo ""
    echo "Usage: nvim-headless.sh <command> [config] [args]"
    echo ""
    echo "Commands:"
    echo "  check [config]        Basic syntax/load check"
    echo "  plugins [config]      Verify plugins load"
    echo "  health [config]       Run checkhealth (verbose)"
    echo "  startup [config]      Profile startup time"
    echo "  lsp [config]          Check LSP configuration"
    echo "  cmd <ex-command>      Run an ex command"
    echo "  lua <lua-code>        Run lua code"
    echo ""
    echo "Config can be:"
    echo "  (empty)      Use current NVIM_APPNAME or default"
    echo "  lazy         Use nvim-lazy config"
    echo "  nvim-lazy    Same as above"
    echo "  default      Use default nvim config"
    echo ""
    echo "Examples:"
    echo "  nvim-headless.sh check lazy"
    echo "  nvim-headless.sh plugins nvim-lazy"
    echo "  nvim-headless.sh startup"
    echo "  nvim-headless.sh lua 'print(vim.fn.stdpath(\"config\"))'"
}

# Main
case "${1:-}" in
    check)
        check_config "${2:-}"
        ;;
    plugins|plugin)
        check_plugins "${2:-}"
        ;;
    health)
        check_health "${2:-}" "${3:-}"
        ;;
    startup|profile)
        check_startup "${2:-}"
        ;;
    lsp)
        check_lsp "${2:-}"
        ;;
    cmd|command)
        run_command "$@"
        ;;
    lua)
        run_lua "$@"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        if [[ -n "${1:-}" ]]; then
            echo "Unknown command: $1"
            echo ""
        fi
        show_help
        exit 1
        ;;
esac
