#!/bin/bash

# ==============================================================================
# SAS Viya CLI Plug-ins Deployment Script
# Copyright (c) 2026 Nicolas Housset
#
# This software is distributed under the MIT License (Open Source).
# It is provided "as is", without warranty of any kind. You are free 
# to use, copy, modify, and redistribute it provided that you include 
# this copyright notice.
# ==============================================================================

# 1. Validate inputs
ARCHIVE_PATH="$1"

if [ -z "$ARCHIVE_PATH" ]; then
    echo "❌ Error: Missing archive path."
    echo "Usage: ./deploy_viya_plugin_from_tar.sh <path_to_tar_gz>"
    exit 1
fi

if [ ! -f "$ARCHIVE_PATH" ]; then
    echo "❌ Error: File '$ARCHIVE_PATH' not found."
    exit 1
fi

echo "=== Starting Viya plugins deployment ==="

# 2. Define directories
SAS_DIR="$HOME/.sas"
PLUGIN_DIR="$SAS_DIR/viya-plugins"
CONFIG_FILE="$PLUGIN_DIR/config.json"

# Ensure the base .sas directory exists
mkdir -p "$SAS_DIR"

# 3. Extract the archive
echo "[1/3] Extracting archive to $SAS_DIR..."
# This extracts the archive. We assume the tarball contains the 'viya-plugins' directory.
tar -xzf "$ARCHIVE_PATH" -C "$SAS_DIR"

if [ $? -ne 0 ]; then
    echo "❌ Error during extraction. Please check if the archive is valid."
    exit 1
fi

# 4. Update the location paths in config.json
echo "[2/3] Updating absolute paths in config.json..."
if [ -f "$CONFIG_FILE" ]; then
    # This sed command searches for the old home path before "/.sas/viya-plugins/"
    # and safely replaces it with the current user's actual $HOME.
    sed -i 's|"location": ".*/\.sas/viya-plugins/|"location": "'"$HOME"'/.sas/viya-plugins/|g' "$CONFIG_FILE"
else
    echo "⚠️ Warning: config.json not found in $PLUGIN_DIR. Paths were not updated."
fi

# 5. Display the list of plugins and their versions
echo "[3/3] Deployed plugins summary:"
echo "-------------------------------------------------------"
if [ -f "$CONFIG_FILE" ]; then
    # Using awk to parse the JSON securely and extract plugin names and versions
    awk -F'"' '
        /^[ \t]*"[^"]+": \{/ { plugin=$2 } 
        /"version":/ { print "📦 " plugin " (v" $4 ")" }
    ' "$CONFIG_FILE"
else
    echo "No config.json available to display."
fi
echo "-------------------------------------------------------"
echo "✅ Deployment complete!"
