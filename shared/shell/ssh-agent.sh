# Start the ssh-agent
if [ -z "$SSH_AUTH_SOCK" ] ; then
    eval "$(ssh-agent -s)"
fi

# Add the SSH key to the ssh-agent, if it's not already added
if ! ssh-add -l > /dev/null ; then
    ssh-add
fi

