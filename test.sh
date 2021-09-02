#!/bin/bash
OE_USER="poliyka"
OE_FOLDER="odoo-project"
OE_HOME="/home/$OE_USER/$OE_FOLDER"
INSTALL_BY_PIPENV_VENV="True"
OE_VERSION="14.0"

if [ $INSTALL_BY_PIPENV_VENV = "False" ]; then
  echo -e "\n---- Install python packages/requirements ----"
fi

sudo su $OE_USER -c "cp /home/${OE_USER}/odoo-custom-script/Makefile ${OE_HOME}"
if [ $INSTALL_BY_PIPENV_VENV = "True" ]; then
  echo -e "\n---- Install pipenv env -----"
  wget https://github.com/odoo/odoo/raw/${OE_VERSION}/requirements.txt -P $OE_HOME
  sudo su $OE_USER -c "cd ${OE_HOME}; pipenv install -r requirements.txt"
fi

