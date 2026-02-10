#!/bin/zsh

layout=$(yabai -m query --spaces --space | jq -r '.type')

if [[ "$layout" == "stack" ]]; then
    if [[ "$1" == "south" ]]; then
        yabai -m window --swap stack.next; yabai -m window --focus stack.next
    elif [[ "$1" == "north" ]]; then
        yabai -m window --swap stack.prev; yabai -m window --focus stack.prev
    fi
else
    yabai -m window --swap "$1"
fi

