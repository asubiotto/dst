#!/bin/bash

# Default values
default_go_binary="go"  # Default Go binary path
counter=1024            # Default counter for how many times to run the benchmark
workers=64              # Default number of workers
custom_runtime_path=""  # Path to custom Go runtime

# Function to display help text
show_help() {
cat << EOF
Usage: ${0##*/} [-h] [-r PATH] [-c COUNT] [-w WORKERS]
Build and run benchmarks with optional custom Go runtime.

    -h          display this help and exit
    -r PATH     specify the path to the custom Go runtime
    -c COUNT    set the number of times the benchmark should be run (default is 1024)
    -w WORKERS  set the number of workers for the dst command (default is 64)

EOF
}

# Parse options
while getopts "hr:c:w:" opt; do
  case $opt in
    h)
      show_help
      exit 0
      ;;
    r)
      custom_runtime_path="$OPTARG"
      ;;
    c)
      counter="$OPTARG"
      ;;
    w)
      workers="$OPTARG"
      ;;
    ?)
      show_help >&2
      exit 1
      ;;
  esac
done

# Validate custom Go runtime path
if [[ -n "$custom_runtime_path" && ! -d "$custom_runtime_path" ]]; then
    echo "Provided custom Go runtime path does not exist or is not a directory: $custom_runtime_path"
    exit 1
fi

# Create a temporary file for the output
output_file=$(mktemp)

# Ensure that the temporary file is removed on script exit
trap 'rm -f "$output_file"' EXIT

# Run build command with possible custom environment
echo "Building project"
# Set up Go environment for custom runtime, if specified
# Set up Go environment for custom runtime, if specified
if [ -n "$custom_runtime_path" ]; then
    export GOROOT="$custom_runtime_path"
    export GOROOT="/Users/asubiotto/Developer/github.com/asubiotto/go"
    export PATH="$GOROOT/bin:$PATH"
    export GOOS="wasip1"
    export GOARCH="wasm"
    go_binary="$GOROOT/bin/go"
    runtime_command="wasmtime -S inherit-env=y ./dst.wasm"
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
echo "GORANDSEED set to $GORANDSEED. Remember to set this env var if you want deterministic execution"
echo "Running benchmark..."
for (( i=0; i<$counter; i++ )); do
    # Modified runtime prints to stderr, so redirect to ensure everything is
    # running as expected.
    $runtime_command --workers $workers >> "$output_file" 2>&1
done

# Process the results using the `dst` command (non-wasm).
echo "Processing results..."
export GOOS=""
export GOARCH=""
go run main.go entropy --file "$output_file"

# Confirm completion
echo "Benchmark completed and results processed."
