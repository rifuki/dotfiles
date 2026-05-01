#!/bin/sh
# Force bash only on real TTY login, skip if already bash

if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ -z "$SSH_CONNECTION" ] && [ -t 0 ]; then
    if [ -z "$BASH_VERSION" ]; then
        exec /bin/bash --login
    fi

    if [ -f /etc/bash/bashrc ] ; then
      . /etc/bash/bashrc
    else
      PS1='\u@\h \w \$ '
    fi
fi
