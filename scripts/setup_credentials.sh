# Find a default identity for SSH
if [ -z "$SSH_KEY_FILE" ]; then
    for candidate in "id_rsa" "id_dsa" "id_ecdsa" "id_ed25519"; do
        candidate_file="$HOME/.ssh/$candidate"
        if [ -f $candidate_file ]; then
            export SSH_KEY_FILE=$candidate_file
            break
        fi
    done
    if [ -z "$SSH_KEY_FILE" ]; then
        logerr "Could not find any ssh identity to use"
        exit 1
    fi
fi

# Retrieve scw api credentials
if ! [ -f $HOME/.scwrc ]; then
    logerr "Please log into Scaleway first : scw login"
    exit 1
fi
read SCW_ORGANIZATION SCW_TOKEN < <(jq -r '"\(.organization) \(.token)"' $HOME/.scwrc)
if [ -z "$SCW_ORGANIZATION" ] || [ -z "$SCW_TOKEN" ]; then
    logerr "Could not get authentication information from $HOME/.scwrc"
    exit 1
fi
