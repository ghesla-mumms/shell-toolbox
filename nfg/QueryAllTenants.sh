#!/bin/sh
PGPASSFILE=.pgpass

#default to support environment
roothost=hbsupport06.mumms.com
for i in "$@"
do
case $i in
    -b=*|--bin=*)
    bin="${i#*=}"
    shift # past argument=value
    ;;
    -r=*|--roothost=*)
    roothost="${i#*=}"
    shift # past argument=value
    ;;

    *)
          # unknown option
    ;;
esac
done
echo "bin  = ${bin}"
echo "roothost = ${roothost}"
rootquery="select dbhost as dbhostvar,dbname as dbnamevar from hospice where \"hospiceETL\"";
## find out if bin is empty or not ##
[  -z "$bin" ] && echo "No bin provided, will run full list" || echo "Bin provided: ".$bin
[  -z "$bin" ] && rootquery=$rootquery" order by bin"  || rootquery=$rootquery" and bin = '$bin' order by bin"
echo $rootquery


/Library/PostgreSQL/9.4/bin/psql -t -h $roothost  -d hummingbird -U hummingbird -c "$rootquery" | while read dbhostvar dbnamevar; do
	echo "dbhost "$dbhostvar;
	dbnamevar="$(echo $dbnamevar | cut -d' ' -f 2)"; #for some reason i get extra characters in front
	echo "dbname "$dbnamevar;
	echo $(date);
	[[ -z "$dbhostvar" ]] && { echo "Done"; exit 1; }

	/Library/PostgreSQL/9.4/bin/psql -h $dbhostvar -d hummingbird  -U hummingbird -c  "select now();";
	/Library/PostgreSQL/9.4/bin/psql -h $dbhostvar -d $dbnamevar  -U hummingbird -f Step5_FunctionsViews_ETLStaging.sql;
	/Library/PostgreSQL/9.4/bin/psql -h $dbhostvar -d $dbnamevar  -U hummingbird -f Step7a_FunctionsViews_BI.sql;
	/Library/PostgreSQL/9.4/bin/psql -h $dbhostvar -d $dbnamevar  -U hummingbird -f Step7c_LoadFunctionsViews_BI.sql;
	/Library/PostgreSQL/9.4/bin/psql -h $dbhostvar -d $dbnamevar  -U hummingbird -f Step7d_FunctionsViews_BI_OLDMustRun.sql;
	/Library/PostgreSQL/9.4/bin/psql -h $dbhostvar -d $dbnamevar  -U hummingbird -f Step8_ReportsChanges_HB.sql;
	/Library/PostgreSQL/9.4/bin/psql -h $dbhostvar -d $dbnamevar  -U hummingbird -f Step9Post_Changesets_1.x37_NEWONLY.sql;

done ;
