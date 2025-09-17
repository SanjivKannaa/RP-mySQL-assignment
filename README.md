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
GRANT REPLICATION SLAVE ON departments.* TO 'replica_user'@'<ip_address_of_slave_node>';
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





