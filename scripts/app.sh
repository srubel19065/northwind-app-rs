#!/bin/bash

sudo apt update && sudo apt upgrade -y

# Install Python 3.9
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update -y
sudo apt install -y python3.9 python3.9-venv python3.9-dev
sudo apt install -y python3-pip

cd ../app

python3.9 -m venv venv
source venv/bin/activate

pip install Flask==3.0.2 Waitress==3.0.0 Flask-SQLAlchemy==3.1.1 SQLAlchemy==2.0.27 PyMySQL==1.1.0 Jinja2==3.1.3 Flask-Waitress==0.0.1 cryptography

#export DB_CONNECTION_URI="mysql+pymysql://admin:password@172.31.62.79:3306/northwind"

waitress-serve --port=5000 northwind_web:app > waitress.log 2>&1 &


#!/bin/bash

# upgrade - ran
sudo apt-get update

# update - ran
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# install git - ran
sudo DEBIAN_FRONTEND=noninteractive apt-get install git -y

# install nginx - ran
sudo DEBIAN_FRONTEND=noninteractive apt-get install nginx -y

# enable nginx - ran
sudo systemctl enable nginx

# update nginx to redirect port 3000 to port 80 -
sudo sed -i "s@try_files \$uri \$uri/ =404;@proxy_pass http://127.0.0.1:5000;@" /etc/nginx/sites-available/default

# restart nginx - ran
sudo systemctl restart nginx

# Install Python 3.9 and set it as default
sudo apt-get install python3.9 -y
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1
sudo update-alternatives --config python3

# Install pip
sudo apt install python3-pip -y

# Waitress 3.0.0 - ran
sudo pip install waitress==3.0.0

# Flask 3.0.2 - ran
sudo pip install Flask==3.0.2

# Flask-sqlalchemy 3.0.2 - ran
sudo pip install Flask-SQLAlchemy==3.1.1

# SQLAlchemy 2.0.27 - ran
sudo pip install SQLAlchemy==2.0.27

# PyMySQL 1.1.0 - ran
sudo pip install pymysql==1.1.0

# Jinja 3.1.3 - ran
sudo pip install Jinja2==3.1.3

# Flask-Waitress 0.0.1 - ran
sudo pip install Flask-Waitress==0.0.1

# Install CFFI - ran
sudo pip install cffi

# make repo directory - ran
mkdir repo

# cd into repo - ran
cd repo/

# git clone repo
git clone https://github.com/srubel19065/northwind-app-rs.git

# cd into northwind_python_app
cd northwind_python_app-main/

# set FLASK_APP environment variable
export FLASK_APP=northwind_web.py

# set DB var export DB_CONNECTION_URI='mysql+pymysql://<user>:<password>@<ip-of-db>:3306/northwind'
export DB_CONNECTION_URI='mysql+pymysql://ajhar:password@63.33.55.80:3306/northwind'

# run waitress
waitress-serve --port=5000 northwind_web:app