#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export ANI_CLI_DOWNLOAD_DIR=/home/rundowntrex/Desktop/STUFF/Videos/

export XDG_CURRENT_DESKTOP=Hyprland
export QT_QPA_PLATFORM=wayland
export XDG_SESSION_TYPE=wayland
export PATH=/opt/android-sdk/platform-tools:$PATH
export ANDROID_HOME=/home/rundowntrex/Android/Sdk


connect_adb_wifi() {
    ip=$(~/.local/bin/get_dns.sh)
    if [[ -n "$ip" ]]; then  # Check if ip is not empty
        adb connect "$ip"
    else
        echo "Failed to get IP address."
    fi
}


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
alias disable-touchpad='xinput disable "$(xinput list | grep -i '\''touchpad'\'' | grep -o '\''id=[0-9]*'\'' | cut -d= -f2)"'
source "/home/rundowntrex/.rover/env"
export PATH=$PATH:$HOME/.maestro/bin
