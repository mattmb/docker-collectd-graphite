# docker-collectd-graphite
Docker image with collectd and statsd to collect metrics and graphite as the storage backend and visualization layer.

## Exposed ports

The following ports are exposed by this image:
| port  | description            |
| -----:| ---------------------- |
| 80    | grafana                |
| 3000  | graphite-web           |
| 8125  | statsd port            |
| 8126  | statsd management port |
| 25826 | collectd port          |

The collectd and statsd ports should be externally available to allow external services to report statistics.
In order to expose the userinterface you can expose port 80 or proxy to the desired port.
