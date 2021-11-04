#!/bin/bash
# find . -type f -mtime -1 -exec etlFilter.sh {} 10428 \;

if [[ $# < 1 ]] ; then
	echo "usage: $0 ETL-HL7-file.txt [ grep-string [ COUNT-BARS ] ]"
	exit
fi

FILE=$1

if [[ -e $FILE ]] ; then
	case $# in
		1) cat $FILE | tr '' '\n' ;;
		2) cat $FILE | tr '' '\n' | grep $2 | awk -v file=$FILE '{print $0 ", " file}' ;;
		3) cat $FILE | tr '' '\n' | grep $2 | awk -F'|' -v file=$FILE '{print NF-1 ", " file}' ;;
	esac
else
	echo "$FILE not found"
fi
