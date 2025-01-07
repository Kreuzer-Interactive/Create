#!/bin/bash

# Check if dos2unix is installed
if ! command -v dos2unix &> /dev/null; then
    echo "dos2unix is not installed. Installing via Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed. Please install Homebrew first."
        exit 1
    fi
    brew install dos2unix
fi

# Usage function
usage() {
    echo "Usage: $0 <directory>"
    echo "Example: $0 ./assets"
    exit 1
}

# Check arguments
if [ $# -ne 1 ]; then
    usage
fi

directory="$1"

# Check if directory exists
if [ ! -d "$directory" ]; then
    echo "Error: Directory does not exist!"
    exit 1
fi

echo "Starting recursive search and conversion..."

# Initialize counter
total_files=0

# First show all directories being searched
echo "Searching in these directories:"
find "$directory" -type d

# Process each extension type
for ext in "pal" "dat" "DVT" "INI"; do
    echo -e "\nLooking for *.$ext files..."
    # Explicitly recursive find with debugging
    find "$directory" -follow -type f -iname "*.$ext" -print | while read -r file; do
        if [ ! -z "$file" ]; then
            echo "Converting: $file"
            unix2dos -v "$file"
            ((total_files++))
        fi
    done
done

echo -e "\nConversion complete!"
echo "Total files processed: $total_files" 
