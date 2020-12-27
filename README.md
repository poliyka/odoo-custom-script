# Odoo 14.0 客製化安裝腳本說明

1. Make the script executable

```sh
sudo chmod +x odoo_install_custom.sh
```

2. Modify the parameters as you wish. In this case just show what different from [Reference](https://github.com/Yenthe666/InstallScript).
```sh
OE_USER="odoo" #Change your username
OE_FOLDER="odoo-project" #your project name

# Here I change default path
OE_HOME="/home/$OE_USER/$OE_FOLDER"
OE_HOME_EXT="/home/$OE_USER/$OE_FOLDER/odoo-server"

# Initialize Data
echo -e "* Force Remove old project conf"
sudo rm -f /etc/${OE_CONFIG}.conf

echo -e "* Stoping and Remove Odoo Service"
sudo su root -c "/etc/init.d/$OE_CONFIG stop"
sudo rm -f /etc/init.d/$OE_CONFIG

echo -e "* Create project folder"
sudo su $OE_USER -c "mkdir ~/$OE_FOLDER"

# Always start postgresql brfore create user
sudo /etc/init.d/postgresql start
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true
```

4. Execute the script
```sh
sudo ./odoo_install_custom.sh
```

3. Install wkhtmltopdf if you want to upgrade. =>
[Reference](https://computingforgeeks.com/install-wkhtmltopdf-on-ubuntu-debian-linux/)

4. Move `Pipfile` 、 `Pipfile.lock` 、 `Makefile` in your project folder.

5. I use `pipenv` with python3.8 and Odoo 14.0 requirements.
```sh
# In your project folder
pipenv install
```

6. Run server
```sh
make run
```

7. If you using `Visual Studio Code`. Move `.vscode` folder in your project and modify the `launch.json`, then you can press `F5` start with debug mode.
```sh
# Change odoo-project to your folder name of project
# Change "python": "/home/(your username)/...
# Change RhqrRy0p to your virtualenvs environment
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "odoo",
            "type": "python",
            "request": "launch",
            "python": "/home/odoo/.local/share/virtualenvs/odoo-project-RhqrRy0p/bin/python3.8",
            "program": "~/odoo-project/odoo-server/odoo-bin",
            "args": [
                "--syslog",
                "-c",
                "/etc/odoo-server.conf"
            ]
        }
    ]
}
```

---
### Congratulations all script done have fun!