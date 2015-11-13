# docker-collectd-graphite
Docker image with collectd and statsd to collect metrics and graphite as the storage backend and visualization layer.

## Exposed ports

The following ports are exposed by this image:

| Port  | Type | Description            |
| -----:|:----:| ---------------------- |
| 80    | tcp  | graphite-web           |
| 3000  | tcp  | grafana                |
| 8125  | udp  | statsd port            |
| 8126  | tcp  | statsd management port |
| 25826 | udp  | collectd port          |

The collectd and statsd ports should be externally available to allow external services to report statistics.
In order to expose the userinterface we advise to proxy to the desired port, 3000 for the grafana UI preferably.

## Running

### Create the containers
```
# Create volume container
sudo docker create \
       --name metrics_data \
       docker.clarin.eu/metrics:1.0.0
# Create container running the stack
sudo docker create \
       --name metrics \
       --volumes-from metrics_data \
       -p 172.17.42.1:3000:3000 \
       -p 8125:8125/udp \
       -p 25826:25826/udp \
       docker.clarin.eu/metrics:1.0.0
```

### Run the containers
```
sudo docker start metrics
sudo docker stop metrics
sudo docker restart metrics
```

### Recreation
```
sudo docker stop metrics
sudo docker rm metrics
sudo docker create \
       --name metrics \
       --volumes-from metrics_data \
       -p 172.17.42.1:3000:3000 \
       -p 8125:8125/udp \
       -p 25826:25826/udp \
       docker.clarin.eu/metrics:1.0.0
sudo docker start metrics
```
