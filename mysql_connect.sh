# Connect to Cloud SQL Instance.  Crate and populate table.
# Variables
export SERVER="fmlmysql555"
export DATABASE="db1"
export TABLE="employees"
export PASSWORD="Password1234"
export USER="mysqluser1"
export BUCKET="gs://nrtbucket1"
export FILE="employees.csv"
export BUCKETFILE="gs://nrtbucket1/employees.csv"
export PROJECTID=$(gcloud config list --format 'value(core.project)')

# Create Cloud SQL Instance
export MYSQL=$(gcloud sql instances create $SERVER --database-version=MYSQL_5_7 --tier=db-n1-standard-1 --region=us-east1 --root-password=$PASSWORD --quiet)
export MYSQLIP=$(gcloud sql instances describe $SERVER --format="value(ipAddresses.ipAddress)")
export MYLOCALIP="$(dig +short myip.opendns.com @resolver1.opendns.com)"
gcloud sql instances describe $SERVER > sqlinstance.txt

# Assign permissions to Service Account Email
export SAEMAIL=$(grep -i -o '[A-Z0-9._%+-]\+@[A-Z0-9.-]\+\.[A-Z]\{2,4\}' sqlinstance.txt)
gsutil iam ch serviceAccount:${SAEMAIL}:roles/storage.legacyObjectReader $BUCKET
# gsutil acl ch -u ${SAEMAIL}:R $BUCKET

# Authorize Local Internet IP on MySQL instance
gcloud sql instances patch $SERVER --authorized-networks=$MYLOCALIP"/32" --quiet

# Create Database & Table
mysql --host=$MYSQLIP --user=root  --password=$PASSWORD --execute "create database if not exists $DATABASE ;"
mysql --host=$MYSQLIP --user=root  --password=$PASSWORD --execute "use $DATABASE ; drop table if exists $TABLE;"
mysql --host=$MYSQLIP --user=root  --password=$PASSWORD --database=$DATABASE --execute "create table employees (employeeid VARCHAR(255),deptid VARCHAR(255),lastname VARCHAR(255),firstname VARCHAR(255),hiredate DATE,salary INT,phone VARCHAR(255),email VARCHAR(255));"
mysql --host=$MYSQLIP --user=root  --password=$PASSWORD --database=$DATABASE --execute "describe employees;"
# mysql --host=$MYSQLIP --user=root  --password=$PASSWORD --verbose --file createtable.sql

# Create MySQL User
mysql --host=$MYSQLIP --user=root  --password=$PASSWORD --database=$DATABASE --execute "CREATE USER $USER IDENTIFIED BY 'Password1234';"
mysql --host=$MYSQLIP --user=root  --password=$PASSWORD --database=$DATABASE --execute "GRANT ALL ON $DATABASE TO $USER IDENTIFIED BY 'Password1234';"
mysql --host=$MYSQLIP --user=root  --password=$PASSWORD --database=$DATABASE --execute "FLUSH PRIVILEGES;"
# mysql --host=$MYSQLIP --user=root --password=$PASSWORD --verbose --file newuser.sql

# Remove Header in CSV File
cp $FILE $FILE".old" -f
sed '1d' $FILE".old" > $FILE
gsutil rm $BUCKETFILE
gsutil cp $FILE $BUCKETFILE 
cp $FILE".old" $FILE -f

# Populate table with csv records
# The service account for the instance must be given permissions to the bucket
gcloud sql import csv $SERVER $BUCKETFILE --database=$DATABASE --table=$TABLE --quiet

# Check Data
mysql --host=$MYSQLIP --user=root  --password=$PASSWORD --execute "select * from db1.employees
order by email desc
limit 100;"



# End
# BigQuery: SELECT * FROM EXTERNAL_QUERY('dataproc1-248508.us.nrtmysql004', '''SELECT email,deptid,salary FROM employees''');





