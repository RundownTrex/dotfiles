function sshhome
    env TERM=xterm-256color ssh -i ~/.ssh/id_ed25519_personal "$argv[1]@$argv[2]"
end
