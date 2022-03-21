# Odoo 14.0 客製化安裝腳本說明

This is fork form [Yenthe666/InstallScript](https://github.com/Yenthe666/InstallScript)

1. Make the script executable

```sh
sudo chmod +x install.sh
```

2. Modify the parameters as you wish.
```sh
OE_USER="odoo" #your system username
OE_PROJECT_NAME="odoo-project" #your project name
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
```json
# Replace odoo-project by your folder name of project
# Replace "python": "/home/(your username)/...
# Replace RhqrRy0p by your virtualenvs environment
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "odoo",
            "type": "python",
            "request": "launch",
            "python": "/home/{odoo}/.local/share/virtualenvs/{odoo-project-RhqrRy0p}/bin/python3.8",
            "program": "~/{odoo-server}/odoo-bin",
            "args": [
                "--syslog",
                "-c",
                "/etc/{odoo-server}.conf"
            ]
        }
    ]
}
```

---
### Congratulations all script done have fun!
