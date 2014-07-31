#!/bin/bash

ME=$(basename $0)
OS=$(uname -s)

if [ $# -lt 1 ]; then
	echo "Usage: ${ME} command [command_args]" >&2
	if [ $OS = "Linux" ]; then
		echo "Optionally set TCMALLOC=/path/to/libtcmalloc.so"
	elif [ $OS = "Darwin" ]; then
		echo "Optionally set TCMALLOC=/path/to/libtcmalloc.dylib"
	fi
	exit 1
fi

# Get the command to profile
EXECUTABLE_SHORT="$1"; shift
EXECUTABLE=$(type "$EXECUTABLE_SHORT" | sed -e 's/^.* //') || \
	EXECUTABLE="$EXECUTABLE_SHORT"
echo "Command: $EXECUTABLE_SHORT ($EXECUTABLE)"
echo "Args:    $*"

# Set environment variables for gperftools
export HEAPPFX="${ME}-${RANDOM}"
export HEAPPROFILE="$HEAPPFX"

if [ $OS = "Linux" ]; then
	: ${TCMALLOC:=/usr/local/lib/libtcmalloc.so}
	echo "Using tcmalloc from $TCMALLOC"
	export LD_PRELOAD="$TCMALLOC"
elif [ $OS = "Darwin" ]; then
	# assume Homebrew
	: ${TCMALLOC:=/usr/local/Cellar/google-perftools/2.1/lib/libtcmalloc.dylib}
	echo "Using tcmalloc from $TCMALLOC"
	export DYLD_INSERT_LIBRARIES="$TCMALLOC"
else
	echo "Unknown OS '$OS'" >&2
	exit 2
fi

# Run the requested program
echo "Running program..."
$EXECUTABLE $ARGS

# XXX is this broken?
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
if [ -z "$HEAPTRACES" ]; then
	echo "No heap traces.  Did you set \$TCMALLOC?" >&2
	exit 4
fi
echo "Heap traces are in $HEAPTRACES"

pprof --alloc_space --show_bytes --text --addresses "$EXECUTABLE" $HEAPTRACES > "$HEAPPFX".txt
pprof --pdf --alloc_space --addresses "$EXECUTABLE" "$HEAPTRACES" > "$HEAPPFX".pdf
