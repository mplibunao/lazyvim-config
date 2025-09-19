# terminal

## Status

- <https://lazyvim-ambitious-devs.phillips.codes/course/chapter-6/#_changing_text>

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
- Tip: press `/` in the picker to focus the list, then use normal Vim motions/y to yank paths
- **alt + s** = seek inside file picker instead of pressing up/down or typing more
- **tab instead of select** - opening multi-file
- **ctrl + d** and **ctrl + u** = scroll results
  - down / up
- **ctrl b** and **ctrl f** =
  - back and forward

## AI

- Group: `<space>a`
- **space + a + w** = Wizy Prompts picker (at `/Users/mp/Projects/wizy/wizy-prompts`)
- **space + a + W** = Grep in Wizy Prompts (picker)

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

## Dashboard

- shift + S = select from session

## Going beyond `<count><motion>`

- The `<count><motion>` commands are great for navigation, which is all we’ve used them for so far, but they can also be combined with a _verb_ to do something to the text between the cursor and the location the motion would move you to.
- Verbs come first, so the structure is always `<verb><count><motion>`
- can theoretically do `<count><verb><count><motion>`

## Operating to end of line

- `D`
  - instead of `d$`
- `C`
  - instead of `c$`
  - **can be more efficient if you need to go to insert mode**
- `cc`
  - **can be better than `dd`**
- `X`
  - **opposite of `x` for deleting**
  - apparently it's op
- `J`
  - deleting newlines at the end of the current line
  - **Join lines**
  - Use with count
  - Preferred
- `gJ` - same as `J` but doesn't modify whitespace
- `~` - toggles case

## Recording

- `qq` to start
- `q` to stop recording
- `qQ` to record in append mode
- `Q` to playback recording

## More motions

- `(` and `)` to move by sentences
- `{` and `}` for paragraphs

## Unimpared mode

- lazyvim
- press `[` or `]` to see options
- move to prev or next something, except the something depends what key you type after the square bracket
- <https://lazyvim-ambitious-devs.phillips.codes/course/chapter-7/#_unimpaired_mode>
  - refer back. didn't get it

## Comments

- `gc` comment
- `gcc`
