#!/bin/bash

# terminate the script if any command fails
set -e

# Start jekyll server
bundle exec jekyll serve --watch
