// Custom JavaScript for Markdown Preview
// Adds copy functionality to code blocks

(function() {
  'use strict';

  // Function to add copy buttons to all code blocks
  function addCopyButtons() {
    const codeBlocks = document.querySelectorAll('pre');

    codeBlocks.forEach((block) => {
      // Skip if button already exists
      if (block.querySelector('.copy-button')) return;

      // Create copy button
      const button = document.createElement('button');
      button.className = 'copy-button';
      button.textContent = 'Copy';

      // Get the language from class name or data attribute
      const codeElement = block.querySelector('code');
      if (codeElement) {
        const className = codeElement.className;
        const langMatch = className.match(/language-(\w+)/);
        if (langMatch) {
          block.setAttribute('data-language', langMatch[1]);
        }
      }

      // Add click handler
      button.addEventListener('click', async () => {
        const code = block.querySelector('code');
        if (!code) return;

        try {
          // Copy to clipboard
          await navigator.clipboard.writeText(code.textContent);

          // Show success state
          button.classList.add('copied');
          button.textContent = 'Copied!';

          // Reset after 2 seconds
          setTimeout(() => {
            button.classList.remove('copied');
            button.textContent = 'Copy';
          }, 2000);
        } catch (err) {
          console.error('Failed to copy:', err);
          button.textContent = 'Error';
          setTimeout(() => {
            button.textContent = 'Copy';
          }, 2000);
        }
      });

      // Add button to code block
      block.appendChild(button);
    });
  }

  // Run when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', addCopyButtons);
  } else {
    addCopyButtons();
  }

  // Also run when content updates (for dynamic content)
  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      if (mutation.addedNodes.length) {
        addCopyButtons();
      }
    });
  });

  // Start observing the document body for changes
  observer.observe(document.body, {
    childList: true,
    subtree: true
  });

  // Add keyboard shortcut (Ctrl/Cmd + Shift + C) to copy focused code block
  document.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.shiftKey && e.key === 'C') {
      const focusedPre = document.querySelector('pre:hover');
      if (focusedPre) {
        const button = focusedPre.querySelector('.copy-button');
        if (button) {
          button.click();
          e.preventDefault();
        }
      }
    }
  });
})();