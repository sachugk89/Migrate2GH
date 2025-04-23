#!/bin/bash

# Function to run the audit command for each pipeline
run_audit() {
  local input_file="$1"

  while IFS=',' read -r org project; do
    if [[ -n "$org" && -n "$project" ]]; then
      output_dir="$GITHUB_WORKSPACE/Data/$org/Pipelines/$project/"
      mkdir -p "$output_dir"
      cd "$output_dir" || exit
      gh actions-importer audit azure-devops --output-dir "$output_dir"
    else
      echo "Skipping line due to missing data: org='$org', project='$project'"
    fi
  done < "$input_file"
}

INPUT_FILE="$GITHUB_WORKSPACE/Data/pipeline_details.csv"

if [[ -f "$INPUT_FILE" ]]; then
  echo "Running audit for pipelines listed in $INPUT_FILE..."
  run_audit "$INPUT_FILE"
else
  echo "Input file not found: $INPUT_FILE"
  exit 1
fi

