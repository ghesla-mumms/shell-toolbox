#!/bin/bash
# find . -type f -mtime -1 -exec etlFilter.sh {} 10428 \;

if [[ $# < 1 ]] ; then
	echo "usage: $0 ETL-HL7-file.txt [ grep-string [ COUNT-BARS ] ]"
	exit
fi

FILE=$1

if [[ -e $FILE ]] ; then
	case $# in
		1) cat $FILE | tr '
		2) cat $FILE | tr '
		3) cat $FILE | tr '
	esac
else
	echo "$FILE not found"
fi