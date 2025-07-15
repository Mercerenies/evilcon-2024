#!/bin/bash

set -euo pipefail

for file in ../card_game/playing_card/cards/*.gd; do
  if [[ ! -f "$file" ]]; then continue; fi  # Skip if no files matched

  echo "Processing $file..."
  if ! cargo run -- "$file" >/dev/null; then
    echo "Error processing file: $file"
    exit 1
  fi
done
