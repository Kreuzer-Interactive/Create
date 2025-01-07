#!/bin/bash

# Usage function
usage() {
    echo "Usage: $0 <source_dir> <dest_dir>"
    echo "Example: $0 . /Code/dosbox/HD/SPACE2/V5/CREATE"
    exit 1
}

# Check arguments
if [ $# -ne 2 ]; then
    usage
fi

source_dir="$1"
dest_dir="$2"

# Check if destination directory exists, create if not
if [ ! -d "$dest_dir" ]; then
    echo "Error: Destination directory does not exist!"
    echo "Creating: $dest_dir"
    mkdir -p "$dest_dir" || {
        echo "Failed to create directory!"
        exit 1
    }
fi

# Check if source files exist
for file in "CREATE5.BAS" "CFG.INI"; do
    if [ ! -f "$source_dir/$file" ]; then
        echo "Error: $file not found in $source_dir!"
        exit 1
    fi
done

# Clean up old files
rm -f "$dest_dir/CREATE5.BAS"
rm -f "$dest_dir/CFG.INI"
rm -f "$dest_dir/CREATE5.MAK"
rm -f "$dest_dir/DEV.BAT"

# Create directories if they don't exist
mkdir -p "$dest_dir/assets"
mkdir -p "$dest_dir/modules"

# Copy main files
for file in "CREATE5.BAS" "CFG.INI" "CREATE5.MAK" "DEV.BAT"; do
    cp "$source_dir/$file" "$dest_dir/" || {
        echo "Error copying $file!"
        exit 1
    }
done

# Copy all assets and subdirectories
cp -R "$source_dir/assets/"* "$dest_dir/assets/" 2>/dev/null || {
    echo "Error copying assets!"
    exit 1
}

# Copy all modules
cp -R "$source_dir/modules/"* "$dest_dir/modules/" 2>/dev/null || {
    echo "Error copying modules!"
    exit 1
}

echo "Files copied successfully!"
