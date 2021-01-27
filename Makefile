PYVENV_PREFIX=pipenv run
db?=odoo
md?=$(md)
conf?=/etc/odoo-server.conf
path = ./custom/addons
# Logging reference
# https://www.odoo.com/documentation/14.0/reference/cmdline.html
# https://odoo-development.readthedocs.io/en/latest/admin/log-handler.html#usefull-logs

format:
	$(PYVENV_PREFIX) black custom
	$(PYVENV_PREFIX) isort custom

lint:
	$(PYVENV_PREFIX) flake8 custom

run:
	$(PYVENV_PREFIX) python3 odoo-server/odoo-bin -c $(conf)

migrate:
	$(PYVENV_PREFIX) python3 odoo-server/odoo-bin -u $(md) -d $(db) -c $(conf)

shell:
	$(PYVENV_PREFIX) python3 odoo-server/odoo-bin shell -d $(db) --addons-path='$(path)'
