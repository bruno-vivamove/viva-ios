#!/bin/bash

# SwiftLint Build Phase Script
# Add this script as a "Run Script Phase" in Xcode build phases

# Check if SwiftLint is installed
if which swiftlint >/dev/null; then
    echo "SwiftLint found, running linter..."
    swiftlint
else
    echo "Warning: SwiftLint not installed. Install with: brew install swiftlint"
    echo "Skipping linting for now..."
fi