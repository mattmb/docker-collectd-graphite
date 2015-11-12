#
# Default credentials: "admin:admin"
#
# References:
#	https://www.digitalocean.com/community/tutorials/how-to-install-and-use-graphite-on-an-ubuntu-14-04-server
#	https://www.digitalocean.com/community/tutorials/how-to-configure-collectd-to-gather-system-metrics-for-graphite-on-ubuntu-14-04
#	https://www.digitalocean.com/community/tutorials/how-to-configure-statsd-to-collect-arbitrary-stats-for-graphite-on-ubuntu-14-04
#
#	Initialize Django database:
#	http://obfuscurity.com/2012/04/Unhelpful-Graphite-Tip-4
#	
FROM ubuntu:14.04

RUN apt-get update && \
    apt-get install -y graphite-web graphite-carbon apache2 libapache2-mod-wsgi supervisor collectd collectd-utils git nodejs

RUN adduser --system --group --no-create-home collectd && \
    adduser --system --group --no-create-home statsd

# Install StatsD
RUN mkdir -p /src && \
    git clone https://github.com/etsy/statsd.git /src/statsd && \
    cd /src/statsd &&\
    git checkout v0.7.2

# Confiure StatsD
COPY statsd/config.js /src/statsd/config.js

# Configure graphite
COPY graphite/local_settings.py /etc/graphite/local_settings.py
COPY graphite/graphite-carbon /etc/default/graphite-carbon
COPY graphite/carbon.conf /etc/carbon/carbon.conf
COPY graphite/storage-schemas.conf /etc/carbon/storage-schemas.conf
COPY graphite/storage-aggregation.conf /etc/carbon/storage-aggregation.conf
COPY graphite/database.json /root/database.json
RUN  python /usr/lib/python2.7/dist-packages/graphite/manage.py syncdb --noinput && \ 
     python /usr/lib/python2.7/dist-packages/graphite/manage.py loaddata /root/database.json

#Carbon runs as www-data and needs write permission
#Graphite runs as _graphite
RUN   chown -R _graphite:www-data /var/lib/graphite && \ 
      chmod -R ugo+w /var/lib/graphite

RUN a2dissite 000-default && \
    cp /usr/share/graphite-web/apache2-graphite.conf /etc/apache2/sites-available && \
    a2ensite apache2-graphite

#Configure collectd
COPY collectd/collectd.conf /etc/collectd/collectd.conf

#Configure supervisor 
COPY supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisor

RUN mkdir /var/log/collectd && \
    chown -R collectd /var/log/collectd && \
#    mkdir /var/lib/collectd && \
    chown -R collectd /var/lib/collectd

VOLUME ["/var/lib/graphite/"]

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]