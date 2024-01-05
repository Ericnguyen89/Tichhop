#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

# Public key to be added to authorized_keys
PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCbUYCHqCtPrY6vu/oL/DlySppSOF7TjxXUXLECZnlrktIJqYCin7mD4z6GFTvqiAvrQSUYJhbASJA3qiVzXrXV5eoGpujhpAdKv6TnFcncEP7dQBf9Ocq6Zpk34fCGBbM4qcJY6nALlEBF8G4KL134iraqHxv34qlUmN8fUKoL0f2s7j86QHwHo/RP/rA9dR2sb9o49zquz5REXIMB5181/Y5Bqty0D49l4Yzq02/aWSA4jfiI0AO6OH7TS1ATdGKtikBB0cfpgHuKkGwTaaq/nz4rTBsQXyWbrEF8K9b/huozaJUzPE/YJISxBBf/m3GPtlN//nzE77WPgaZ9IyfGJ3qVBs4iGBE2Us9WzPuXxWFliRtFHOhfTB33BnoAkw1lCpGwLQD9NTs8BirB0DNkTE/EUDSOWhteKiDyruIV0+6n09Yw6Urz7484YBYnqHxNQe4S+ZmttltHAnpECbzsuRnWszJSuggTF676pFbjCtj9uES0yIXnKe00zEEEUa0= tuannm@BLU-TDESK-07"

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
apt-get install -y curl gcc-mingw-w64 g++-mingw-w64-i686 g++-mingw-w64-x86-64 nsis make cmake



git clone https://github.com/wazuh/wazuh.git
cd /wazuh/src/
echo "\n ----------------------------------\n SYSTEM READY to START."
