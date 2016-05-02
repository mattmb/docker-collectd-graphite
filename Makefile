build:
	docker build -t docker.clarin.eu/metrics:1.1.0 .

volume:
	docker create --name graphite_data graphite/test
run:
	docker run -ti --rm -p 80:80 -p 3000:3000 --volumes-from graphite_data docker.clarin.eu/metrics:1.1.0 
