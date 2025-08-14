function sshhome
    ssh -i ~/.ssh/id_ed25519_personal $argv[1]@$argv[2]
end
