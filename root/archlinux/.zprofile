# Autostart X on login
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    exec startx /usr/bin/i3
fi

