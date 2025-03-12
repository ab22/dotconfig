# Set theme for GTK apps (Thunar, etc)
export GTK_THEME=Adwaita:dark

# Autostart i3 on login
# if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
#    exec startx /usr/bin/i3
# fi

# Autostart Plasma on Login
# /usr/lib/plasma-dbus-run-session-if-needed /usr/bin/startplasma-wayland

# Autostart Sway on login
if [ -z "$WAYLAND_DISPLAY" ] && [ -n "$XDG_VTNR" ] && [ "$XDG_VTNR" -eq 1 ] ; then
    exec sway --unsupported-gpu
fi
