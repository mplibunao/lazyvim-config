# terminal

## Zoxide

- **`zi`** pipes to fzf.
  - good if you know there are multiple files with partial names
  - includes scores
- zoxide remove /path/you/want/to/remove

# Go-to

gi - Go to last place you entered insert mode, and enter insert mode again

# Register

ctrl + r = registry in insert mode
paste from registry = shift + =
" = registry in normal mode

# Autocomplete

ctrl + y = accept auto-complete

# Sneak

s - for sneak/flash
f/F - on the char
t/T - before the char

# Scrolling

- Nice for getting into view of flash
- **ctrl + d and ctrl + u** = scroll window by a half a screen's worth of text
  - down and up
- **ctrl + f and ctrl + b** = scroll by full page of text
  - forward or backward
- Can prefix with count (5<Control-f>)
- **ctrl + y and ctrl + e** = scroll window by single line
  - 5<ctrl+y>

## Z mode

- zz
- zt = top
- zb = bottom

# Line targets  

- I/A instead of $, ^, 0
- `g_` = go to last non-black character

# Jump history

- **Ctrl + o** = Go to place I jumped from
- **ctrl + i** = jump forward in history

# Opening files

- `:e` is short for edit
- `:cd path` to change directory

## Picker

- snacks
- **space + space** = picker
- **space + f + f** = picker
- **space + f + F** = find files (cwd)
- **alt + s** = seek inside file picker instead of pressing up/down or typing more
- **tab instead of select** - opening multi-file
- **ctrl + d** and **ctrl + u** = scroll results
  - down / up
- **ctrl b** and **ctrl f** =
  - back and forward

## CWD & Root

### CWD

- **:lcd** to change current window's directory
  - local change directory

## Snacks

- ~space + e = explorer (root)~
- ~space + E = explorer (cwd)~
- most capabilities of picker are here (seek)
- `i` to enter insert mode while explorer is focused to search for a file.
- backspace to go up
- a to create
- r to rename
- d to delete
- y to copy
- p to paste
- m to move

## Mini.files

- ~`<space>fm` - current file~
- `<space>e` - open in current file
- `<space>E` - open in cwd
- `<space>fm` - open in root dir
- ``<space>fM`` - open in cwd
- similar to ranger / vim bindings
- `l` - opens the file in currently active window without closing the file menu
  - for navigating and opening multiple files
- `<space>fm` - root dir
- `=` - **save**
  - make filesystem equal to what I've typed
