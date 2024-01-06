#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

# Public key to be added to authorized_keys
PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2E"

# Root user's home directory
ROOT_HOME="/root"

# Create .ssh directory if it doesn't exist
mkdir -p "$ROOT_HOME/.ssh"

# Add the public key to the authorized_keys file
echo "$PUBLIC_KEY" >> "$ROOT_HOME/.ssh/authorized_keys"

# Allow additional users to login via SSH using the root account
# Replace "user1" and "user2" with the desired usernames
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Restart SSH service to apply changes
service ssh restart
apt-get install -y curl gcc-mingw-w64 g++-mingw-w64-i686 g++-mingw-w64-x86-64 nsis make cmake gcc g++ make libc6-dev curl policycoreutils automake autoconf libtool



git clone https://github.com/wazuh/wazuh.git
cd wazuh/src/
echo "\n ----------------------------------\n SYSTEM READY to START."
make deps
