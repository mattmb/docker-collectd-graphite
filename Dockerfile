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
    apt-get install -y graphite-web graphite-carbon apache2 libapache2-mod-wsgi supervisor collectd collectd-utils git nodejs wget

RUN adduser --system --group --no-create-home collectd && \
    adduser --system --group --no-create-home statsd

################################
# Install StatsD and configure #
################################
RUN mkdir -p /src                                           && \
    git clone https://github.com/etsy/statsd.git /src/statsd && \
    cd /src/statsd &&\
    git checkout v0.7.2
COPY statsd/config.js /src/statsd/config.js

######################
# Configure collectd #
######################
COPY collectd/collectd.conf /etc/collectd/collectd.conf
RUN mkdir /var/log/collectd && \
    chown -R collectd /var/log/collectd && \
    chown -R collectd /var/lib/collectd

######################
# Configure graphite #
######################
COPY graphite/local_settings.py /etc/graphite/local_settings.py
COPY graphite/graphite-carbon /etc/default/graphite-carbon
COPY graphite/carbon.conf /etc/carbon/carbon.conf
COPY graphite/storage-schemas.conf /etc/carbon/storage-schemas.conf
COPY graphite/storage-aggregation.conf /etc/carbon/storage-aggregation.conf
COPY graphite/database.json /root/database.json
RUN  python /usr/lib/python2.7/dist-packages/graphite/manage.py syncdb --noinput                          && \ 
     python /usr/lib/python2.7/dist-packages/graphite/manage.py loaddata /root/database.json
#Carbon runs as www-data and needs write permission
#Graphite runs as _graphite
RUN   chown -R _graphite:www-data /var/lib/graphite                                                       && \ 
      chmod -R ug+w /var/lib/graphite

RUN a2dissite 000-default                                                                                 && \
    cp /usr/share/graphite-web/apache2-graphite.conf /etc/apache2/sites-available                         && \
    a2ensite apache2-graphite

#####################
# Configure grafana #
#####################
RUN mkdir /src/grafana                                                                                    &&\
    mkdir /opt/grafana                                                                                    &&\
    wget https://grafanarel.s3.amazonaws.com/builds/grafana-2.6.0.linux-x64.tar.gz -O /src/grafana.tar.gz &&\
    tar -xzf /src/grafana.tar.gz -C /opt/grafana --strip-components=1                                     &&\
    rm /src/grafana.tar.gz
COPY ./grafana/custom.ini /opt/grafana/conf/custom.ini
RUN mkdir -p /var/lib/grafana/ && \
    chown -R www-data /var/lib/grafana && \
    mkdir -p /var/lib/grafana-dashboards && \
    chown -R www-data /var/lib/grafana-dashboards

########################
# Configure supervisor #
########################
COPY supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisor

VOLUME ["/var/lib/graphite/", "/var/lib/collectd", "/var/log/supervisor", "/var/log/collectd", "/var/log/graphite", "/var/log/carbon"]

EXPOSE 80 3000 8125 8126 25826

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
