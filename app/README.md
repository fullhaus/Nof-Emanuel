# APP NOF EMANUEL

## How to create docker image and run docker conatiner?

```shell
$ docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
$ docker build -t test:latest .
$ docker container run -p 3000:3000 -d $IMAGE_REPO_NAME:$IMAGE_TAG
$ docker container run -p 3000:3000 -d test:latest
```

## How to observe conatiner's logs?
```shell
$ docker ps -a
$ docker logs `docker ps -a | grep "test:latest" | cut -d ' ' -f1`
$ docker kill `docker ps -a | grep "test:latest" | cut -d ' ' -f1` && docker rm `docker ps -a | grep "test:latest" | cut -d ' ' -f1`
```

## How to go inside docker image/container?
```shell
docker exec -it `docker ps -a | grep "test:latest" | cut -d ' ' -f1` sh
docker run --rm -it --entrypoint sh test:latest
```