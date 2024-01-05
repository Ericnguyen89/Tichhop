#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi


echo "\n ----------------------------------\n SYSTEM READY to START."
