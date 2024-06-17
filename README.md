# Northwind App Deployment Project
**Task: Deploy the Northwind App in a 2-tier deployment in the most efficient way possible. The app has a homepage, a page that has all customer data and a page that add new customers to that list. The app runs on Python 3.9 and uses PIP to install dependencies and the database uses MySQL to populate the data. We decided to create automated scripts for both the running of the app and the database alongside a Jenkins setup which would deploy changes using CICD**

## Creating Instances using AWS
1. Launch Instance on AWS
2. App Instance Configuration:
   1. `Name`
   2. `Image` - Ubuntu 20.04
   3. `Type` - t2.micro
   4. `Security Group` - Create a security group and open ports for SSH:22, HTTP:80, TCP:5000(port to run the app)
3. Database Instance Configuration:
   1. `Name`
   2. `Image` - Ubuntu 20.04
   3. `Type` - t2.micro
   4. `Security Group` - Create a group and open port for SSH:22, TCP:3000(port that runs the database)

## Manual Deployment of Database
Before creating the script, we manually deployed to figure out which steps would be needed:
1. `sudo apt update && sudo apt upgrade -y` = update and upgrade
2. `sudo apt install mysql-server` = this install MySQL server
3. `sudo mysql` = enter the mysql monitor where you can query and create databases, users etc

![alt text](img/image7.png)

### Within the mysql monitor we needed to create the database and give it access permissions:
   1. `CREATE DATABASE northwind;` = creates the database
   2. `CREATE USER '<USER>'@'%' IDENTIFIED BY '<PASSWORD>';` = creates user with name and password associated to it
      1. It also needs an 'location' assigned to it with at first using the ip address of the app however that didnt work. We then switched to using '%' which means it can be accessed through anywhere 
   3. `GRANT ALL PRIVILEGES ON northwind.* TO '<USER>'@'%';` = granting the user permissions to the database
   4. `FLUSH PRIVILEGES`; = reload and put the permissions into effect
   5. `EXIT;` = exit the monitor as the database has now been created
### Populating the database 
1. `git clone <repo link> repo` = within the repo there is a mysql database which is what we will use to populate
2. `cd repo/app`
3. `mv northwind_sql.sql ~` = move the sql folder to the home
4. `cd ~` = cd back into home 
5. `rm -rf repo` = we are deleting the repo in total without the sql as the repo folder being in this instance is unnecessary
6. `sudo mysql northwind < northwind_sql.sql` = this imports/populates the data

### Configuring the Bind Ip
1. `sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf` = navigate and edit the config file which has the bind ip address set as 127.0.0.1, change it to 0.0.0.0 which means to allow access from anywhere.
   -   This is what allows listening of of incoming connections
2. `sudo systemctl restart mysql` = after changing the bind ip, we need to restart mysql so it enables the change

## Manual Deployment of App
Before creating the script, we manually deployed to figure out which steps would be needed:
### Installing Python and Pip
1. `sudo apt update && sudo apt upgrade` = update and upgrade
2. `sudo apt install -y software-properties-common` = install common software properties
3. `sudo add-apt-repository ppa:deadsnakes/ppa` = this adds the repo that has packages of the most recent python version and is added to the list of software sources
4. `sudo apt update` = updates with the repo just being added
5. `sudo apt install -y python3.9 python3.9-venv python3.9-dev` = install python 3.9 which is the version that we require alongside its virtual environment 
6. `sudo apt install -y python3-pip` = installs pip which is python package installer
### Installing all dependencies
1. `git clone <github clone https link> repo` = git clones the repo that contains the app and renames it to 'repo'
2. `cd repo/app` = navigating to the app folder
3.  `python3.9 -m venv <venv name>` = creating a Python 3.9 virtual environment which we will use to install all dependencies and run the app, naming the virtual environment too
4. `source venv/bin/activate` = activate and enter into the 'venv'
5. `pip install Flask==3.0.2 Waitress==3.0.0 Flask-SQLAlchemy==3.1.1 SQLAlchemy==2.0.27 PyMySQL==1.1.0 Jinja2==3.1.3 Flask-Waitress==0.0.1` = using pip to install all the packages and dependencies that the app needs to run
6. `sudo apt update` = update the instance with whats been installed

![alt text](img/image2.png)

### Connecting the app to the database and running app
1. `export DB_CONNECTION_URI="mysql+pymysql://admin:password@DB_PRIVATE_IP:3306/northwind"` = we need the app to recognise the database:
    1.  Creating a environment variable that stores the private ip of the database alongside the port needed for it to be accessed
    2.  We store a connection string
    3.  We are providing the user account and password that is created within the database as a way to authenticate the database
2.  `waitress-serve --port=5000 northwind_web:app` = waitress runs the app on port 5000 and should be available upon entering the app public ip address followed by :5000

![alt text](img/image3.png)

## Automating the app deployment using a Script
```
#!/bin/bash

sudo apt update && sudo apt upgrade -y

# Install Python 3.9
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update -y
sudo apt install -y python3.9 python3.9-venv python3.9-dev
sudo apt install -y python3-pip

cd ../app

# create python3.9 virtual environment and enter it
python3.9 -m venv venv
source venv/bin/activate

# install all dependencies using pip
pip install Flask==3.0.2 Waitress==3.0.0 Flask-SQLAlchemy==3.1.1 SQLAlchemy==2.0.27 PyMySQL==1.1.0 Jinja2==3.1.3 Flask-Waitress==0.0.1 cryptography

# create connection string
export DB_CONNECTION_URI="mysql+pymysql://admin:password@172.31.62.79:3306/northwind"

# run app using waitress and run in the background
waitress-serve --port=5000 northwind_web:app > waitress.log 2>&1 &
```
## Automating database deployment using a Script
```
#!/bin/bash

sudo apt update && sudo apt upgrade -y

# install MySQL server
sudo apt-get install mysql-server -y

# creating database with a user and its permissions
sudo mysql <<EOF
CREATE DATABASE northwind;
CREATE USER 'admin'@'%' IDENTIFIED BY '<PASSWORD>>';
GRANT ALL PRIVILEGES ON northwind.* TO 'admin'@'%';
FLUSH PRIVILEGES;
EOF

# populate the database
cd ../app
sudo mysql northwind < northwind_sql.sql

# Change the bind address to 0.0.0.0
sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf

sudo systemctl restart mysql
```
## Jenkins for CICD 
**Task: We need to setup jenkins for CICD, when code changes are made we need it to automate and test and make the changes on the app. This uses 3 jobs:**
### Job1: CI Testing
1. Create dev branch on gitbash/vsc
   - `git branch <name>`
   - `git checkout <branchname>` = switches to branch
2. On Jenkins, create a job
3. `Discard old builds` = 3 max builds
4. `Git project` = add your github that will be used HTTPS URL
5. `Source Code Management` - Add SSH URL of github with its SSH key which needs to match
   - specify the dev branch
6. `Build` = add the script which tests the code changes:
```
# cd into the app folder
cd app
# install pytest (pythons code tester)
python3 -m pip install pytest
# run the test script
python3 tests/test_northwind_app.py
```
![alt text](img/image4.png)

   - Note: Ensure to SSH into the Jenkins instance to install Pip.

      ![alt text](img/image6.png)

7. *When Job 2 is created, it will be added in 'Post-build Actions: Build other projects'*

### Job2: Merge the branch to the main
1. Create Job used to test the code within the dev branch
2. `Discard old builds` - 3 max builds
3. `Git project` - add your github that will be used HTTPS URL
4. `Source Code Management` - Add SSH URL of github with its SSH key which needs to match: specify the dev branch
5. `Post Build Action`
    1. Git Publisher - This will merge the builds, select Push only if build succeeds and merge results
    2. Add branches - main/origin as this is where we want changes from dev to push to and will be merged to
6. *When Job3 is created, it will be added in 'Post-build Actions: Build other projects*

### Job3: Continuous Deployment
1. Create a job that will be used to deploy the do CD
2. `Discard old builds` - 3 max builds
3. `Git project` - add your github that will be used HTTPS URL
4. `Source Code Management` - Add SSH URL of github with its SSH key which needs to match: Specify that it is the main branch that we will be using
5. `Build Environment` - Add 'SSH Agent' - this will be the ssh key linked to the aws instance as we need an entry between jenkins and when we run the scripts that key will be used to give authentication
6. `Build` - Shell Script
```
# copying the app and scripts folder from jenkins workspace into the instance and without the need to user intervention
rsync -avz -e "ssh -o StrictHostKeyChecking=no" app ubuntu@34.245.159.132:/home/ubuntu/
rsync -avz -e "ssh -o StrictHostKeyChecking=no" scripts ubuntu@34.245.159.132:/home/ubuntu/

# ssh into the instance
ssh -o "StrictHostKeyChecking=no" ubuntu@34.245.159.132 <<EOF
    # cd into the scripts folder
    cd /home/ubuntu/scripts
    # give the app script the correct execute permissions
    chmod +x app.sh
    # Kill process on port 5000
    lsof -t -i :5000 | xargs kill
    # run the app
    ./app.sh
EOF
```
![alt text](img/image5.png)

Results:

![alt text](img/image.png)

**Now if a code change is made on the dev branch, it will be tested and if successful, merged with the main branch. The new changes will be copied onto the instance and automatically run the app for it to still be running**

Example:

![alt text](img/image2.5.png)<br>
*In this example, the index.html was configured to make changes to the front page.*