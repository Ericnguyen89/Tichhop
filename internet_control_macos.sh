#!/bin/bash

block_internet() {
    echo "Blocking internet access..."
    sudo pfctl -E # Enable pf firewall
    sudo pfctl -f /etc/pf.conf -e # Load rules from pf.conf file
    echo "block out all" | sudo pfctl -f - # Block all outbound traffic
    echo "pass out proto tcp to any port 55000" | sudo pfctl -f - # Whitelist Wazuh API port
    echo "Internet access blocked."
}

unblock_internet() {
    echo "Unblocking internet access..."
    sudo pfctl -d # Disable pf firewall
    echo "Internet access unblocked."
}

main() {
    read -p "Enter 'block' to block internet access or 'unblock' to unblock internet access: " choice
    case $choice in
        block)
            block_internet
            ;;
        unblock)
            unblock_internet
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac
}

main
