build:
	docker build -t graphite/test .

volume:
	docker create --name graphite_data graphite/test
run:
	docker run -ti --rm -p 80:80 -p 3000:3000 --volumes-from graphite_data graphite/test
