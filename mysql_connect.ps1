# Connect to Cloud SQL Instance.  Crate and populate table.
# Variables
$SERVER="fmlmysql055"
$DATABASE="db1"
$TABLE="employees"
$PASSWORD="Password1234"
$USER="mysqluser1"
$BUCKET="gs://nrtbucket1"
$FILE="employees.csv"
$BUCKETFILE="gs://nrtbucket1/employees.csv"
$PROJECTID=$(gcloud config list --format 'value(core.project)')

# Create Cloud SQL Instance
$MYSQL=$(gcloud sql instances create $SERVER --database-version=MYSQL_5_7 --tier=db-n1-standard-1 --region=us-east1 --root-password=$PASSWORD --quiet)
$MYSQLIP=$(gcloud sql instances describe $SERVER --format="value(ipAddresses.ipAddress)")
$MYLOCALIP=(Invoke-WebRequest -uri "https://api.ipify.org/").Content
$SQLInstance=$(gcloud sql instances describe $SERVER)

# Assign permissions to Service Account Email
$TXT=$SQLInstance | Select-String "serviceaccountemailaddress"
$RE="[a-z0-9!#\$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#\$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?"
$SAEMAIL=([regex]::MAtch($TXT, $RE, "IgnoreCase ")).value
gsutil iam ch serviceAccount:${SAEMAIL}:roles/storage.legacyObjectReader $BUCKET
# gsutil acl ch -u ${SAEMAIL}:R $BUCKET

# Authorize Local Internet IP on MySQL instance
gcloud sql instances patch $SERVER --authorized-networks=$MYLOCALIP"/32" --quiet

# Create Database & Table
mysqlsh --host=$MYSQLIP --user=root  --password=$PASSWORD --sql --execute "create database if not exists $DATABASE ;"
mysqlsh --host=$MYSQLIP --user=root  --password=$PASSWORD --sql --execute "use $DATABASE ; drop table if exists $TABLE;"
mysqlsh --host=$MYSQLIP --user=root  --password=$PASSWORD --database=$DATABASE --sql --execute "create table employees (employeeid VARCHAR(255),deptid VARCHAR(255),lastname VARCHAR(255),firstname VARCHAR(255),hiredate DATE,salary INT,phone VARCHAR(255),email VARCHAR(255));"
mysqlsh --host=$MYSQLIP --user=root  --password=$PASSWORD --database=$DATABASE --sql --execute "describe employees;"
# mysqlsh --host=$MYSQLIP --user=root  --password=$PASSWORD --verbose --file createtable.sql

# Create MySQL User
mysqlsh --host=$MYSQLIP --user=root  --password=$PASSWORD --database=$DATABASE --sql --execute "CREATE USER $USER IDENTIFIED BY 'Password1234';"
mysqlsh --host=$MYSQLIP --user=root  --password=$PASSWORD --database=$DATABASE --sql --execute "GRANT ALL ON $DATABASE TO $USER IDENTIFIED BY 'Password1234';"
mysqlsh --host=$MYSQLIP --user=root  --password=$PASSWORD --database=$DATABASE --sql --execute "FLUSH PRIVILEGES;"
# mysqlsh --host=$MYSQLIP --user=root --password=$PASSWORD --verbose --file newuser.sql

# Remove Header in CSV File
Copy-Item $FILE $FILE".old" -Force
Get-Content $FILE".old" | Select -Skip 1 | Set-Content $FILE
gsutil rm $BUCKETFILE
gsutil cp $FILE $BUCKETFILE 
Copy-Item $FILE".old" $FILE -Force

# Populate table with csv records.  Verify that the service account has the required permissions for the bucket first.
gcloud sql import csv $SERVER $BUCKETFILE --database=$DATABASE --table=$TABLE --quiet

# Check Data
mysqlsh --host=$MYSQLIP --user=root  --password=$PASSWORD --sql --execute "select * from db1.employees
order by email desc
limit 100;"



# End
# BigQuery: SELECT * FROM EXTERNAL_QUERY('dataproc1-248508.us.nrtmysql004', '''SELECT email,deptid,salary FROM employees''');

