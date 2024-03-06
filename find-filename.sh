#!/bin/bash

# Check if the user has provided a filename pattern
if [ $# -eq 0 ]; then
    echo "Usage: $0 <filename_pattern>"
    exit 1
fi

filename_pattern="$1"

# Search for files with the specified filename pattern in the current directory
# and its subdirectories recursively
found_files=$(find . -type f -name "*$filename_pattern*")

# Check if any files were found
if [ -n "$found_files" ]; then
    echo "Found files:"
    echo "$found_files"
else
    echo "No files found with the filename pattern '$filename_pattern' in the current directory."
fi
