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

for  GTID based replication refer -> https://dev.mysql.com/doc/refman/8.4/en/replication-gtids-howto.html, https://dev.mysql.com/doc/refman/8.4/en/replication-gtids-failover.html

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
CHANGE REPLICATION SOURCE TO SOURCE_HOST='<ip_address_of_master_node>', SOURCE_USER='replica_user', SOURCE_PASSWORD='password', SOURCE_LOG_FILE='mysql-bin.000001', SOURCE_LOG_POS=899;

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


# 15. ​Set Up an ec2 instance (free tier) and install MySQL using Generic binaries
ref -> https://dev.mysql.com/doc/refman/8.0/en/binary-installation.html#:~:text=Oracle%20provides%20a%20set%20of,package%20formats%20for%20selected%20platforms.

--> ubuntu 24.x has issues with a required package (libaio1)


install this package -> libaio1
```
apt-cache search libaio # search for info
apt-get install libaio1 # install library
```


```
groupadd mysql
useradd -r -g mysql -s /bin/false mysql
cd /usr/local
tar xvf </path/to/mysql-VERSION-OS.tar.xz>
ln -s </full/path/to/mysql/VERSION-OS> mysql
cd mysql
mkdir mysql-files
chown mysql:mysql mysql-files
chmod 750 mysql-files
bin/mysqld --initialize --user=mysql
bin/mysqld_safe --user=mysql &
# Next command is optional
cp support-files/mysql.server /etc/init.d/mysql.server
```


note ==> set the location of mysql.sock file ... and other conf stuff also



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

reference - https://stackoverflow.com/questions/43572049/how-can-i-change-the-innodb-file-per-table-parameter-from-off-to-1-for-an


#### innodb_file_per_table is a configuration setting that determines how InnoDB stores data for individual tables. It impacts the way tablespaces are managed and affects performance, storage, and maintenance.
#### innodb_file_per_table = 0 => all InnoDB tables are stored in a single shared system tablespace file (ibdata1). 
ADV -> 
1. better cause multiple reads can be done together without seperate I/O
2. No need to handle files seperately
DIS-ADV -> 
1. bulky files, hard in case of backups or migration etc
2. if a table is cleared, the space may not be freed by the OS... leading to unneccessary storage consumption

#### innodb_file_per_table = 1 (default) => Each InnoDB table has a seperate file (.idb) for itself.
ADV -> 
1. better disk management and table maintenance
DIS-ADV ->
1. Relatively Higher I/O


Use Case for ibdata1 (Shared Tablespace):
1. Small databases with a limited number of tables.
2. Environments where simplicity and low file system overhead are priorities.
3. Applications where tables are not frequently dropped, truncated, or modified.

Use Case for .ibd (File-Per-Table Tablespace):
1. Large-scale databases with many tables or high transaction volumes.
2. Applications where tables are frequently dropped, truncated, or migrated.
3. Environments requiring efficient disk space management and scalability.
4. Databases where per-table backups, restores, or optimizations are needed.

# 18.​ Try to go through the binary files created and try to read the transaction in the bin log (Ketan Shridhar Kolte has added)

```
root@ip-172-31-34-69:/var/log/mysql# mysqlbinlog mysql-bin.000001 
# The proper term is pseudo_replica_mode, but we use this compatibility alias
# to make the statement usable on server versions 8.0.24 and older.
/*!50530 SET @@SESSION.PSEUDO_SLAVE_MODE=1*/;
/*!50003 SET @OLD_COMPLETION_TYPE=@@COMPLETION_TYPE,COMPLETION_TYPE=0*/;
DELIMITER /*!*/;
# at 4
#250924 18:24:12 server id 1  end_log_pos 126 CRC32 0x97fca604 	Start: binlog v 4, server v 8.0.43-0ubuntu0.24.04.2 created 250924 18:24:12 at startup
# Warning: this binlog is either in use or was not closed properly.
ROLLBACK/*!*/;
BINLOG '
TDfUaA8BAAAAegAAAH4AAAABAAQAOC4wLjQzLTB1YnVudHUwLjI0LjA0LjIAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAABMN9RoEwANAAgAAAAABAAEAAAAYgAEGggAAAAICAgCAAAACgoKKioAEjQA
CigAAQSm/Jc=
'/*!*/;
# at 126
#250924 18:24:12 server id 1  end_log_pos 157 CRC32 0x563e28e9 	Previous-GTIDs
# [empty]
# at 157
#250924 18:32:16 server id 1  end_log_pos 236 CRC32 0x3d122d1c 	Anonymous_GTID	last_committed=0	sequence_number=1	rbr_only=no	original_committed_timestamp=1758738736902961	immediate_commit_timestamp=1758738736902961	transaction_length=316
# original_commit_timestamp=1758738736902961 (2025-09-24 18:32:16.902961 UTC)
# immediate_commit_timestamp=1758738736902961 (2025-09-24 18:32:16.902961 UTC)
/*!80001 SET @@session.original_commit_timestamp=1758738736902961*//*!*/;
/*!80014 SET @@session.original_server_version=80043*//*!*/;
/*!80014 SET @@session.immediate_server_version=80043*//*!*/;
SET @@SESSION.GTID_NEXT= 'ANONYMOUS'/*!*/;
# at 236
#250924 18:32:16 server id 1  end_log_pos 473 CRC32 0x87dec12b 	Query	thread_id=12	exec_time=0	error_code=0	Xid = 3
SET TIMESTAMP=1758738736.890008/*!*/;
SET @@session.pseudo_thread_id=12/*!*/;
SET @@session.foreign_key_checks=1, @@session.sql_auto_is_null=0, @@session.unique_checks=1, @@session.autocommit=1/*!*/;
SET @@session.sql_mode=1168113696/*!*/;
SET @@session.auto_increment_increment=1, @@session.auto_increment_offset=1/*!*/;
/*!\C utf8mb4 *//*!*/;
SET @@session.character_set_client=255,@@session.collation_connection=255,@@session.collation_server=255/*!*/;
SET @@session.time_zone='SYSTEM'/*!*/;
SET @@session.lc_time_names=0/*!*/;
SET @@session.collation_database=DEFAULT/*!*/;
/*!80011 SET @@session.default_collation_for_utf8mb4=255*//*!*/;
CREATE USER 'replica_user'@'<ip_address_of_slave_node>' IDENTIFIED WITH 'mysql_native_password' AS '*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19'
/*!*/;
# at 473
#250924 18:35:06 server id 1  end_log_pos 552 CRC32 0x6ec77db0 	Anonymous_GTID	last_committed=1	sequence_number=2	rbr_only=no	original_committed_timestamp=1758738906232767	immediate_commit_timestamp=1758738906232767	transaction_length=304
# original_commit_timestamp=1758738906232767 (2025-09-24 18:35:06.232767 UTC)
# immediate_commit_timestamp=1758738906232767 (2025-09-24 18:35:06.232767 UTC)
/*!80001 SET @@session.original_commit_timestamp=1758738906232767*//*!*/;
/*!80014 SET @@session.original_server_version=80043*//*!*/;
/*!80014 SET @@session.immediate_server_version=80043*//*!*/;
SET @@SESSION.GTID_NEXT= 'ANONYMOUS'/*!*/;
# at 552
#250924 18:35:06 server id 1  end_log_pos 777 CRC32 0x586846f2 	Query	thread_id=12	exec_time=0	error_code=0	Xid = 6
SET TIMESTAMP=1758738906.229548/*!*/;
CREATE USER 'replica_user'@'13.232.166.198' IDENTIFIED WITH 'mysql_native_password' AS '*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19'
/*!*/;
# at 777
#250924 18:35:32 server id 1  end_log_pos 854 CRC32 0xaabf9a68 	Anonymous_GTID	last_committed=2	sequence_number=3	rbr_only=no	original_committed_timestamp=1758738932299069	immediate_commit_timestamp=1758738932299069	transaction_length=241
# original_commit_timestamp=1758738932299069 (2025-09-24 18:35:32.299069 UTC)
# immediate_commit_timestamp=1758738932299069 (2025-09-24 18:35:32.299069 UTC)
/*!80001 SET @@session.original_commit_timestamp=1758738932299069*//*!*/;
/*!80014 SET @@session.original_server_version=80043*//*!*/;
/*!80014 SET @@session.immediate_server_version=80043*//*!*/;
SET @@SESSION.GTID_NEXT= 'ANONYMOUS'/*!*/;
# at 854
#250924 18:35:32 server id 1  end_log_pos 1018 CRC32 0x18a622bd 	Query	thread_id=12	exec_time=0	error_code=0	Xid = 7
SET TIMESTAMP=1758738932/*!*/;
GRANT REPLICATION SLAVE ON *.* TO 'replica_user'@'13.232.166.198'
/*!*/;
# at 1018
#250924 18:40:15 server id 1  end_log_pos 1095 CRC32 0x6ac0ad8c 	Anonymous_GTID	last_committed=3sequence_number=4	rbr_only=no	original_committed_timestamp=1758739215522822	immediate_commit_timestamp=1758739215522822	transaction_length=182
# original_commit_timestamp=1758739215522822 (2025-09-24 18:40:15.522822 UTC)
# immediate_commit_timestamp=1758739215522822 (2025-09-24 18:40:15.522822 UTC)
/*!80001 SET @@session.original_commit_timestamp=1758739215522822*//*!*/;
/*!80014 SET @@session.original_server_version=80043*//*!*/;
/*!80014 SET @@session.immediate_server_version=80043*//*!*/;
SET @@SESSION.GTID_NEXT= 'ANONYMOUS'/*!*/;
# at 1095
#250924 18:40:15 server id 1  end_log_pos 1200 CRC32 0x0e9686e1 	Query	thread_id=13	exec_time=0	error_code=0	Xid = 11
SET TIMESTAMP=1758739215/*!*/;
/*!80016 SET @@session.default_table_encryption=0*//*!*/;
create database jsk
/*!*/;
# at 1200
#250924 18:40:27 server id 1  end_log_pos 1277 CRC32 0xcabb62b5 	Anonymous_GTID	last_committed=4sequence_number=5	rbr_only=no	original_committed_timestamp=1758739227753138	immediate_commit_timestamp=1758739227753138	transaction_length=188
# original_commit_timestamp=1758739227753138 (2025-09-24 18:40:27.753138 UTC)
# immediate_commit_timestamp=1758739227753138 (2025-09-24 18:40:27.753138 UTC)
/*!80001 SET @@session.original_commit_timestamp=1758739227753138*//*!*/;
/*!80014 SET @@session.original_server_version=80043*//*!*/;
/*!80014 SET @@session.immediate_server_version=80043*//*!*/;
SET @@SESSION.GTID_NEXT= 'ANONYMOUS'/*!*/;
# at 1277
#250924 18:40:27 server id 1  end_log_pos 1388 CRC32 0xe4f6e743 	Query	thread_id=13	exec_time=0	error_code=0	Xid = 16
use `jsk`/*!*/;
SET TIMESTAMP=1758739227/*!*/;
/*!80013 SET @@session.sql_require_primary_key=0*//*!*/;
create table jsk (id int)
/*!*/;
# at 1388
#250924 18:40:40 server id 1  end_log_pos 1467 CRC32 0x77c75de1 	Anonymous_GTID	last_committed=5sequence_number=6	rbr_only=yes	original_committed_timestamp=1758739240367426	immediate_commit_timestamp=1758739240367426	transaction_length=282
/*!50718 SET TRANSACTION ISOLATION LEVEL READ COMMITTED*//*!*/;
# original_commit_timestamp=1758739240367426 (2025-09-24 18:40:40.367426 UTC)
# immediate_commit_timestamp=1758739240367426 (2025-09-24 18:40:40.367426 UTC)
/*!80001 SET @@session.original_commit_timestamp=1758739240367426*//*!*/;
/*!80014 SET @@session.original_server_version=80043*//*!*/;
/*!80014 SET @@session.immediate_server_version=80043*//*!*/;
SET @@SESSION.GTID_NEXT= 'ANONYMOUS'/*!*/;
# at 1467
#250924 18:40:40 server id 1  end_log_pos 1541 CRC32 0xaf63bfd7 	Query	thread_id=13	exec_time=0	error_code=0
SET TIMESTAMP=1758739240/*!*/;
BEGIN
/*!*/;
# at 1541
#250924 18:40:40 server id 1  end_log_pos 1589 CRC32 0x6d5687c5 	Table_map: `jsk`.`jsk` mapped to number 93
# has_generated_invisible_primary_key=0
# at 1589
#250924 18:40:40 server id 1  end_log_pos 1639 CRC32 0x983594a9 	Write_rows: table id 93 flags: STMT_END_F

BINLOG '
KDvUaBMBAAAAMAAAADUGAAAAAF0AAAAAAAEAA2pzawADanNrAAEDAAEBAQDFh1Zt
KDvUaB4BAAAAMgAAAGcGAAAAAF0AAAAAAAEAAgAB/wABAAAAAAIAAAAAAwAAAKmUNZg=
'/*!*/;
# at 1639
#250924 18:40:40 server id 1  end_log_pos 1670 CRC32 0xfc815670 	Xid = 17
COMMIT/*!*/;
# at 1670
#250924 18:48:23 server id 1  end_log_pos 1749 CRC32 0x716e748d 	Anonymous_GTID	last_committed=6sequence_number=7	rbr_only=yes	original_committed_timestamp=1758739703631564	immediate_commit_timestamp=1758739703631564	transaction_length=272
/*!50718 SET TRANSACTION ISOLATION LEVEL READ COMMITTED*//*!*/;
# original_commit_timestamp=1758739703631564 (2025-09-24 18:48:23.631564 UTC)
# immediate_commit_timestamp=1758739703631564 (2025-09-24 18:48:23.631564 UTC)
/*!80001 SET @@session.original_commit_timestamp=1758739703631564*//*!*/;
/*!80014 SET @@session.original_server_version=80043*//*!*/;
/*!80014 SET @@session.immediate_server_version=80043*//*!*/;
SET @@SESSION.GTID_NEXT= 'ANONYMOUS'/*!*/;
# at 1749
#250924 18:48:23 server id 1  end_log_pos 1823 CRC32 0x822b84df 	Query	thread_id=18	exec_time=0	error_code=0
SET TIMESTAMP=1758739703/*!*/;
BEGIN
/*!*/;
# at 1823
#250924 18:48:23 server id 1  end_log_pos 1871 CRC32 0x044f3b3b 	Table_map: `jsk`.`jsk` mapped to number 93
# has_generated_invisible_primary_key=0
# at 1871
#250924 18:48:23 server id 1  end_log_pos 1911 CRC32 0x1a281b83 	Write_rows: table id 93 flags: STMT_END_F

BINLOG '
9zzUaBMBAAAAMAAAAE8HAAAAAF0AAAAAAAEAA2pzawADanNrAAEDAAEBAQA7O08E
9zzUaB4BAAAAKAAAAHcHAAAAAF0AAAAAAAEAAgAB/wAFAAAAgxsoGg==
'/*!*/;
# at 1911
#250924 18:48:23 server id 1  end_log_pos 1942 CRC32 0x1cea855e 	Xid = 106
COMMIT/*!*/;
# at 1942
#250924 18:51:34 server id 1  end_log_pos 2021 CRC32 0x111453ab 	Anonymous_GTID	last_committed=7sequence_number=8	rbr_only=yes	original_committed_timestamp=1758739894593755	immediate_commit_timestamp=1758739894593755	transaction_length=272
/*!50718 SET TRANSACTION ISOLATION LEVEL READ COMMITTED*//*!*/;
# original_commit_timestamp=1758739894593755 (2025-09-24 18:51:34.593755 UTC)
# immediate_commit_timestamp=1758739894593755 (2025-09-24 18:51:34.593755 UTC)
/*!80001 SET @@session.original_commit_timestamp=1758739894593755*//*!*/;
/*!80014 SET @@session.original_server_version=80043*//*!*/;
/*!80014 SET @@session.immediate_server_version=80043*//*!*/;
SET @@SESSION.GTID_NEXT= 'ANONYMOUS'/*!*/;
# at 2021
#250924 18:51:34 server id 1  end_log_pos 2095 CRC32 0x752e1a49 	Query	thread_id=18	exec_time=0	error_code=0
SET TIMESTAMP=1758739894/*!*/;
BEGIN
/*!*/;
# at 2095
#250924 18:51:34 server id 1  end_log_pos 2143 CRC32 0x80fef085 	Table_map: `jsk`.`jsk` mapped to number 93
# has_generated_invisible_primary_key=0
# at 2143
#250924 18:51:34 server id 1  end_log_pos 2183 CRC32 0xb0c74b06 	Write_rows: table id 93 flags: STMT_END_F

BINLOG '
tj3UaBMBAAAAMAAAAF8IAAAAAF0AAAAAAAEAA2pzawADanNrAAEDAAEBAQCF8P6A
tj3UaB4BAAAAKAAAAIcIAAAAAF0AAAAAAAEAAgAB/wAGAAAABkvHsA==
'/*!*/;
# at 2183
#250924 18:51:34 server id 1  end_log_pos 2214 CRC32 0x3f340ce6 	Xid = 110
COMMIT/*!*/;
# at 2214
#250924 18:53:21 server id 1  end_log_pos 2291 CRC32 0x5872e7cf 	Anonymous_GTID	last_committed=8sequence_number=9	rbr_only=no	original_committed_timestamp=1758740001314784	immediate_commit_timestamp=1758740001314784	transaction_length=178
# original_commit_timestamp=1758740001314784 (2025-09-24 18:53:21.314784 UTC)
# immediate_commit_timestamp=1758740001314784 (2025-09-24 18:53:21.314784 UTC)
/*!80001 SET @@session.original_commit_timestamp=1758740001314784*//*!*/;
/*!80014 SET @@session.original_server_version=80043*//*!*/;
/*!80014 SET @@session.immediate_server_version=80043*//*!*/;
SET @@SESSION.GTID_NEXT= 'ANONYMOUS'/*!*/;
# at 2291
#250924 18:53:21 server id 1  end_log_pos 2392 CRC32 0x11a91712 	Query	thread_id=18	exec_time=0	error_code=0	Xid = 116
SET TIMESTAMP=1758740001/*!*/;
drop database jsk
/*!*/;
# at 2392
#250924 19:16:37 server id 1  end_log_pos 2469 CRC32 0x7cd98adc 	Anonymous_GTID	last_committed=9sequence_number=10	rbr_only=no	original_committed_timestamp=1758741397835999	immediate_commit_timestamp=1758741397835999	transaction_length=182
# original_commit_timestamp=1758741397835999 (2025-09-24 19:16:37.835999 UTC)
# immediate_commit_timestamp=1758741397835999 (2025-09-24 19:16:37.835999 UTC)
/*!80001 SET @@session.original_commit_timestamp=1758741397835999*//*!*/;
/*!80014 SET @@session.original_server_version=80043*//*!*/;
/*!80014 SET @@session.immediate_server_version=80043*//*!*/;
SET @@SESSION.GTID_NEXT= 'ANONYMOUS'/*!*/;
# at 2469
#250924 19:16:37 server id 1  end_log_pos 2574 CRC32 0x90d823d3 	Query	thread_id=18	exec_time=0	error_code=0	Xid = 247
SET TIMESTAMP=1758741397/*!*/;
/*!80016 SET @@session.default_table_encryption=0*//*!*/;
create database jsk
/*!*/;
# at 2574
#250924 19:17:15 server id 1  end_log_pos 2651 CRC32 0xd35b4f6e 	Anonymous_GTID	last_committed=1sequence_number=11	rbr_only=no	original_committed_timestamp=1758741435517837	immediate_commit_timestamp=1758741435517837	transaction_length=188
# original_commit_timestamp=1758741435517837 (2025-09-24 19:17:15.517837 UTC)
# immediate_commit_timestamp=1758741435517837 (2025-09-24 19:17:15.517837 UTC)
/*!80001 SET @@session.original_commit_timestamp=1758741435517837*//*!*/;
/*!80014 SET @@session.original_server_version=80043*//*!*/;
/*!80014 SET @@session.immediate_server_version=80043*//*!*/;
SET @@SESSION.GTID_NEXT= 'ANONYMOUS'/*!*/;
# at 2651
#250924 19:17:15 server id 1  end_log_pos 2762 CRC32 0x7cdc437b 	Query	thread_id=18	exec_time=0	error_code=0	Xid = 252
use `jsk`/*!*/;
SET TIMESTAMP=1758741435/*!*/;
/*!80013 SET @@session.sql_require_primary_key=0*//*!*/;
create table jsk (id int)
/*!*/;
SET @@SESSION.GTID_NEXT= 'AUTOMATIC' /* added by mysqlbinlog */ /*!*/;
DELIMITER ;
# End of log file
/*!50003 SET COMPLETION_TYPE=@OLD_COMPLETION_TYPE*/;
/*!50530 SET @@SESSION.PSEUDO_SLAVE_MODE=0*/;
root@ip-172-31-34-69:/var/log/mysql# 

```

# 19. ​Learn about User creation options and meaning of all the privileges : 
###### docs: https://dev.mysql.com/doc/refman/8.0/en/account-management-statements.html

User creation options:
1. CREATE USER ..
2. ALTER USER ..
3. DROP USER ..
4. GRANT ..
5. REVOKE ..
6. SET PASSWORD ..
7. CREATE ROLE ..
8. DROP ROLE ..
9. SET DEFAULT ROLE ..
10. SET ROLE ..



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



# 23. ​Setup replication b/w 2 machines, learn about how to setup replication on existing live running MySQL(writes are coming) using point in time recovery 
references ->
1. https://dev.mysql.com/doc/mysql-replication-excerpt/8.0/en/replication-howto.html
2. https://dev.mysql.com/doc/mysql-replication-excerpt/8.0/en/replication-howto-masterstatus.html
3. https://dev.mysql.com/doc/mysql-replication-excerpt/8.0/en/replication-howto-mysqldump.html
4. https://linuxscriptshub.com/mysql-replication-setup-without-downtime/

STEPS:
1. At the same time, took backup of master, and ran show master status (to get the binlog file and pointer)
2. restore the backup into slave
3. setup the slave and start (With the values got from step 1)
4. slave will start replication from that point


but not sure how feasible...
should be better with GTID replication!!



# 24. ​Show MASTER STATUS (Replication architecture)

```
mysql> show master status \G
*************************** 1. row ***************************
             File: mysql-bin.000001
         Position: 2762
     Binlog_Do_DB: jsk
 Binlog_Ignore_DB: 
Executed_Gtid_Set: 
1 row in set (0.00 sec)
```

# 25. ​SHOW SLAVE STATUS \\G cover all points

```
mysql> show slave status \G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for source to send event
                  Master_Host: 13.235.244.45
                  Master_User: replica_user
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000001
          Read_Master_Log_Pos: 2392
               Relay_Log_File: ip-172-31-35-107-relay-bin.000002
                Relay_Log_Pos: 326
        Relay_Master_Log_File: mysql-bin.000001
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: 
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 2392
              Relay_Log_Space: 547
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 1
                  Master_UUID: cb36d761-9972-11f0-87d8-0227182a723b
             Master_Info_File: mysql.slave_master_info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Replica has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 
                Auto_Position: 0
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
       Master_public_key_path: 
        Get_master_public_key: 0
            Network_Namespace: 
1 row in set, 1 warning (0.00 sec)
```


# 26.​Setup replication on the running system when sysbench is running. Setup and run sysbench on machine 1 and let it run on terminal 1. Then once its running setup replication from machine 1(use new terminal and let sysbench running on another terminal) to machine 2


# 27. ​AWS RDS Architecture Overview (In MySQL context), Usecase of RDS, Difference in RDS vs physical Databases, Features, Parameter Groups, Backups(snapshots), Multi-AZ, Failover, Replication


#### Usecase of RDS

- Scalability: RDS is designed to handle varying workloads, allowing to easily scale compute and storage resources up or down.
- Managed Service: It automates administrative tasks like infra provisioning, DB installation, patching, and backups, allowing to focus on application development.
- Cost-Effectiveness: You only pay for the resources you use, and RDS offers different instance types and pricing models (e.g., On-Demand, Reserved Instances) to optimize costs.

#### Difference between RDS vs. Physical Databases

- Physical Databases: Require manual management of the underlying infrastructure, including the server, operating system, and database software. This means you are responsible for everything from hardware failure to security patches.
- RDS: An RDS instance is a managed service. You don't have to worry about the underlying server or OS. AWS handles the maintenance, security, and availability of the database, providing a "hands-off" approach to database management.


#### Important Features

- Parameter Groups: A way to contain configuration values that are applied to DB instances. You can use these to manage settings like character sets, buffer sizes, and timeouts.
- Backups (Snapshots): RDS automatically creates and stores backups of your DB instance. You can also manually create snapshots at any time. These backups are stored in Amazon S3 and can be used to restore your database to a specific point in time.
- Multi-AZ Deployment: This provides enhanced availability and durability for your DB instance. When you create a Multi-AZ deployment, RDS automatically provisions and maintains a synchronous standby replica in a different Availability Zone (AZ). In the event of a failure, RDS automatically fails over to the standby.
- Failover: The automatic process of switching from the primary database instance to the standby replica in a Multi-AZ deployment. This happens seamlessly and with minimal downtime in case of an outage.
- Replication: RDS supports creating one or more read replicas from a source DB instance. Read replicas are asynchronous copies that are used to offload read traffic from the primary instance, improving the performance of read-heavy applications. This is a key component for scaling your application's read throughput.



# 28. ​Hands on RDS


# 29. ​Prepared state is pending (sync_binlog =1 crash recovery)


# 30. ​Locking in DB

Types of Locks
1. Shared Locks (Read Locks): Allows multiple transactions to read data simultaneously. Prevents other transactions from writing.
2. Exclusive Locks (Write Locks): Grants a single transaction exclusive access to data, preventing all other transactions from reading or writing it.

Locking Granularity
1. Table-Level: Locks the entire table. Reduces concurrency.
2. Row-Level: Locks only the specific rows being accessed. Provides the highest concurrency and is used by engines like InnoDB.





# Learning
1. Youtube Playlist for getting familiar with MySQL: https://www.youtube.com/playlist?list=PLd5sTGXltJ-l9PKT2Bynhg0Ou2uESOJiH
2. Innodb architecture : https://dev.mysql.com/doc/refman/8.0/en/innodb-architecture.html
3. Innodb memory architecture : https://dev.mysql.com/doc/refman/8.0/en/innodb-in-memory-structures.html
4. Innodb disk architecture : https://dev.mysql.com/doc/refman/8.0/en/innodb-on-disk-structures.html
