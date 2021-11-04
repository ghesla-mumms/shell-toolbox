#!/bin/bash

# Simulator script for mhf (PASBE) in local (mac) springboot
# test environment.
#
PGM=$0
INP=""
OUT=""
TYP="xml_pb"
NV=""
MC=""

# Configure Log File
readonly LOG="/tmp/pasbeSimulator.log"
readonly LOGERR="/tmp/pasbeSimulator.err" # Send STDERR to separate file OP-28417
touch $LOG
chmod 777 $LOG
rm -f $LOGERR
touch $LOGERR
chmod 777 $LOGERR
exec 1>>$LOG # Redirect standard ouput to log file
#exec 2>&1 # Redirect standard error to follow standard output
exec 3>&2
exec 2>>$LOGERR # Capture STDERR separate from STDOUT

# Limit the maximum size of a file in lines.
# When the file exceeds the specified limit, delete the first half of the file.
#
#	FILE($1) - file to limit
#	LIMIT($2) - Maximum number of lines
#	BACKUP($3) - backup file (optional)
#
function rollover() {
	FILE=$1
	LIMIT=$2
	HALF=$(( LIMIT / 2 ))

	# If file doesn't exist, return
	if [[ ! -e $FILE ]] ; then
		return
	fi

	if [[ -e $FILE ]] ; then
		SIZE=`cat $FILE | wc -l`
		if (( $SIZE > $LIMIT )) ; then
			# If backup file specified, backup prior to reducing size
			if [[ $# == 3 ]] ; then
				BACKUP=$3
				rm -rf $BACKUP 2>/dev/null
				cp -p $FILE $BACKUP
			fi
			# Delete first half of file
			ROLL=$(( SIZE - HALF - 1 ))
			if (( ROLL > 0 )) ; then
				sed -i -e "1,${ROLL}d" $FILE
			fi
		fi
	fi
}

rollover $LOG 1000

DATE=`date +%Y-%m-%d`
TIME=`date +%H:%M:%S`

echo -e "$DATE $TIME PASBE Start\n=================================="
echo " ARGC $# ARGV {$@}"

# Show command line options/parameters
#
function usage() {
	local ERROR=""
	echo -e "\n<<< PASBE BASH Simulation Script >>>\n"

	if [[ $# > 0 ]] ; then
		if [[ $# == 2 ]] ; then
			ERROR="$2"
		fi
		echo -e "ERROR: Invalid Command Line Option encountered: {$1}$ERROR\n"
	fi

	echo "usage: $PGM -i input.xml -o output.type -s type"
	echo "       type: emc    = X12/837"
	echo "       type: xml_pb = XML Pre-bill"
	echo "       type: txt_pb = Print Pre-bill"
	echo "       type: csv_pb = CSV - Comma Separated Value"
	echo "       type: print  = Print - UB04, HCFA-1500, Statement"
	echo
	exit 1
}

# Parse command line options
#
function parse() {
	local OPTIND

	# Parse command line arguments as standard switches
	#
	while getopts i:o:s:nh  opt ; do
		case $opt in
			i) INP=$OPTARG ;;
			o) OUT=$OPTARG ;;
			s) TYP=$OPTARG ;;
			n) NV="NextVersion" ;;
			h) usage ;;
			?) usage $opt ;;
		esac
	done

	# Now process any we missed
	#	1). getops stops when it encounters a non-switch (-x) parameter.
	#	2). pasbe-service doesn't include a space between the (-i, -o) switches
	#		and the file path/name.
	#	3). pasbe-service passes "externalbillN" which disables getopts.
	#
	while [ "$1" != "" ]; do
		parm=$1
		VALUE=$2

#	for parm in $@ ; do
		case $parm in
			-i) INP=$VALUE ; shift ;;
			-o) OUT=$VALUE ; shift ;;
			-s) TYP=$VALUE ; shift ;;
			-n) NV="NextVersion" ;;
			-C) MC="MC" ; echo "Medicare-C" ;;
			-h) usage ;;
			*)
				if [[ $parm == "-i"* ]] && [[ $INP == "" ]] ; then
					INP=`echo "$parm" | cut -c3-`
				fi
				if [[ $parm == "-o"* ]] && [[ $OUT == "" ]] ; then
					OUT=`echo "$parm" | cut -c3-`
				fi
				if [[ $parm == "-s"* ]] && [[ $TYP == "" ]] ; then
					TYP=`echo "$parm" | cut -c3-`
				fi
				;;
		esac
		shift
	done
}

if [[ $1 == "version" ]] ; then
	HB=/tmp/remote.sh
	$HB version
	echo "SOUP"
	exit 55
fi

# Parse command line
parse $@

# Validate Input File
if [[ $INP == "" ]] ; then
	usage "i" " = Missing input file"
else
	if [[ ! -s $INP ]] ; then
		usage "i" " = {$INP} Not a file or empty"
	fi
fi

# Validate Output File
if [[ $OUT == "" ]] ; then
	usage "o" " = Missing output file"
fi

# Validate Type
STYPE="ERROR"
EXT="err"
case $TYP in
	emc)	EXT="emc" ; STYPE="EMC" ;;
	txt_pb)	EXT="txt" ; STYPE="PREBILL" ;;
	xml_pb)	EXT="xml" ; STYPE="" ;;
	csv_pb)	EXT="csv" ; STYPE="PREBILL_CVS" ;;
	print)	EXT="doc" ; STYPE="PRINT_CLAIMS" ;;
	*) usage "s" " = Unrecognized Type: {$TYP}"
esac
if [[ $STYPE == "ERROR" ]] ; then
	usage "s" " = FAULT: Unrecognized Type: {$TYP}"
fi

RESPONSE_PATH="/Users/d.ferguson/dev/springboot-workspace/billing-engine/pasbe-service/misc"

cp -p $RESPONSE_PATH/CANNED$MC.$EXT $OUT
RC=$?

echo "PASBE {$INP} | $TYP > {$OUT} STATUS: $RC"

	RC=0
#	HB=/tmp/pasbe_billing.sh
#	if [[ -s $HB ]] ; then
#		echo "Running PASBE on Firebird"
#		$HB $INP $OUT $STYPE true
#		RC=$?
#	fi

	HB=/tmp/remote.sh
	if [[ -s $HB ]] ; then
		echo "Running PASBE on me2b - $MC"
		if [[ $MC == "MC" ]] ; then
			$HB -C -i $INP -o $OUT -s $TYP
		else
			$HB -i $INP -o $OUT -s $TYP
		fi
		RC=$?
	fi

exec 2>&3 # Restore STDERR

>&2 cat $LOGERR # Send PASBE STDERR to STDERR
cat $LOGERR >> $LOG # And append STDERR to log
rm -f $LOGERR # cleanup

exit $RC
