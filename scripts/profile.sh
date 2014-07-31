#!/bin/sh

ME=$(basename $0)

if [ $# -lt 1 ]; then
	echo "Usage: ${ME} command [command_args]" >&2
	exit 1
fi

# Get the command to profile
EXECUTABLE="$1"; shift
echo "Command: $EXECUTABLE"
echo "Args:    $*"

# Set environment variables for gperftools
export HEAPPFX="${ME}-${RANDOM}"
export HEAPPROFILE="$HEAPPFX"

OS=$(uname -s)
if [ $OS = "Linux" ]; then
	export LD_PRELOAD=/usr/local/lib/libtcmalloc.so
elif [ $OS = "Darwin" ]; then
	# assume Homebrew
	export DYLD_INSERT_LIBRARIES=/usr/local/Cellar/google-perftools/2.1/lib/libtcmalloc.dylib
else
	echo "Unknown OS '$OS'" >&2
	exit 2
fi

# Run the requested program
echo "Running program..."
$EXECUTABLE $ARGS

echo "Program completed."
if [ $? -ne 0 ]; then
	echo "Program exited with nonzero exit code." >&2
	exit 3
fi

if [ $OS = "Linux" ]; then
	unset LD_PRELOAD
elif [ $OS = "Darwin" ]; then
	unset DYLD_INSERT_LIBRARIES
fi
unset HEAPPROFILE

# Everything executed OK; collect results
HEAPTRACES=$(ls "$HEAPPFX".*.heap)
echo "Heap traces are in $HEAPTRACES"

pprof --alloc_space --show_bytes --text --addresses "$EXECUTABLE" $HEAPTRACES
