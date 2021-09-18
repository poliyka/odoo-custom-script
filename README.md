# Odoo 14.0 客製化安裝腳本說明

This is fork form [Yenthe666/InstallScript](https://github.com/Yenthe666/InstallScript)

1. Make the script executable

```sh
sudo chmod +x odoo_install_custom.sh
```

2. Modify the parameters as you wish.
```sh
OE_USER="odoo" #Change your username
OE_FOLDER="odoo-project" #your project name
OE_CONFIG="${OE_FOLDER}-server"
```

3. Execute the script
```sh
sudo ./odoo_install_custom.sh
```

4. Install wkhtmltopdf if you want to upgrade. =>
[Reference](https://computingforgeeks.com/install-wkhtmltopdf-on-ubuntu-debian-linux/)

5. Run server
```sh
make run
```

6. If you using `Visual Studio Code`. Move `.vscode` folder in your project and modify the `launch.json`, then you can press `F5` start with debug mode.
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
