# Implemented Commands

This document describes the features of vim emulated by VimBindings.jl.

The following symbols indicate the status of a feature:

- ✅ Implemented

- ❌ Not implemented

- 🚧 Planned or In Progress

## Motions
Commands for moving the cursor.

A motion command may be prepended with a `count` to repeat the motion, for example the motion `3w` moves 3 words to the right. 

| Command | Description | Implemented |
|--|--|--|
| h | left | ✅  |
| l | right | ✅  |
| j | down | ✅  |
| k | up | ✅  |
| w | next word | ✅  |
| W | next WORD | ✅  |
| e | end of word | ✅  |
| E | end of WORD | ✅  |
| b | previous word | ✅  |
| B | previous WORD | ✅  |
| ^ | beginning of line (excluding whitespace) | ✅  |
| 0 | first character of line (including whitespace) | ✅  |
| $ | end of line | ✅  |
| f{x} | the next occurence of {x} | ✅  |
| F{x} | the Previous occurence of {x} | ✅  |
| t{x} | till before the next occurence of {x} | ✅  |
| T{x} | till after the previous occurence of {x} | ✅ | 
| % | find the next item in the line and jump to its match. Items can be ([{}]) | ❌ |

## Operators
A motion can be used in after an operator to have the command operate on the text in the motion.

| Command | Description | Implemented |
|--|--|--|
| c | change | ✅ |
| d | delete | ✅  |
| y | yank | 🚧 (see [issue](https://github.com/caleb-allen/VimBindings.jl/issues/3))

An operator may be prepended with a `count` to repeat the operation. For example, `3dW` will execute the `dW` operation 3 times.

## Text Objects
Text object commands can only be used after an operator. Commands that start with `a` select "a"n object including white space, the commands starting with `i` select an "inner" object without white space, or just the white space. Thus the "inner" commands always select less text than the "a" commands.

Definitions of text objects:
- word: a word consists of a sequence of letters, digits and underscores, or a sequence of other non-blank characters, separated with whitespace (spaces, tabs, newline). For example, the words in the text `function hello()` are `function`, `hello`, and `()`.
- WORD: a WORD consists of a sequence of non-blank characters, separated with whitespace. For example, the WORDs in the text `function hello()` are `function` and `hello()`.

| Command | Description | Implemented |
|--|--|--|
| aw | a word | ✅ |
| iw | inner word | ✅ |
| aW | a WORD | ✅ |
| iW | inner WORD | ✅ |
| a]/a[ | a [] block | 🚧 (see [issue](https://github.com/caleb-allen/VimBindings.jl/issues/62)) |
| i]/i[ | inner [] block | 🚧 |
| a)/a(/ab | a block | 🚧 |
| i)/i(/ib | inner block | 🚧 |
| a>/a< | a <> block | 🚧 |
| i>/i< | inner <> block | 🚧 |
| a}/a{/aB | a Block | 🚧 |
| i}/i{/iB | inner Block | 🚧 |
| a"/a'/a` | a quoted string | 🚧 |
| i"/i'/i` | inner quoted string | 🚧 |
| as/is | a sentence, inner sentence | ❌ |
| ap/ip | a paragraph, inner paragraph | ❌ |
| at/at | a tag block, inner tag block | ❌ |

## Inserting Text

Insert commands can be used to insert new text.

| Command | Description | Implemented |
|--|--|--|
| i | insert text before the cursor | ✅ |
| I | insert text before the first non-blank in the line | ✅ |
| a | append text after the cursor | ✅ |
| A | append text at the end of the line | ✅ |
| o | begin a new line below the cursor and insert text | ✅ |
| O | begin a new line above the cursor and insert text | ✅ |
| gI | insert text in column 1 | ❌ |
| gi | insert text where Insert mode was stopped last time | ❌ |


## Deleting and Changing text

| Command | Description | Implemented |
|--|--|--|
| x | delete `count` characters under and after the cursor. Equivalent to `dl` | ✅ |
| X | delete `count` character before the cursor. Equivalent to `dh` | ✅ |
| D | delete from the cursor until the end of the line. Equivalent to `d$` | ✅ |
| dd | delete line | ✅ |
| C | delete from the cursor position to the end of the line and start insert. Equivalent to `c$`. | ✅ |
| cc | delete line and start insert | ✅ |
| s | delete the character under the cursor and start insert | ✅ |
| S | delete `count` lines and start insert. Equivalent to `cc`. | ✅ |
| r | replace the character under the cursor | ✅ |
| R | enter replace mode | ❌ |
| J | join lines | ❌ |

## Undo and Redo

VimBindings.jl implements the core semantics of undo and redo as implemented by vim, with the exception that VimBindings.jl does not implement an undo tree or undo branches. Undo/redo is implemented as a list.

The undo and redo implementation is not vi compatible; "uu" will undo two times, like in vim, rather than "undoing" an undo as in vi.

| Command | Description | Implemented |
|--|--|--|
| u | undo `count` changes | ✅  |
| C-r | redo `count` changes | ✅ |
| U | undo the latest changes on oneline | ❌ |


## Miscellaneous

| Command | Description | Implemented |
|--|--|--|
| v | start visual mode | ❌ |
| / | search forward | ❌ |
| ? | search backward | ❌ |
| n | repeat the latest "/" or "?" | ❌ |
| N | repeat the latest "/" or "?" in the opposite direction | ❌ |
| * | search forward for the word nearest to the cursor | ❌ |
| \# | same as "*" but search backward | ❌ |
| G | goto line `count`, default last line | ❌ |
| gg | go to line `count`, default first line | ❌ |
| [( | go to previous unmatched '(' | ❌ |
| [{ | go to previous unmatched '{' | ❌ |
| ]) | go to next unmatched ')' | ❌ |
| ]} | go to next unmatched '}' | ❌ |
| ]m | go to next start of a method | ❌ |
| ]M | go to next end of a method | ❌ |
| [m | go to previous start of a method | ❌ |
| [M | go to previous end of a method | ❌ |


## Reference
Many of these descriptions are adapted from the vim documentation of the respective commands.

