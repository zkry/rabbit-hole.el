# rabbit-hole.el

A micro task-manager for managing nested stacks of tasks.

# Demo

<img src="https://github.com/zkry/rabbit-hole.el/raw/master/docs/rabbit-hole.gif" width="400" />

# Installation

This package is not on MELPA so it must be installed manually (ie by
adding rabbit-hole.el to your load path).

# Configuration

You will need to configure the following settings:

- `rabbit-hole-file` should be an org-mode file that contains where
  you want to store your task tree.
- `rabbit-hole-header` should be the text of the headline under which
  you want to save your task tree.

# Usage

The package has the following interactive commands:

- `rabbit-hole` view the rabbit-hole buffer
- `rabbit-hole-go-deeper` adds a nested task item
- `rabbit-hole-pop` removes the item at the top of the stack
- `rabbit-hole-continue` continues the topmost stream of tasks

## Inside the rabbit-hole buffer

- <kbd>&gt;</kbd> `rabbit-hole-go-deeper`
- <kbd>&lt;</kbd> `rabbit-hole-pop`
- <kbd>.</kbd> `rabbit-hole-continue`
- <kbd>q</kbd> `quit`
