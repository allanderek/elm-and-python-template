#!/bin/bash

# Setup script to install Git hooks for this project

echo "Setting up Git hooks..."

# Create .git/hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy the pre-commit hook
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

echo "✓ Pre-commit hook installed"
echo ""
echo "This hook will prevent accidentally committing .env files."
echo "To bypass the hook when needed, use: git commit --no-verify"