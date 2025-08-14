if status is-interactive
    # Commands to run in interactive sessions can go here
end

function connect_adb_wifi
    set -l ip (~/.local/bin/get_dns.sh)
    if test -n "$ip"
        adb connect "$ip"
    else
        echo "Failed to get IP address."
    end
end
set -g PATH $PATH /usr/games

function sigma_boy
    echo "Sigma boy"
end

function disable-touchpad
    xinput disable (xinput list | grep -i 'touchpad' | grep -o 'id=[0-9]*' | cut -d= -f2)
end

set -gx ADW_DISABLE_PORTAL 1
set -gx PATH /opt/android-sdk/platform-tools $PATH
set -gx PATH $PATH $HOME/.maestro/bin
set -gx PATH $HOME/.nvm/versions/node/v22.16.0/bin $PATH
