#!/bin/bash

#*****************************************************************************
# FUNCTION DEFINITIONS
#*****************************************************************************
gdb_command()
{
	if [ -n "$1" ]; then
		echo ">>>" >&5
		echo "$1" | tee TO_GDB 1>&5
		echo ">>>" >&5
	fi
}

gdb_command_nolog()
{
	if [ -n "$1" ]; then
		echo "$1" > TO_GDB
	fi
}

#need quotes or else the log file will list contents of directory if * is passed as a parameter
log_command()
{
	if [ -n "$1" ]; then
		echo "$1" >&5	
	fi
}

log_gdb_output()
{
	while read -t 0.1 var <&4
	do
		echo "$var" >&5
	done
}

flush_gdb_output()
{
	while read -t 0.1 var <&4
	do
		true #do nothing
	done
}

separator()
{
	log_command "--------------------------------------------------"
}

gdb_var_size()
{
	#TODO want to differentiate between pointers and flat variables
	#	for pointers, prepend a * to name, and make a note
	#TODO want to go through all pieces of a struct and get their sizes?
	if [ -n "$1" ]; then
		log_command "###"
		gdb_command_nolog "print sizeof($1)"
		while read -t 0.1 var <&4
		do
			#pull everything off the gdb output before the actual value we want
			echo "$var" | sed -e 's/$[1-9].*= //' >&5
		done
		log_command "###"
	fi		
}

gdb_var_entries()
{
	while read entry <&6
	do
		#dont want empty lines
		if [ -n "$entry" ]; then
			gdb_command "ptype $entry"
			log_gdb_output
			gdb_var_size $entry
			separator
		fi
	done
}
#*****************************************************************************
# END FUNCTION DEFINITIONS
#*****************************************************************************


ME=$(basename $0)
if [ $# -lt 2 ]; then
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

gdb_var_entries
#TODO recurse through several layers of structs if needed

gdb_command_nolog "quit"

rm -f TO_GDB
rm -f FROM_GDB
