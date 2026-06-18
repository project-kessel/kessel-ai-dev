#!/bin/bash
set -e

echo "kessel-ai-dev" > /home/botuser/app/.instance-id

# Instance-specific packages go here:
# dnf install -y --nodocs <package>
# pip3.12 install <package>
# npm install -g <package>

echo "Instance setup complete: kessel-ai-dev"
