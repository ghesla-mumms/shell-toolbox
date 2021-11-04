#!/bin/bash
####
# Set up the demo data necessary for a trainer or demo user to successfully
# demonstrate the software.
# This process will include...
#  Setting reuired fields in PIM
#  Setting facesheet settings
#  Adding churches and Facilities
#  Adding teams and offices
#  Adding people with role assignments
#  Adding SSO users for a Nurse and a Physician including ClearScripts credentials
#  Setting up demo patients including Medication History in the DrFirst widgets
####

cd `dirname "${BASH_SOURCE[0]}"`
scriptname=`basename $0`
myUserName=`whoami`

. utilities.sh

#
# Show usage
#
usage() {
  echo ""
  echo "Usage: $scriptname [OPTIONS]."
  echo "   -h|--help this help message"
  echo "   --host (REQUIRED) the target database server host"
  echo "   --db (REQUIRED) the target database name"
  echo "   --phase the deployment phase"
  echo "      OPTIONS: PROD (default), STAGE, QA"
  echo "   --port psql port"
  echo "      DEFAULT - 5432"
  echo "   -safemode Printquery and ask for confirmation before running"
  echo "   -L loglevel"
  echo "      OPTIONS: ERROR, WARN, INFO, DEBUG"
  echo "      DEFAULT: ERROR"
  echo ""
} # end usage()

#
# return the absolute value of a number
#
abs() {
    [[ $[ $@ ] -lt 0 ]] && echo "$[ ($@) * -1 ]" || echo "$[ $@ ]"
}

#
# Set Defaults
#
setDefaults() {
  setLogLevel DEBUG
  if [[ -z $DB_USER ]]; then
    DB_USER="hummingbird"
  fi
  DATABASE=
  userEmailAddress=
  physicianId=
  HOSTNAME="localhost" #`hostname`
  PORT=5432
  SAFE_MODE=false
  PHASE="PROD"
  DEBUGGING=false
} #end setDefaults

#
# Parse the command line arguments and set globals
#
parseArgs() {
  while [ "$1" != "" ]; do
    PARAM=$1
    VALUE=$2
    case $PARAM in
      -h|--help)
        usage
        exit
        ;;
      --host)
        HOSTNAME=$VALUE
        shift
        ;;
      --port)
        PORT=$VALUE
        shift
        ;;
      --db)
        DATABASE=$VALUE
        shift
        ;;
      --phase)
        PHASE=$VALUE
        shift
        ;;
      -L )
        setLogLevel $VALUE
        if [ $? -ne 0 ]; then
          setLogLevel ERROR
        fi
        shift
        ;;
      -safemode)
        # Show query and ask if you want to run.
        SAFE_MODE=true
        shift
        ;;
      *)
        if [[ $PARAM == -* ]]; then
          log 0 "unknown parameter \"$PARAM\""
          usage
          exit 1
        fi
        QUERY_FILE=$PARAM
        ;;
    esac
    shift
  done

  # verify required parameters
  checkVAR "$DATABASE" "target DATABASE not provided"
  checkVAR "$HOSTNAME" "hostname not provided"
} #end parseArgs

## execute sql insert statement, returning an id
executeSql() {
  local sqlStmtIn=$1

  if [[ $DEBUGGING = true ]]; then
    printf "Running SQL: $sqlStmtIn\n" &>/dev/tty
    printf " Enter to continue, ctrl-c to stop " &>/dev/tty
    read answer
  fi

  result=`echo "${sqlStmtIn}" | psql -h ${HOSTNAME} -d ${DATABASE} -p ${PORT} -U ${DB_USER} -wAt`
  if [ $? -ne 0 ]; then
    log 0 "An error occurred executing a SQL statement."
    exit 1
  fi

  echo $result
  return 0
}

## execute sql insert statement, returning an id
executeInsertReturningId() {
  local insertStmtIn=$1

  result=$(executeSql "${insertStmtIn} returning id;")
  if [ $? -ne 0 ]; then
    log 0 "An error occurred executing an insert statement."
    log 0 " statement: ${sqlStmtIn}"
    log 0 " result: $result"
    exit 1
  fi

  returnId=`echo $result | cut -f1 -d ' '`
  if [ $? -ne 0 ]; then
    log 0 "An error occurred extracting the id from the insert results."
    exit 1
  fi

  echo $returnId
  return 0
}

getHospiceId() {
  local sqlStmt="select id from hospice;"
  local hospiceId=$(executeSql "$sqlStmt")
  checkVAR "$hospiceId" "A hospice id could not be determined"

  echo "$hospiceId"
  return 0
}

## Add an address
addAddress() {
  local street1In=$1
  local street2In=$2
  local cityIn=$3
  local countyIn=$4
  local stateIn=$5
  local zipIn=$6
  local zip4In=$7

  local insertStmt="insert into address(issystemdefined,lastupdatetime,version,lastupdateuser,city,county,state,street1,street2,zip,zip4)
                                values(FALSE,now(),now(),'${myUserName}','${cityIn}','${countyIn}','${stateIn}','${street1In}','${street2In}','${zipIn}','${zip4In}')"
  local addrId=$(executeInsertReturningId "$insertStmt")
  checkVAR "$addrId" "An address was not successfully created"

  echo $addrId
  return 0
}

addSmartformResponse() {
  local personIdIn=$1
  local questionTextIn=$2
  local answerTextIn=$3

  local questionIdSql="SELECT id FROM smartformquestion WHERE questiontext = '$questionTextIn' AND hospice_id IS NULL"
  if [[ "$questionTextIn" == "NPI Number" ]]; then
    questionIdSql="${questionIdSql} and entityclassname = 'Person' and actiontype = 'READONLY'"
  fi
  local questionId=$(executeSql "$questionIdSql")
  checkVAR "$questionId" "The questionId could not be determined"

  local insertStmt="INSERT INTO smartformresponse (answer_id,
        question_id,
        issystemdefined,lastupdatetime,version,deleted,lastupdateuser)
    SELECT (SELECT id FROM smartformanswer WHERE answertext = '$answerTextIn' AND question_id = $questionId) as answer_id,
        $questionId as question_id,
  			FALSE,now(),now(),FALSE,'$myUserName'"
  local smartformResponseId=$(executeInsertReturningId "$insertStmt")
  checkVAR "$smartformResponseId" "A smartformResponseId was not returned."
  insertStmt="INSERT INTO person_smartformresponse (person_id,smartformresponses_id)
  	SELECT $personIdIn,$smartformResponseId"
  local result=$(executeSql "$insertStmt")
}

addPersonRole() {
  local personIdIn=$1
  local roleNameIn=$2

  local roleId=

  local roleIdSql="select id from hbrole where not deleted and issystemdefined and name = '$roleNameIn';"
  roleId=$(executeSql "$roleIdSql")
  checkVAR "$roleId" "A roleId was not returned."

  local insertStmt="INSERT INTO person_role (issystemdefined,lastupdateuser,lastupdatetime,version,
        rank,person_id,role_id,deleted)
    SELECT FALSE AS issystemdefined, '$myUserName' AS lastupdateuser, now() AS lastupdatetime, now() AS version,
        (select count(*) from person_role where person_id = $personId) AS rank,$personIdIn,$roleId,false AS deleted"
  local response=$(executeSql "$insertStmt")
}

addPerson() {
  local personIdIn=$1
  local firstnameIn=$2
  local lastnameIn=$3
  local credentialsIn=$4
  local emailIn=$5
  local ldapSerialIn=$6
  local addrIdIn=$7
  local titleIn=$8
  local officeIdIn=$9
  local clearScriptsLoginIn=${10}
  local npiIn=${11}

  local hospiceId=$(getHospiceId)

  if [[ -n $personIdIn ]]; then
    # We passed in a personId. Make sure the person does not exist before continuing
    local sqlStatement="select count(*) from person where id = $personIdIn;"
    local numPersonrecords=$(executeSql "$sqlStatement")
    if (( $numPersonrecords > 0 )); then
      echo "0"
      return 0
    fi
  fi

  local insertString="insert into person ("
  local valuesString="values("
  local personNumber=

  local hasLdapprofile="false"
  if [ -n "$ldapSerialIn" ]; then
    hasLdapprofile="true"
  fi

  if [ -n "$personIdIn" ]; then
    personNumber=$(abs $personIdIn)
    insertString="${insertString}id,personnumber,"
    valuesString="${valuesString}${personIdIn},'${personNumber}',"
  fi
  if [ -n "$addrIdIn" ]; then
    insertString="${insertString}address_id,"
    valuesString="${valuesString}${addrIdIn},"
  fi
  if [ -n "$clearScriptsLoginIn" ]; then
    insertString="${insertString}clearscriptslogin,"
    valuesString="${valuesString}'${clearScriptsLoginIn}',"
  fi
  if [ -n "$npiIn" ]; then
    insertString="${insertString}npi,"
    valuesString="${valuesString}'${npiIn}',"
  fi

  insertString="${insertString}issystemdefined,deleted,lastupdatetime,version,lastupdateuser,lastname,firstname,
        credentials,email,employmentstartdate,hasldapprofile,serialnumber,active,
        sex,hospice_id,salutation)"
  valuesString="${valuesString}FALSE,FALSE,now(),now(),'$myUserName','$lastnameIn','$firstnameIn',
      '$credentialsIn','$emailIn','2019-01-01',$hasLdapprofile,'$ldapSerialIn',TRUE,
      'Unknown',$hospiceId,'$titleIn')"

  local insertStmt="${insertString} ${valuesString}"
  local personId=$(executeInsertReturningId "$insertStmt")
  checkVAR "$personId" "A personId was not returned."

  insertStmt="insert into teampersonassignment (issystemdefined,lastupdatetime,lastupdateuser,version,deleted,person_id,teamperson_id)
      (select false, now(), '$myUserName', now(), false, $personId, t.id from teampersonlist t where not t.deleted);"
  result=$(executeSql "$insertStmt")

  if [ -n "$officeIdIn" ]; then
    insertStmt="insert into person_office (person_id, office_id, rank)
      values ($personId, $officeIdIn, 0);"
    result=$(executeSql "$insertStmt")
  fi

  insertStmt="insert into person_site
    (select $personId,id,row_number() over (order by id) as row
    from office
    where officetype ='Site' and deleted = false);"
  result=$(executeSql "$insertStmt")

  insertStmt="insert into person_programsite
    (select $personId,id,row_number() over (order by id) as row
    from programsite
    where deleted = false);"
  result=$(executeSql "$insertStmt")

  echo $personId
  return 0
}

confirmParms() {
  if [[ $SAFE_MODE = true ]]; then
    printf "Setting up demo data on host: ${HOSTNAME}, database: ${DATABASE}, port: ${PORT}\n" &>/dev/tty
    printf " Continue? (y/n) " &>/dev/tty
    read answer
    echo $answer | grep -i "^y" >>/dev/null
    if [ $? -ne 0 ]; then
      log 2 "Aborting ... "
      exit 1
    fi
  fi
}

setDefaults
## 1. get the parms and verify required parms
parseArgs $@
## Have the user verify the parameters
confirmParms

addrId=$(addAddress "822 Camp St." "" "New Orleans" "Orleans" "LA" "70130" "1234")
personId=$(addPerson -51 "Physician" "Apple" "MD" "jeff+physapple@mumms.com" "ApplePhysSerial51" "$addrId" "" "17" "18" "" "1999990001")
echo " personId = ${personId}"

checkVAR "$personId" "A person was not successfully created"
if [[ "$personId" != "0" ]]; then
  result=$(addPersonRole "$personId" "Physician")
  result=$(addPersonRole "$personId" "Hospice User")
  result=$(addPersonRole "$personId" "DMS Meds")
  result=$(addPersonRole "$personId" "DMS Finance")
  result=$(addPersonRole "$personId" "DMS Administrator")
  result=$(addPersonRole "$personId" "IDG Meeting Master")
  result=$(addPersonRole "$personId" "HIS Clerk")
  result=$(addPersonRole "$personId" "Accountant")
  result=$(addSmartformResponse "$personId" "Doctor" "Doctor")
  result=$(addSmartformResponse "$personId" "NPI Number" "*")
  result=$(addSmartformResponse "$personId" "Hummingbird User" "Yes")
  result=$(addSmartformResponse "$personId" "User Type" "Hospice Administrator")
  result=$(addSmartformResponse "$personId" "Hospice Employee" "Yes")
  result=$(addSmartformResponse "$personId" "Employee Type" "Full-Time")
fi



log 4 "all Done!"
