#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export ANI_CLI_DOWNLOAD_DIR=/home/rundowntrex/Desktop/STUFF/Videos/

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

connect_adb_wifi() {
    ip=$(~/.local/bin/get_dns.sh)
    if [[ -n "$ip" ]]; then  # Check if ip is not empty
        adb connect "$ip"
    else
        echo "Failed to get IP address."
    fi
}


sshhome() {
  ssh -i ~/.ssh/id_ed25519_personal "$1@$2"
}

export ADW_DISABLE_PORTAL=1
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
