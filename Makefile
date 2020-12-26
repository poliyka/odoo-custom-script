PYVENV_PREFIX=pipenv run
LOG_MODE=INFO
# Logging reference
# https://www.odoo.com/documentation/14.0/reference/cmdline.html
# https://odoo-development.readthedocs.io/en/latest/admin/log-handler.html#usefull-logs

format:
	$(PYVENV_PREFIX) black custom
	$(PYVENV_PREFIX) isort custom

lint:
	$(PYVENV_PREFIX) flake8 custom

run:
	$(PYVENV_PREFIX) python3 odoo-server/odoo-bin --syslog --log-handler :$(LOG_MODE) -c /etc/odoo-server.conf
