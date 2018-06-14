#!/bin/sh
rm -rf /var/run/apache2/*.pid
rm -rf /var/run/carbon/*.pid
rm -rf /var/run/grafana/*.pid
rm -rf /var/log/grafana/xorm.log
exec "$@"

