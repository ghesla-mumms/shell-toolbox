
#!/bin/sh

DBUSER=hummingbird
ROOTDBNAME=hummingbird
#default to support environment
DBHOST=prod-gce-dw-1.mumms.com
DBPORT=5432

# get parameters
for i in "$@"
do
case $i in
    -b=*|--bin=*)
    bin="${i#*=}"
    shift # passed argument=value
    ;;
    -h=*|--DBHOST=*)
    DBHOST="${i#*=}"
    shift # passed argument=value
    ;;
    -p=*|--port=*)
    DBPORT="${i#*=}"
    shift # passed argument=value
    ;;

    -q=*|--query=*)
    query="${i#*=}"
    shift # passed argument=value
    ;;

    *)
          # unknown option
    ;;
esac
done

echo "DBHOST = ${DBHOST}"
echo "bin  = ${bin}"

rootquery="select dbhost as dbhostvar, dbname as dbnamevar from hospice";
## find out if bin is empty or not ##
[  -z "$bin" ] && echo "No bin provided, will run for all ACTIVE hospices" || echo "Bin provided: ${bin}"
[  -z "$bin" ] && rootquery="${rootquery} where status = 'ACTIVE' order by bin;"  || rootquery="${rootquery}  where bin = '${bin}' order by bin;"
echo $rootquery

psql -t -h $DBHOST -p $DBPORT -d $ROOTDBNAME -U $DBUSER -c "$rootquery" | while read dbhostvar dbnamevar; do
  #echo $(date);
  [[ -z "$dbhostvar" ]] && { echo "Done"; exit 1; }
  dbnamevar="$(echo $dbnamevar | cut -d' ' -f 2)"; #for some reason i get extra characters in front
  echo "running query against dbhost: ${dbhostvar}, dbname: ${dbnamevar}: ${query}";
  echo "dbname "$dbnamevar;
  # psql -h $dbhostvar -d $dbnamevar  -U hummingbird -c "select count(*) as num_admitted_patients from patient where currentstatus = 'Admitted';";
  # psql -h $dbhostvar -d $dbnamevar  -U hummingbird -c "select count(*) as num_drfirst_sites from office where medsandprescriptions_id = -1;";
  # psql -h $dbhostvar -d $dbnamevar  -U hummingbird -c "select * from etl.hl7_jobcontrol;";
  psql -h $dbhostvar -d $dbnamevar  -U hummingbird -c "${query}"
  # psql -h $dbhostvar -d $dbnamevar  -U $DBUSER -f qry.sql;
done ;
