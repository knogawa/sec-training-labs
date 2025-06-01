#!/bin/bash

URL='https://github.com/knogawa/sec-training-labs/raw/refs/heads/main/iret-script.zip'
HOME_DIR=$HOME
TEMP_FILE="temp.zip"
TARGET_DIR="$HOME_DIR/script.d"

# Download the file
echo "LAB> Downloading lab files..."
curl -sLo "$TEMP_FILE" "$URL" || {
    echo "Error: Failed to download file"
    exit 1
}

# Unzip to home directory
echo "LAB> Unzipping file to $HOME_DIR..."
unzip -qo "$TEMP_FILE" -d "$HOME_DIR" || {
    echo "Error: Failed to unzip file"
    rm -f "$TEMP_FILE"
    exit 1
}

# Remove temporary zip file
rm -f "$TEMP_FILE"

# Check if script.d directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: script.d directory not found in $HOME_DIR"
    exit 1
fi

# Add execute permission to all .sh files in script.d
echo "LAB> Setting execute permissions for .sh files..."
find "$TARGET_DIR" -type f -name "*.sh" -exec chmod u+x {} \+ || {
    echo "Error: Failed to set permissions"
    exit 1
}

# Install required package
echo "LAB> Installing reuqired packages..."
sudo yum install tree -y

echo "LAB> Script completed successfully!"