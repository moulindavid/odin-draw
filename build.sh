#!/bin/sh
set -e
mkdir -p build
odin build src -out:build/excalidraw-local "$@"
