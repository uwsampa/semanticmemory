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
EXECUTABLE_ABBRV=$(echo "$EXECUTABLE_SHORT" | sed -e 's,^.*/,,')
echo "Command: $EXECUTABLE_SHORT ($EXECUTABLE = '$EXECUTABLE_ABBRV')"
echo "Args:    $*"
ARGS=$*

# Set environment variables for gperftools
export HEAPPFX="${EXECUTABLE_ABBRV}-${RANDOM}"
export HEAPPROFILE="$HEAPPFX"
export LD_LIBRARY_PATH=/usr/lib/debug/lib/

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
mkdir $HEAPPFX	#We want to put all the output in a separate directory
mv $HEAPTRACES $HEAPPFX
echo "Heap traces are in $HEAPPFX/$HEAPTRACES"

pprof --add_lib=/usr/local/lib/libtcmalloc.so --add_lib=/lib/x86_64-linux-gnu/libc.so.6 --lib_prefix=/usr/lib/debug/lib/,/usr/lib/debug/lib/x86_64-linux-gnu/ --alloc_space --show_bytes --text --addresses "$EXECUTABLE" $HEAPPFX/$HEAPTRACES > "$HEAPPFX/$HEAPPFX".txt
pprof --add_lib=/usr/local/lib/libtcmalloc.so --add_lib=/lib/x86_64-linux-gnu/libc.so.6 --lib_prefix=/usr/lib/debug/lib/,/usr/lib/debug/lib/x86_64-linux-gnu/ --pdf --alloc_space --addresses "$EXECUTABLE" "$HEAPPFX/$HEAPTRACES" > "$HEAPPFX/$HEAPPFX"_space.pdf
pprof --add_lib=/usr/local/lib/libtcmalloc.so --add_lib=/lib/x86_64-linux-gnu/libc.so.6 --lib_prefix=/usr/lib/debug/lib/,/usr/lib/debug/lib/x86_64-linux-gnu/ --pdf --alloc_objects --addresses "$EXECUTABLE" "$HEAPPFX/$HEAPTRACES" > "$HEAPPFX/$HEAPPFX"_objects.pdf
pprof --add_lib=/usr/local/lib/libtcmalloc.so --add_lib=/lib/x86_64-linux-gnu/libc.so.6 --lib_prefix=/usr/lib/debug/lib/,/usr/lib/debug/lib/x86_64-linux-gnu/ --callgrind --alloc_space --lines "$EXECUTABLE" "$HEAPPFX/$HEAPTRACES" > "$HEAPPFX/$HEAPPFX".callgrind
callgrind_annotate --tree=caller --threshold=100 "$HEAPPFX/$HEAPPFX".callgrind > "$HEAPPFX/$HEAPPFX".results

# TODO parse the callgrind output for the callers of things like malloc
