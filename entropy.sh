#!/bin/bash

# Default Go binary path
default_go_binary="go"
# Counter for how many times to run the benchmark
counter=1024

# Function to display help text
show_help() {
cat << EOF
Usage: ${0##*/} [-h] [-r] [-c COUNT]
Build and run benchmarks with optional custom Go runtime.

    -h          display this help and exit
    -r          use custom Go runtime located at /Users/asubiotto/Developer/github.com/asubiotto/go
    -c COUNT    set the number of times the benchmark should be run (default is 1024)

EOF
}

# Parse options for custom runtime flag and help
use_custom_runtime=false
while getopts "hrc:" opt; do
  case $opt in
    h)
      show_help
      exit 0
      ;;
    r)
      use_custom_runtime=true
      ;;
    c)
      counter="$OPTARG"
      ;;
    ?)
      show_help >&2
      exit 1
      ;;
  esac
done


# Create a temporary file for the output
output_file=$(mktemp)

# Ensure that the temporary file is removed on script exit
trap 'rm -f "$output_file"' EXIT

# Run build command with possible custom environment
echo "Building project"
# Set up Go environment for custom runtime, if specified
if [ "$use_custom_runtime" = true ]; then
    export GOROOT="/Users/asubiotto/Developer/github.com/asubiotto/go"
    export PATH="$GOROOT/bin:$PATH"
    export GOOS="wasip1"
    export GOARCH="wasm"
    go_binary="$GOROOT/bin/go"
    runtime_command="wasmtime --env=POLARSIGNALS_RANDOM_SEED=$POLARSIGNALS_RANDOM_SEED ./dst.wasm"
    $go_binary build -tags=faketime -o dst.wasm .
else
    go_binary="$default_go_binary"
    runtime_command="./dst"
    $go_binary build .
fi
build_status=$?
if [ $build_status -ne 0 ]; then
    echo "Failed to build project."
    exit $build_status
fi

# Check if the binary was successfully created
if [ ! -x "./dst.wasm" ] && [ "$use_custom_runtime" = true ]; then
    echo "Build did not produce a runnable 'dst.wasm' binary."
    exit 2
elif [ ! -x "./dst" ] && [ "$use_custom_runtime" = false ]; then
    echo "Build did not produce a runnable 'dst' binary."
    exit 2
fi

# Run the benchmark multiple times and append results to the temporary file
echo "POLARSIGNALS_RANDOM_SEED set to $POLARSIGNALS_RANDOM_SEED. Remember to set this env var if you want deterministic execution"
echo "Running benchmark..."
for (( i=0; i<$counter; i++ )); do
    # Modified runtime prints to stderr, so redirect to ensure everything is
    # running as expected.
    $runtime_command --workers 1024 >> "$output_file" 2>&1
done

# Process the results using the `dst` command (non-wasm).
echo "Processing results..."
export GOOS=""
export GOARCH=""
go run main.go entropy --file "$output_file"

# Confirm completion
echo "Benchmark completed and results processed."
