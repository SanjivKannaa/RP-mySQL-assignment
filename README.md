# Run terraform script to get EC2 instances

```
terraform init
terraform apply
```


# 1. Install MySQL on machine 1

```
sudo apt update -y
sudo apt upgrade -y
sudo apt install mysql-server
```

# 2. Create user with your choice of password

```
sudo mysql
```

```
create user 'jsk'@'%' identified by 'jsk';
```

# 3. Create a database with name employees 


```
create database employees;
grant all on employees.* to jsk;
exit;
```

# 4. Create few tables and insert dummy data into those tables


```
mysql -u jsk --password=jsk
```

```
use employees;
CREATE TABLE staff (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    role VARCHAR(50),
    salary DECIMAL(10,2),
    department_id INT,
    hired_date DATE
);

CREATE TABLE departments (
    dept_id INT AUTO_INCREMENT PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL
);


INSERT INTO departments (dept_name)
VALUES ('SDE'), ('DevOps'), ('DBA'), ('HR');

INSERT INTO staff (name, role, salary, department_id, hired_date)
VALUES
('Staff1', 'Software Engineer 1', 85000.00, 1, '2022-01-15'),
('Staff2', 'Engineering Manager', 120000.00, 1, '2020-07-01'),
('Staff3', 'DevOps Engineer', 65000.00, 2, '2021-03-10'),
('Staff4', 'snr DBA', 60000.00, 3, '2023-05-20'),
('Staff5', 'HR', 95000.00, 4, '2022-11-30');
exit;
```



# 5. Take MySQL dump of employees database


```
sudo mysqldump employees > backup.sql # need to give process privilage (which is a global privilege) to jsk for him to perform dump
```

copy it to local machine (laptop)

``` scp -i RP.pem ubuntu@<ip_address_of_master_node>:/home/ubuntu/backup.sql ./backup.sql ``` 

copy it to slave

``` scp -i RP.pem ./backup.sql  ubuntu@<ip_address_of_slave_node>:/home/ubuntu/backup.sql ```




# 6. Install MySQL on machine 2

```
sudo apt update -y
sudo apt upgrade -y
sudo apt install mysql-server
```

# 7. Create same user on machine 2

```
sudo mysql
```

```
create user 'jsk'@'%' identified by 'jsk';
```



# 8. Restore the dump taken in step 5 on Machine 2

```
sudo mysql
```

```
source backup.sql;
```


# 9. Learn/setup replication b/w machine 1 and machine2

reference -> https://www.digitalocean.com/community/tutorials/how-to-set-up-replication-in-mysql
### In the Master instance
Edit the /etc/mysql/mysql.conf.d/mysqld.cnf file using any text editor and make the below changes
##### BEFORE
```
bind-address            = 127.0.0.1
# server-id             = 1
# log_bin                       = /var/log/mysql/mysql-bin.log
# binlog_do_db          = include_database_name
```

##### AFTER
```
bind-address            = 0.0.0.0
server-id             = 1
log_bin                       = /var/log/mysql/mysql-bin.log
binlog_do_db          = employees
```

##### Now restart the mysql service

```
sudo systemctl restart mysql
```

##### Now create a new user to handle replicaiton
```
CREATE USER 'replica_user'@'<ip_address_of_slave_node>' IDENTIFIED WITH mysql_native_password BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'replica_user'@'<ip_address_of_slave_node>';
```

##### NOTE: 
If the master node has any data in the DB that has to be replicated, take a backup and restore it into the slave.

### In the Slave instance
Edit the /etc/mysql/mysql.conf.d/mysqld.cnf file using any text editor and make the below changes

##### BEFORE
```
# server-id             = 1
# log_bin                       = /var/log/mysql/mysql-bin.log
# binlog_do_db          = include_database_name
# relay_log              = /var/log/mysql/mysql-relay-bin.log
```

##### AFTER
```
server-id             = 2
log_bin                       = /var/log/mysql/mysql-bin.log
binlog_do_db          = include_database_name
relay_log              = /var/log/mysql/mysql-relay-bin.log
```

##### Now restart the mysql service

```
sudo systemctl restart mysql
```

##### Now tell the Slave to start replication from Master node
NOTE: The below values should be updated by running "SHOW MASTER STATUS;" command on the Master node.
1. SOURCE_LOG_FILE
2. SOURCE_LOG_POS
```
CHANGE REPLICATION SOURCE TO
SOURCE_HOST='<ip_address_of_master_node>',
SOURCE_USER='replica_user',
SOURCE_PASSWORD='password',
SOURCE_LOG_FILE='mysql-bin.000001',
SOURCE_LOG_POS=899;

START REPLICA;
```


# 10. Create another schema students and another user with name students

```
sudo mysql
```

```
CREATE DATABASE students;
CREATE USER 'students'@'%' IDENTIFIED BY 'stud_pass123';
GRANT ALL PRIVILEGES ON students.* TO 'students'@'%';
FLUSH PRIVILEGES;
```

# 11. With employees user add some data to employees database
```
mysql -u jsk --password=jsk
```

```
USE employees;

INSERT INTO departments (dept_name)
VALUES ('Marketing'), ('Support');

INSERT INTO staff (name, role, salary, department_id, hired_date)
VALUES
('Frank', 'Marketing Lead', 75000.00, 5, '2023-02-01'),
('Grace', 'Support Engineer', 58000.00, 6, '2024-06-15');

```

# 12.​With students user add some data to students database


```
mysql -u students --password=stud_pass123
```

```
USE students;

CREATE TABLE student_info (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    course VARCHAR(50),
    enrollment_date DATE
);

INSERT INTO student_info (name, course, enrollment_date)
VALUES
('stu1', 'Computer Science', '2023-08-01'),
('stu2', 'Mechanical Engineering', '2022-07-15'),
('stu3', 'Electrical Engineering', '2024-01-10');
```


# 13. Take dump of both students and employees database and restore to machine 2

take backup on master node

``` sudo mysqldump employees > backup.sql ```

copy it to local machine (laptop)

``` scp -i RP.pem ubuntu@<ip_address_of_master_node>:/home/ubuntu/backup.sql ./backup.sql ``` 

copy it to slave

``` scp -i RP.pem ./backup.sql  ubuntu@<ip_address_of_slave_node>:/home/ubuntu/backup.sql ```

restore into slave node

``` source backup.sql; ```


# 14. ​Setup RDS on AWS account (free tier) and connect to it via ec2/personal system

Done using AWS console, launched an EC2 instance and connected to RDS instnace using mycli tool.


# 15. ​Set Up an ec2 instance (free tier) and install MySQL using Generic binaries(link)


# 16. ​Explore use case of my.cnf in MySQL, learn important parameters of MySQL(link, link)

 my.conf is a configuration file that has information about:

1. Memory Allocation
   - innodb_buffer_pool_size
   - query_cache_size (for query repetetion, depreciated -> slows down sys in write-heavy scenario)
   - key_buffer_size (memory buffer of MyISAM)

2. Logging
   - general_log, general_log_file
   - slow_query_log, slow_query_log_file
   - log_error

3. Networking
   - bind-address
   - max_connections
   - wait_timeout

4. Authentication & Security
   - skip-networking
   - ssl-ca, ssl-cert, ssl-key

5. Performance Tuning
   - innodb_flush_log_at_trx_commit
   - tmp_table_size
   - thread_cache_size

It uses INI style formating (like in ansible's inventory.ini). The common sections are: 
1. client -> every action my client tools (mysql, mycli, mysqldump, mysqladmin)
2. mysqld -> memory, cache, network, etc
3. mysqld_saf3 -> logging, crash recovery, etc
4. mysqldump
5. mysqladmin


# 17. ​Try to change parameter values on MySQL install on ec2 and observe behavior Change the setting of innodb_file_per_table from 1 (default) to 0 and observe the changes ( Ketan Shridhar Kolte has added)


# 18.​ Try to go through the binary files created and try to read the transaction in the bin log (Ketan Shridhar Kolte has added)


# 19. ​Learn about User creation options and meaning of all the privileges : 
###### docs: https://dev.mysql.com/doc/refman/8.0/en/account-management-statements.html

User creation options:
1. ALTER USER Statement
2. CREATE ROLE Statement
3. CREATE USER Statement
4. DROP ROLE Statement
5. DROP USER Statement
6. GRANT Statement
7. RENAME USER Statement
8. REVOKE Statement
9. SET DEFAULT ROLE Statement
10. SET PASSWORD Statement
11. SET ROLE Statement



# 20. ​Explore mysql.user table.

the central table in MySQL that stores all user accounts and their privileges. 

Purpose of mysql.user
1. Stores users and host combinations that can connect to MySQL.
2. Defines privileges.
3. Stores authentication information (passwords, plugins, SSL requirements).
4. Manages account limitations (max connections, password expiration, etc.).


# 21. ​Explore all system databases in MySQL (mysql, information_schema,sys,performance_schema)

Default DBs created my mysql:
1. mysql -> store information needed by the mySQL server (users and privilages, stored procedure, functions, plugins and server conf)
2. information_schema -> store info/metadata about other DBs (db, table, indexes, triggers, contraints, privileges)
3. performance_schema -> low-level monitoring
4. sys -> abstraction layer over performance_schema (makes performance_schema's data easier to read)


# 22. ​With sample permission, give respective permission to the user and check if you are able to do the operation. Also try other operations and note the errors you get and understand the error meanings. Eg. If you give select permissions, check if you are able to select data and execute insert,update etc and note the errors you get

```
mysql -u root -p
```

```
create user 'jsk'@'%';
create database jsk;
grant select on jsk.* to 'jsk'@'%';
create table jsk (id int);
insert into jsk values (1);
exit;
```

```
mysql -u jsk -p
```

``` select * from jsk; ``` -> runs without error

``` insert into jsk values (1); ``` -> returns the below error
``` ERROR 1142 (42000): INSERT command denied to user 'jsk'@'localhost' for table 'jsk' ```


# 23. ​Setup replication b/w 2 machines, learn about how to setup replication on existing live running MySQL(writes are coming) using point in time recovery (MySQL dump)(link, link,link,Procedure to setup replication)


# 24. ​Show MASTER STATUS (Replication architecture)


# 25. ​SHOW SLAVE STATUS \\G cover all points


# 26.​Setup replication on the running system when sysbench is running. Setup and run sysbench on machine 1 and let it run on terminal 1. Then once its running setup replication from machine 1(use new terminal and let sysbench running on another terminal) to machine 2


# 27. ​AWS RDS Architecture Overview (In MySQL context), Usecase of RDS, Difference in RDS vs physical Databases, Features, Parameter Groups, Backups(snapshots), Multi-AZ, Failover, Replication


# 28. ​Hands on RDS


# 29. ​Prepared state is pending (sync_binlog =1 crash recovery)


# 30. ​Locking in DB
















