#!/bin/bash
################################################################################
# Script for installing Odoo on Ubuntu 14.04, 15.04, 16.04 and 18.04 (could be used for other version too)
# Author: Yenthe Van Ginneken
#-------------------------------------------------------------------------------
# This script will install Odoo on your Ubuntu 16.04 server. It can install multiple Odoo instances
# in one Ubuntu because of the different xmlrpc_ports
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano odoo-install.sh
# Place this content in it and then make the file executable:
# sudo chmod +x odoo-install.sh
# Execute the script to install Odoo:
# ./odoo-install
################################################################################

OE_USER="odoo"
OE_PROJECT_NAME="odoo-project"

OE_HOME="/home/$OE_USER"
OE_ODOO_PATH="/home/$OE_USER/odoo-server"
OE_PROJECT_PATH="$OE_HOME/${OE_PROJECT_NAME}"
# Split Addons and Odoo as you wish (default at same folder)
OE_ADDONS="${OE_PROJECT_PATH}/addons"
# Install by pipenv-venv
INSTALL_BY_PIPENV_VENV="True"
# The default port where this Odoo instance will run under (provided you use the command -c in the terminal)
# Set to true if you want to install it, false if you don't need it or have it already installed.
INSTALL_WKHTMLTOPDF="True"
# Set the default Odoo port (you still have to use -c /etc/odoo-server.conf for example to use this.)
OE_PORT="8069"
# Choose the Odoo version which you want to install. For example: 14.0, 13.0, 12.0, 11.0 or saas-18. When using 'master' the master version will be installed.
# IMPORTANT! This script contains extra libraries that are specifically needed for Odoo 14.0
OE_VERSION="14.0"
# Set this to True if you want to install the Odoo enterprise version!
IS_ENTERPRISE="False"
# Set this to True if you want to install Nginx!
INSTALL_NGINX="False"
# Set the superadmin password - if GENERATE_RANDOM_PASSWORD is set to "True" we will automatically generate a random password, otherwise we use this one
OE_SUPERADMIN="admin"
# Set to "True" to generate a random password, "False" to use the variable in OE_SUPERADMIN
GENERATE_RANDOM_PASSWORD="False"
OE_CONFIG="${OE_PROJECT_NAME}-server"
# Set the website name
WEBSITE_NAME="_"
# Set the default Odoo longpolling port (you still have to use -c /etc/odoo-server.conf for example to use this.)
LONGPOLLING_PORT="8072"
# Set to "True" to install certbot and have ssl enabled, "False" to use http
ENABLE_SSL="True"
# Provide Email to register ssl certificate
ADMIN_EMAIL="odoo@example.com"

#--------------------------------------------------
# Echo Color
#--------------------------------------------------
RED="\033[0;31m"
GREEN="\033[0;32m"
ORANGE="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

#--------------------------------------------------
# Check OE_ODOO_PATH
#--------------------------------------------------
if [[ -d "${OE_ODOO_PATH}" ]]; then
  echo -e "${ORANGE}${OE_ODOO_PATH} already exists.${NC}"
  read -p "Do you want to continue(N/y)?" answer
  case ${answer:0:1} in
      y|Y )
      ;;
      * )
          exit 1
      ;;
  esac
fi

#--------------------------------------------------
# Check OE OE_PROJECT_PATH
#--------------------------------------------------
if [[ -d "${OE_PROJECT_PATH}" ]]; then
  echo -e "${RED}${OE_PROJECT_PATH} already exists.${NC}"
  exit 1
fi

#--------------------------------------------------
# Initialize Data
#--------------------------------------------------
echo -e "${CYAN}* Force Remove old project conf${NC}"
sudo rm -f /etc/${OE_CONFIG}.conf

echo -e "${CYAN}* Stoping and Remove Odoo Service${NC}"
sudo su root -c "/etc/init.d/$OE_CONFIG stop"
sudo rm -f /etc/init.d/$OE_CONFIG

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n${BLUE}==== Update Server ====${NC}"
sudo apt-get update
sudo apt-get upgrade -y

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n${BLUE}==== Install PostgreSQL Server ====${NC}"
sudo apt-get install postgresql postgresql-contrib -y

sudo /etc/init.d/postgresql start
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n${BLUE}--- Installing Python 3 + pip3 --${NC}"
sudo apt-get install git python3 python3-pip build-essential wget make vim python3-dev libpq-dev -y
sudo apt-get install python3-venv python3-wheel libxslt-dev libzip-dev libldap2-dev libsasl2-dev -y
sudo apt-get install python3-setuptools node-less libpng12-0 libjpeg-dev gdebi python3-virtualenv -y

if [ $INSTALL_BY_PIPENV_VENV = "False" ]; then
  echo -e "\n${BLUE}==== Install python packages/requirements ====${NC}"
  sudo -H pip3 install -r https://github.com/odoo/odoo/raw/${OE_VERSION}/requirements.txt
  sudo pip3 install PyPDF2
fi
sudo pip3 install pipenv

echo -e "\n${BLUE}==== Installing nodeJS NPM and rtlcss for LTR support ====${NC}"
sudo apt-get install nodejs npm -y
sudo npm install -g rtlcss

#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
  echo -e "\n${BLUE}==== Install wkhtml and place shortcuts on correct place for ODOO 14 ====${NC}"
  sudo add-apt-repository ppa:linuxuprising/libpng12 << 'EOF'
\n
EOF
  sudo apt update
  sudo apt install libpng12-0
else
  echo "Wkhtmltopdf isn't installed due to the choice of the user!"
fi

echo -e "\n${BLUE}==== Create ODOO system user ====${NC}"
sudo adduser --system --quiet --shell=/bin/bash --home=/home/$OE_USER --gecos 'ODOO' --group $OE_USER
#The user should also be added to the sudo'ers group.
sudo adduser $OE_USER sudo

echo -e "${CYAN}* Create project folder${NC}"
sudo su $OE_USER -c "mkdir ~/$OE_PROJECT_NAME"

echo -e "\n${BLUE}==== Create Log directory ====${NC}"
sudo mkdir /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n${BLUE}==== Installing ODOO Server ====${NC}"
sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_ODOO_PATH/

if [ $IS_ENTERPRISE = "True" ]; then
    # Odoo Enterprise install!
    sudo pip3 install psycopg2-binary pdfminer.six
    echo -e "\n${BLUE}--- Create symlink for node${NC}"
    sudo ln -s /usr/bin/nodejs /usr/bin/node
    sudo su $OE_USER -p "mkdir $OE_HOME/enterprise/addons"

    GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    while [[ $GITHUB_RESPONSE == *"Authentication"* ]]; do
        echo "------------------------WARNING------------------------------"
        echo "Your authentication with Github has failed! Please try again."
        printf "In order to clone and install the Odoo enterprise version you \nneed to be an offical Odoo partner and you need access to\nhttp://github.com/odoo/enterprise.\n"
        echo "TIP: Press ctrl+c to stop this script."
        echo "-------------------------------------------------------------"
        echo " "
        GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    done

    echo -e "\n${BLUE}==== Added Enterprise code under $OE_HOME/enterprise/addons ====${NC}"
    echo -e "\n${BLUE}==== Installing Enterprise specific libraries ====${NC}"
    sudo -H pip3 install num2words ofxparse dbfread ebaysdk firebase_admin pyOpenSSL
    sudo npm install -g less
    sudo npm install -g less-plugin-clean-css
fi

echo -e "\n${BLUE}==== Create custom module directory ====${NC}"
sudo su $OE_USER -c "mkdir -p $OE_ADDONS"

if [ $INSTALL_BY_PIPENV_VENV = "True" ]; then
  echo -e "\n${BLUE}==== Create Makefile ====${NC}"
  cat <<EOF > $OE_PROJECT_PATH/Makefile
PYVENV_PREFIX=pipenv run
ODOO_SERVER=${OE_ODOO_PATH}
ADDONS_PATH=${OE_ADDONS}
db?=odoo
md?=\$(md)
t?=\$(t)
conf?=/etc/${OE_CONFIG}.conf

l=INFO
# Log levels
# CRITICAL
# ERROR
# WARNING
# INFO
# DEBUG
# NOTSET

# Logging reference
# https://www.odoo.com/documentation/14.0/reference/cmdline.html
# https://odoo-development.readthedocs.io/en/latest/admin/log-handler.html#usefull-logs

format:
	\$(PYVENV_PREFIX) black custom
	\$(PYVENV_PREFIX) isort custom

lint:
	\$(PYVENV_PREFIX) flake8 custom

run:
	\$(PYVENV_PREFIX) python3 \$(ODOO_SERVER)/odoo-bin --log-handler=odoo:\$(l) -c \$(conf)

update:
	\$(PYVENV_PREFIX) python3 \$(ODOO_SERVER)/odoo-bin -u \$(md) -d \$(db) -c \$(conf)

shell:
	\$(PYVENV_PREFIX) python3 \$(ODOO_SERVER)/odoo-bin shell -d \$(db) --addons-path='\$(ADDONS_PATH)' --log-handler=odoo:\$(l)

test:
	\$(PYVENV_PREFIX) python3 \$(ODOO_SERVER)/odoo-bin -d \$(db) --addons-path='\$(ADDONS_PATH)' --test-enable --stop-after-init --test-tags '\$(t)'

EOF

  echo -e "\n${BLUE}==== Install pipenv env ====${NC}"
  wget https://github.com/odoo/odoo/raw/${OE_VERSION}/requirements.txt
  sed -i '/pypiwin32/d' ./requirements.txt
  sed -i -e '$aPyPDF2==1.26.0' ./requirements.txt
  sudo su $OE_USER -c "cp requirements.txt ${OE_PROJECT_PATH}"
  sudo su $OE_USER -c "cp Pipfile ${OE_PROJECT_PATH}"
  sudo su $OE_USER -c "cd ${OE_PROJECT_PATH}; pipenv install -r ${OE_PROJECT_PATH}/requirements.txt"
fi

echo -e "\n${BLUE}==== Setting permissions on home folder ====${NC}"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "${CYAN}* Create server config file${NC}"


sudo touch /etc/${OE_CONFIG}.conf
echo -e "${CYAN}* Creating server config file${NC}"
sudo su root -c "printf '[options] \n; This is the password that allows database operations:\n' >> /etc/${OE_CONFIG}.conf"
if [ $GENERATE_RANDOM_PASSWORD = "True" ]; then
    echo -e "${CYAN}* Generating random admin password${NC}"
    OE_SUPERADMIN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
fi
sudo su root -c "printf 'admin_passwd = ${OE_SUPERADMIN}\n' >> /etc/${OE_CONFIG}.conf"
if [ $OE_VERSION > "11.0" ];then
    sudo su root -c "printf 'http_port = ${OE_PORT}\n' >> /etc/${OE_CONFIG}.conf"
else
    sudo su root -c "printf 'xmlrpc_port = ${OE_PORT}\n' >> /etc/${OE_CONFIG}.conf"
fi
sudo su root -c "printf ';logfile = /var/log/${OE_USER}/${OE_CONFIG}.log\n' >> /etc/${OE_CONFIG}.conf"

if [ $IS_ENTERPRISE = "True" ]; then
    sudo su root -c "printf 'addons_path=${OE_HOME}/enterprise/addons,${OE_ODOO_PATH}/addons\n' >> /etc/${OE_CONFIG}.conf"
else
    sudo su root -c "printf 'addons_path=${OE_ODOO_PATH}/addons,${OE_ADDONS}\n' >> /etc/${OE_CONFIG}.conf"
fi
sudo chown $OE_USER:$OE_USER /etc/${OE_CONFIG}.conf
sudo chmod 640 /etc/${OE_CONFIG}.conf

#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------

if [ $INSTALL_BY_PIPENV_VENV = "False" ]; then
echo -e "${CYAN}* Create init file${NC}"
cat <<EOF > ~/$OE_CONFIG
#!/bin/sh
### BEGIN INIT INFO
# Provides: $OE_CONFIG
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Should-Start: \$network
# Should-Stop: \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Enterprise Business Applications
# Description: ODOO Business Applications
### END INIT INFO
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin
DAEMON=$OE_ODOO_PATH/odoo-bin
NAME=$OE_CONFIG
DESC=$OE_CONFIG
# Specify the user name (Default: odoo).
USER=$OE_USER
# Specify an alternate config file (Default: /etc/openerp-server.conf).
CONFIGFILE="/etc/${OE_CONFIG}.conf"
# pidfile
PIDFILE=/var/run/\${NAME}.pid
# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c \$CONFIGFILE"
[ -x \$DAEMON ] || exit 0
[ -f \$CONFIGFILE ] || exit 0
checkpid() {
[ -f \$PIDFILE ] || return 1
pid=\`cat \$PIDFILE\`
[ -d /proc/\$pid ] && return 0
return 1
}
case "\${1}" in
start)
echo -n "Starting \${DESC}: "
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
stop)
echo -n "Stopping \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
echo "\${NAME}."
;;
restart|force-reload)
echo -n "Restarting \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
sleep 1
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
*)
N=/etc/init.d/\$NAME
echo "Usage: \$NAME {start|stop|restart|force-reload}" >&2
exit 1
;;
esac
exit 0
EOF
fi

if [ $INSTALL_BY_PIPENV_VENV = "True" ]; then
echo -e "${CYAN}* Create init file by pipenv venv${NC}"
PYTHON_PATH=$(sudo su $OE_USER -c "cd ${OE_PROJECT_PATH}; pipenv --venv")

cat <<EOF > ~/$OE_CONFIG
#!/bin/sh
### BEGIN INIT INFO
# Provides: $OE_CONFIG
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Should-Start: \$network
# Should-Stop: \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Enterprise Business Applications
# Description: ODOO Business Applications
### END INIT INFO
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin
PYTHON_PATH=$PYTHON_PATH/bin/python3
DAEMON=$OE_ODOO_PATH/odoo-bin
NAME=$OE_CONFIG
DESC=$OE_CONFIG
# Specify the user name (Default: odoo).
USER=$OE_USER
# Specify an alternate config file (Default: /etc/openerp-server.conf).
CONFIGFILE="/etc/${OE_CONFIG}.conf"
# pidfile
PIDFILE=/var/run/\${NAME}.pid
# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c \$CONFIGFILE"
[ -x \$DAEMON ] || exit 0
[ -f \$CONFIGFILE ] || exit 0
checkpid() {
[ -f \$PIDFILE ] || return 1
pid=\`cat \$PIDFILE\`
[ -d /proc/\$pid ] && return 0
return 1
}
case "\${1}" in
start)
echo -n "Starting \${DESC}: "
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$PYTHON_PATH \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
stop)
echo -n "Stopping \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
echo "\${NAME}."
;;
restart|force-reload)
echo -n "Restarting \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
sleep 1
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$PYTHON_PATH \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
*)
N=/etc/init.d/\$NAME
echo "Usage: \$NAME {start|stop|restart|force-reload}" >&2
exit 1
;;
esac
exit 0
EOF
fi

echo -e "${CYAN}* Security Init File${NC}"
sudo mv ~/$OE_CONFIG /etc/init.d/$OE_CONFIG
sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG

echo -e "${CYAN}* Start ODOO on Startup${NC}"
sudo update-rc.d $OE_CONFIG defaults

#--------------------------------------------------
# Install Nginx if needed
#--------------------------------------------------
if [ $INSTALL_NGINX = "True" ]; then
  echo -e "\n${BLUE}==== Installing and setting up Nginx ====${NC}"
  sudo apt install nginx -y
  cat <<EOF > ~/odoo
  server {
  listen 80;

  # set proper server name after domain set
  server_name $WEBSITE_NAME;
  SERVER
  # Add Headers for odoo proxy mode
  proxy_set_header X-Forwarded-Host \$host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_set_header X-Real-IP \$remote_addr;
  add_header X-Frame-Options "SAMEORIGIN";
  add_header X-XSS-Protection "1; mode=block";
  proxy_set_header X-Client-IP \$remote_addr;
  proxy_set_header HTTP_X_FORWARDED_HOST \$remote_addr;

  #   odoo    log files
  access_log  /var/log/nginx/$OE_USER-access.log;
  error_log       /var/log/nginx/$OE_USER-error.log;

  #   increase    proxy   buffer  size
  proxy_buffers   16  64k;
  proxy_buffer_size   128k;

  proxy_read_timeout 900s;
  proxy_connect_timeout 900s;
  proxy_send_timeout 900s;

  #   force   timeouts    if  the backend dies
  proxy_next_upstream error   timeout invalid_header  http_500    http_502
  http_503;

  types {
  text/less less;
  text/scss scss;
  }

  #   enable  data    compression
  gzip    on;
  gzip_min_length 1100;
  gzip_buffers    4   32k;
  gzip_types  text/css text/less text/plain text/xml application/xml application/json application/javascript application/pdf image/jpeg image/png;
  gzip_vary   on;
  client_header_buffer_size 4k;
  large_client_header_buffers 4 64k;
  client_max_body_size 0;

  location / {
  proxy_pass    http://127.0.0.1:$OE_PORT;
  # by default, do not forward anything
  proxy_redirect off;
  }

  location /longpolling {
  proxy_pass http://127.0.0.1:$LONGPOLLING_PORT;
  }
  location ~* .(js|css|png|jpg|jpeg|gif|ico)$ {
  expires 2d;
  proxy_pass http://127.0.0.1:$OE_PORT;
  add_header Cache-Control "public, no-transform";
  }
  # cache some static data in memory for 60mins.
  location ~ /[a-zA-Z0-9_-]*/static/ {
  proxy_cache_valid 200 302 60m;
  proxy_cache_valid 404      1m;
  proxy_buffering    on;
  expires 864000;
  proxy_pass    http://127.0.0.1:$OE_PORT;
  }
  }
EOF

  sudo mv ~/odoo /etc/nginx/sites-available/
  sudo ln -s /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/odoo
  sudo rm /etc/nginx/sites-enabled/default
  sudo service nginx reload
  sudo su root -c "printf 'proxy_mode = True\n' >> /etc/${OE_CONFIG}.conf"
  echo -e "${GREEN}Done! The Nginx server is up and running. Configuration can be found at${NC} ${ORANGE}/etc/nginx/sites-available/odoo${NC}"
else
  echo -e "${GREEN}Nginx isn't installed due to choice of the user!${NC}"
fi

#--------------------------------------------------
# Enable ssl with certbot
#--------------------------------------------------

if [ $INSTALL_NGINX = "True" ] && [ $ENABLE_SSL = "True" ] && [ $ADMIN_EMAIL != "odoo@example.com" ]  && [ $WEBSITE_NAME != "_" ];then
  sudo add-apt-repository ppa:certbot/certbot -y && sudo apt-get update -y
  sudo apt-get install python3-certbot-nginx -y
  sudo certbot --nginx -d $WEBSITE_NAME --noninteractive --agree-tos --email $ADMIN_EMAIL --redirect
  sudo service nginx reload
  echo -e "${GREEN}SSL/HTTPS is enabled!${NC}"
else
  echo -e "${GREEN}SSL/HTTPS isn't enabled due to choice of the user or because of a misconfiguration!${NC}"
fi

echo -e "${CYAN}* Starting Odoo Service${NC}"
sudo su root -c "/etc/init.d/$OE_CONFIG start"
echo -e "${GREEN} -----------------------------------------------------------${NC}"
echo -e "${GREEN} Done! The Odoo server is up and running. Specifications:${NC}"
echo -e "${GREEN} Port:${NC} ${ORANGE}$OE_PORT${NC}"
echo -e "${GREEN} User service:${NC} ${ORANGE}$OE_USER${NC}"
echo -e "${GREEN} Configuraton file location:${NC} ${ORANGE}/etc/${OE_CONFIG}.conf${NC}"
echo -e "${GREEN} Logfile location:${NC} ${ORANGE}/var/log/$OE_USER${NC}"
echo -e "${GREEN} User PostgreSQL:${NC} ${ORANGE}$OE_USER${NC}"
echo -e "${GREEN} Odoo location:${NC} ${ORANGE}$OE_ODOO_PATH${NC}"
echo -e "${GREEN} Addons folder:${NC} ${ORANGE}${OE_ADDONS}${NC}"
echo -e "${GREEN} Password superadmin (database):${NC} ${ORANGE}$OE_SUPERADMIN${NC}"
echo -e "${GREEN} Start Odoo service: sudo service${NC} ${ORANGE}$OE_CONFIG start${NC}"
echo -e "${GREEN} Stop Odoo service: sudo service${NC} ${ORANGE}$OE_CONFIG stop${NC}"
echo -e "${GREEN} Restart Odoo service: sudo service${NC} ${ORANGE}$OE_CONFIG restart${NC}"
if [ $INSTALL_NGINX = "True" ]; then
  echo -e "${GREEN}Nginx configuration file:${NC} ${ORANGE}/etc/nginx/sites-available/odoo${NC}"
fi
echo -e "${GREEN}-----------------------------------------------------------${NC}"
