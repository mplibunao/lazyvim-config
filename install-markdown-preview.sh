#!/bin/bash

# Install script for markdown-preview with custom CSS

echo "Setting up Markdown Preview with Sticky TOC..."

# Check if nvim is installed
if ! command -v nvim &> /dev/null; then
    echo "Neovim is not installed. Please install Neovim first."
    exit 1
fi

# Ensure the assets directory exists
mkdir -p ~/.config/nvim-lazy/assets

# Make sure the CSS file exists
if [ -f ~/.config/nvim-lazy/assets/markdown-preview.css ]; then
    echo "✓ Custom CSS file found"
else
    echo "✗ CSS file not found at ~/.config/nvim-lazy/assets/markdown-preview.css"
    exit 1
fi

# Make sure the plugin config exists
if [ -f ~/.config/nvim-lazy/lua/plugins/markdown-preview.lua ]; then
    echo "✓ Plugin configuration found"
else
    echo "✗ Plugin configuration not found"
    exit 1
fi

echo ""
echo "Installation complete! To use the new markdown preview:"
echo "1. Open Neovim"
echo "2. Run :Lazy sync to ensure the plugin is installed"
echo "3. Open a markdown file"
echo "4. Run :MarkdownPreview to see the new sticky TOC layout"
echo ""
echo "Features:"
echo "• Sticky table of contents on the left side"
echo "• Active section highlighting in TOC"
echo "• Responsive design (TOC hides on mobile)"
echo "• Dark theme optimized for readability"
echo ""
echo "Note: If the CSS doesn't apply immediately, try:"
echo "• Restart Neovim"
echo "• Clear browser cache"
echo "• Run :MarkdownPreviewStop and :MarkdownPreview again"