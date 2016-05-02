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

ENV APACHE_RUN_USER=_graphite
ENV APACHE_RUN_GROUP=_graphite

RUN apt-get update && \
    apt-get install -y graphite-web graphite-carbon apache2 libapache2-mod-wsgi supervisor collectd collectd-utils git nodejs wget

################################
# Install StatsD and configure #
################################
RUN mkdir -p /src                                           && \
    git clone https://github.com/etsy/statsd.git /src/statsd && \
    cd /src/statsd &&\
    git checkout v0.7.2
COPY statsd/config.js /src/statsd/config.js

################################
# Configure collectd           #
################################
COPY collectd/collectd.conf /etc/collectd/collectd.conf

################################
# Configure graphite           #
################################
COPY graphite/local_settings.py /etc/graphite/local_settings.py
COPY graphite/graphite-carbon /etc/default/graphite-carbon
COPY graphite/carbon.conf /etc/carbon/carbon.conf
COPY graphite/storage-schemas.conf /etc/carbon/storage-schemas.conf
COPY graphite/storage-aggregation.conf /etc/carbon/storage-aggregation.conf
COPY graphite/database.json /root/database.json
RUN  python /usr/lib/python2.7/dist-packages/graphite/manage.py syncdb --noinput                          && \ 
     python /usr/lib/python2.7/dist-packages/graphite/manage.py loaddata /root/database.json

#Enable graphite-web website
RUN a2dissite 000-default                                                                                 && \
    cp /usr/share/graphite-web/apache2-graphite.conf /etc/apache2/sites-available                         && \
    a2ensite apache2-graphite

################################
# Configure grafana            #
################################
RUN mkdir /src/grafana                                                                                    &&\
    mkdir /opt/grafana                                                                                    &&\
    wget https://grafanarel.s3.amazonaws.com/builds/grafana-2.6.0.linux-x64.tar.gz -O /src/grafana.tar.gz &&\
    tar -xzf /src/grafana.tar.gz -C /opt/grafana --strip-components=1                                     &&\
    rm /src/grafana.tar.gz
COPY ./grafana/custom.ini /opt/grafana/conf/custom.ini

################################
# Configure apache2            #
################################
COPY apache2/envvars /etc/apache2/envvars

################################
# Configure supervisor         #
################################
COPY supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

########################################################
# Create users ( _graphite already exists),            #
# directories and update all permission                #
########################################################

RUN adduser --system --group --no-create-home collectd \
 && adduser --system --group --no-create-home statsd \
 && mkdir /var/log/collectd \
 && mkdir /var/log/grafana \
 && mkdir -p /var/log/supervisor \
 && mkdir -p /var/lib/grafana/ \
 && mkdir -p /var/run/carbon \
 && mkdir -p /var/run/grafana \
 && mkdir -p /opt/grafana/data/log/ \
 && chown -R collectd /var/log/collectd \
 && chown -R collectd /var/lib/collectd \
 && chown -R statsd /src/statsd \
 && chown -R _graphite /var/lib/grafana \
 && chown -R _graphite /var/log/grafana \
 && chown -R _graphite /var/run/grafana \
 && chown -R _graphite:_graphite /var/lib/graphite \
 && chown -R _graphite:_graphite /var/run/carbon \
 && chown -R _graphite:_graphite /opt/grafana/data/log/

################################
# Expose volumes, ports and    #
# set container command        #
################################
VOLUME ["/var/lib/graphite/", "/var/lib/collectd", "/var/log/supervisor", "/var/log/collectd", "/var/log/graphite", "/var/log/carbon"]
EXPOSE 80 3000 8125 8126 25826
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
