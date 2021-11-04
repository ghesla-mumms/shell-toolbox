#!/bin/sh
PGPASSFILE=.pgpass



#dbhostvar=`/Library/PostgreSQL/9.4/bin/psql -t -h vmux-migrator.mumms.com -d hummingbird -U hummingbird -c "select dbhost from hospice where bin = '${bin}'"`;
#dbnamevar=`/Library/PostgreSQL/9.4/bin/psql -t -h vmux-migrator.mumms.com -d hummingbird -U hummingbird -c "select dbname from hospice where bin = '${bin}'"`;
dbhostvar="hbdemo04.mumms.com";
dbnamevar="hb_nola";
echo "dbhost ".$dbhostvar;
echo "dbname ".$dbnamevar;


for sql in `ls Step*.sql` ; do
    echo BI running: $sql;
    echo "$(date)";
    /Library/PostgreSQL/9.4/bin/psql -h $dbhostvar -d $dbnamevar  -U hummingbird -f $sql;
 done
 
