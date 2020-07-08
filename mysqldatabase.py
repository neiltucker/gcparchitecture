import mysql.connector

newuser="user1"
password = "Password1234"
database="mysql"
hostip="35.239.134.244"

# Connect to Server
mysrv = mysql.connector.connect(
  host=hostip,
  user="root",
  passwd=password,
  database=database
)
mycursor = mysrv.cursor()

# Create New Database
mycursor.execute("CREATE DATABASE db01")

# Create New User
createuser = "CREATE USER " + newuser + " IDENTIFIED BY " + "'" + password + "'" + ";"
mycursor.execute(createuser)
databasegrantnewuser = "GRANT ALL PRIVILEGES ON " + "db01" + " TO " + newuser + " IDENTIFIED BY " + "'" + password +"'" + ";"
mycursor.execute(databasegrantnewuser)

# Connect to mysql default database
mydb = mysql.connector.connect(
  host=hostip,
  user=newuser,
  passwd=password,
  database=database
)
dbcursor = mydb.cursor()

mycursor.execute("CREATE TABLE employees (companyid VARCHAR(255), lastname VARCHAR(255), firstname VARCHAR(255), hiredate VARCHAR(255), salary VARCHAR(255), fullname VARCHAR(255) )")
mycursor.execute("SHOW TABLES")
for t in mycursor:
  print(t)

dbcursor1.execute(sql)

# mydb1.close()
# mysrv.close()


















