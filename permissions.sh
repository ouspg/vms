#!/bin/bash

# Find and set permissions for .hcl, .py, and .sh files
find . -type f \( -name "*.hcl" -o -name "*.py" -o -name "*.sh" \) -exec chmod 755 {} +

echo "Permissions updated to 755 for .hcl, .py, and .sh files."
