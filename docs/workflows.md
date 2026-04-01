# Workflows

## Targeting this config

This config uses `NVIM_APPNAME=nvim-lazy`. Always set this when launching Neovim programmatically so you hit this config instead of the default.

## Verifying changes with tmux

tmux is the only reliable way for agents to test Neovim behavior. Launch a detached session, run the check, capture the output:

```bash
# Headless Lua check
tmux new-session -d -s nvim-check -x 120 -y 40 \
  "NVIM_APPNAME=nvim-lazy nvim --headless \
  -c '<lua commands>' 2>&1 | tee /tmp/nvim-check.log"

# Read output
tmux capture-pane -p -t nvim-check

# Clean up
tmux kill-session -t nvim-check
```

Use `vim.defer_fn` with a delay (e.g., 3000ms) to let plugins load before checking values.

## Validation by change type

| Change type | What to check |
|---|---|
| `lua/config/*.lua` or `lua/plugins/*.lua` (existing plugins) | Format with `stylua` + headless startup check |
| New/removed plugins or extras (any file) | `:Lazy sync` + lockfile review + startup check |
| `lazyvim.json` changes | `:Lazy sync` + lockfile review + startup check |
| `docs/*.md` or `CLAUDE.md` only | Verify referenced paths exist and spot-check claims against source files |
| Interactive UI / plugin behavior | tmux-backed visual validation |
