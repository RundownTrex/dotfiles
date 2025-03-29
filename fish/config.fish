if status is-interactive
    # Commands to run in interactive sessions can go here
end

function connect_adb_wifi
    set -l ip (get_dns.sh)
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
