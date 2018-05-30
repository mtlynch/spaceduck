#!/bin/bash

# terminate the script if any command fails
set -e

# Run JS build task
npm run build:js

# Start jekyll server
bundle exec jekyll serve --watch --port 4001
