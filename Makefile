PYVENV_PREFIX=pipenv run 
db?=odoo
md?=$(md)
t?=$(t)
conf?=/etc/odoo-server.conf
path = ./custom/addons

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
        $(PYVENV_PREFIX) black custom
        $(PYVENV_PREFIX) isort custom

lint:
        $(PYVENV_PREFIX) flake8 custom

run:
        $(PYVENV_PREFIX) python3 odoo-server/odoo-bin --log-handler=odoo:$(l) -c $(conf) 

update:
        $(PYVENV_PREFIX) python3 odoo-server/odoo-bin -u $(md) -d $(db) -c $(conf)

shell:
        $(PYVENV_PREFIX) python3 odoo-server/odoo-bin shell -d $(db) --addons-path='$(path)' --log-handler=odoo:$(l)

test:
        $(PYVENV_PREFIX) python3 odoo-server/odoo-bin -d $(db) --addons-path='$(path)' --test-enable --stop-after-init --test-tags '$(t)'
