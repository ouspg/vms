#!/bin/bash

# Find and set permissions for .hcl, .py, and .sh files. Makes ALL FILES under its current working directory executable. If this needs to be used please remove scripts permissions afterwards.
find . -type f \( -name "*.hcl" -o -name "*.py" -o -name "*.sh" -o -name "*.json" \) -exec chmod 755 {} +

echo "Permissions updated to 755 for .hcl, .py, .sh and .json files."
