#!/bin/bash

#*****************************************************************************
# GLOBAL VARIABLES (FOR USE BY FUNCTIONS)
#*****************************************************************************
#Variables to make a queue
declare -a VAR_QUEUE
DEQUEUE_INDEX=0
QUEUE_SIZE=0
DEQUEUE_RESULT=""

#*****************************************************************************
# FUNCTION DEFINITIONS
#*****************************************************************************
queue_enqueue()
{
	echo "Enqueue: $1"
	ENTRY="$1"
	VAR_QUEUE=("${VAR_QUEUE[@]}" "$ENTRY")
	(( QUEUE_SIZE++ ))
	echo "Size: $QUEUE_SIZE"
	echo
}

#result is pulled off front of queue and assigned to DEQUEUE_RESULT
queue_dequeue()
{
	if [[ QUEUE_SIZE -gt 0 ]]; then
		DEQUEUE_RESULT=${VAR_QUEUE[DEQUEUE_INDEX]}
		#unset VAR_QUEUE[DEQUEUE_INDEX] #seems to set return value to null as well
		(( DEQUEUE_INDEX++ ))
		(( QUEUE_SIZE-- ))
	else
		unset DEQUEUE_RESULT
		echo "Nothing"
	fi
	echo "Dequeue: $DEQUEUE_RESULT"
	echo "Size: $QUEUE_SIZE"
	echo
}

#only prints parts of queue in current bounds
print_queue()
{
	OUTPUT_STRING="Queue:"
	POSITION=$DEQUEUE_INDEX
	while [[ POSITION -le $(( $QUEUE_SIZE + $DEQUEUE_INDEX - 1 )) ]]
	do
		OUTPUT_STRING="$OUTPUT_STRING ${VAR_QUEUE[POSITION]}"
		(( POSITION++ ))
	done
	echo "$OUTPUT_STRING"
}

#prints entire queue that exists
print_queue_whole()
{
	echo "Whole Queue: ${VAR_QUEUE[@]}"
}

clear_queue()
{
	unset VAR_QUEUE
	QUEUE_SIZE=0
	DEQUEUE_INDEX=0
}

gdb_command()
{
	if [[ -n "$1" ]]; then
		echo ">>>" >&5
		echo "$1" | tee TO_GDB 1>&5
		echo ">>>" >&5
	fi
}

gdb_command_nolog()
{
	if [[ -n "$1" ]]; then
		echo "$1" > TO_GDB
	fi
}

#need quotes or else the log file will list contents of directory if * is passed as a parameter
log_command()
{
	if [[ -n "$1" ]]; then
		echo "$1" >&5	
	fi
}

log_gdb_output()
{
	while read -t 0.1 VAR <&4
	do
		echo "$VAR" >&5
	done
}

flush_gdb_output()
{
	while read -t 0.1 VAR <&4
	do
		true #do nothing
	done
}

separator()
{
	log_command "--------------------------------------------------"
}

#should probably use grep or sed for better regex matching
gdb_count_types()
{
	local POINTERS=0
	local CHARS=0
	local SHORTS=0
	local INTS=0
	local LONGS=0
	local LONGLONGS=0
	local FLOATS=0
	local DOUBLES=0
	local BOOLS=0
	local UINTS=0
	while read -t 0.1 VAR <&4
	do
		case "$VAR" in
		*" *"*|*"* "*)
			(( POINTERS++ ))
			;;
		*"char "*)
			(( CHARS++ ))
			;;
		*"short "*)
			(( SHORTS++ ))
			;;
		*"uint"[0-9]*"_t "*)
			(( UINTS++ ))
			;;
		*"int "*)
			(( INTS++ ))
			;;
		*"long long"*)
			(( LONGLONGS++ ))
			;;
		*"long "*)
			(( LONGS++ ))
			;;
		*"float "*)
			(( FLOATS++ ))
			;;
		*"double "*)
			(( DOUBLES++ ))
			;;
		*"_Bool "*)
			(( BOOLS++ ))
			;;
		esac
		echo "$VAR" >&5
	done
	echo "###" >&5
	echo "Number pointers: $POINTERS" >&5
	echo "Number chars: $CHARS" >&5
	echo "Number shorts: $SHORTS" >&5
	echo "Number ints: $INTS" >&5
	echo "Number longs: $LONGS" >&5
	echo "Number long longs: $LONGLONGS" >&5
	echo "Number floats: $FLOATS" >&5
	echo "Number doubles: $DOUBLES" >&5
	echo "Number _Bools: $BOOLS" >&5
	echo "Number various uint_t types: $UINTS" >&5
	echo "###" >&5
}

gdb_var_size()
{
	#TODO want to differentiate between pointers and flat variables
	#	for pointers, prepend a * to name, and make a note
	#TODO want to go through all pieces of a struct and get their sizes?
	if [[ -n "$1" ]]; then
		log_command "###"
		gdb_command_nolog "print sizeof($1)"
		while read -t 0.1 VAR <&4
		do
			#pull everything off the gdb output before the actual value we want
			echo "$VAR" | sed -e 's/$[1-9].*= //' >&5
		done
		log_command "###"
	fi		
}

gdb_primitve_size()
{
	log_command "---Primitive types---"
	log_command "###"
	gdb_command "print sizeof(void*)"
	while read -t 0.1 VAR <&4
	do
		#pull everything off the gdb output before the actual value we want
		echo "$VAR" | sed -e 's/$[1-9].*= //' >&5
	done
	log_command "###"
	gdb_command "print sizeof(char)"
	while read -t 0.1 VAR <&4
	do
		#pull everything off the gdb output before the actual value we want
		echo "$VAR" | sed -e 's/$[1-9].*= //' >&5
	done
	log_command "###"
	gdb_command "print sizeof(short)"
	while read -t 0.1 VAR <&4
	do
		#pull everything off the gdb output before the actual value we want
		echo "$VAR" | sed -e 's/$[1-9].*= //' >&5
	done
	log_command "###"
	gdb_command "print sizeof(int)"
	while read -t 0.1 VAR <&4
	do
		#pull everything off the gdb output before the actual value we want
		echo "$VAR" | sed -e 's/$[1-9].*= //' >&5
	done
	log_command "###"
	gdb_command "print sizeof(long int)"
	while read -t 0.1 VAR <&4
	do
		#pull everything off the gdb output before the actual value we want
		echo "$VAR" | sed -e 's/$[1-9].*= //' >&5
	done
	log_command "###"
	gdb_command "print sizeof(long long)"
	while read -t 0.1 VAR <&4
	do
		#pull everything off the gdb output before the actual value we want
		echo "$VAR" | sed -e 's/$[1-9].*= //' >&5
	done
	log_command "###"
	gdb_command "print sizeof(float)"
	while read -t 0.1 VAR <&4
	do
		#pull everything off the gdb output before the actual value we want
		echo "$VAR" | sed -e 's/$[1-9].*= //' >&5
	done
	log_command "###"
	gdb_command "print sizeof(double)"
	while read -t 0.1 VAR <&4
	do
		#pull everything off the gdb output before the actual value we want
		echo "$VAR" | sed -e 's/$[1-9].*= //' >&5
	done
	log_command "###"
	gdb_command "print sizeof(_Bool)"
	while read -t 0.1 VAR <&4
	do
		#pull everything off the gdb output before the actual value we want
		echo "$VAR" | sed -e 's/$[1-9].*= //' >&5
	done
	log_command "###"
	separator
}

gdb_var_entries()
{
	while read ENTRY <&6
	do
		if [ -n "$ENTRY" ]; then
			gdb_command "ptype $ENTRY"
			gdb_count_types
			#TODO recurse through several layers of structs if needed
			gdb_var_size "$ENTRY"
			separator
		fi
	done
}
#*****************************************************************************
# END FUNCTION DEFINITIONS
#*****************************************************************************


ME=$(basename $0)
if [[ $# -lt 2 ]]; then
	echo "Usage: ${ME} /path/to/binary /file/containing/variables/ [output_file]" >&2
	exit 1
fi

#Get binary to extract data from
BINARY="$1"; shift
echo "Extracting data from $BINARY"
VARFILE="$1"; shift
echo "Looking for variables from $VARFILE"
LOG=$*
: ${LOG:=gdb_output.txt}
echo "Using log file $LOG"

#Make named FIFOs
rm -f TO_GDB
rm -f FROM_GDB
mkfifo TO_GDB FROM_GDB

#Start gdb
gdb --quiet $BINARY < TO_GDB > FROM_GDB 2>&1 &

#Open file descriptors
exec 3> TO_GDB
exec 4< FROM_GDB
exec 5> $LOG
exec 6< $VARFILE

#we want to throw away all the stuff that gdb outputs at beginning
flush_gdb_output
gdb_primitve_size
gdb_var_entries

gdb_command_nolog "quit"

rm -f TO_GDB
rm -f FROM_GDB
