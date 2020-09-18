# aha-circle-docker

Public Docker configuration for test environment.

## Building image

Run `docker build .`

## Run/enter local image

1. Run `docker build .`
2. Run `docker run -i -t IMAGEID /bin/bash`, replacing `IMAGEID` with the ID output at the end of the docker build.
3. You're now inside a bash shell in your container.

## Pushing updated image

1. Run `docker build .`
2. At the end of the build script copy the image ID for the image you just built
3. Run `docker tag IMAGEID ahaapp/aha-circle-docker:x.x.x` -- `IMAGEID` should be the image ID you copied in step 2, `x.x.x` should be a bumped version number
4. Run `docker login` to authenticate with Docker Hub (you'll need added to https://hub.docker.com/orgs/ahaapp if not already)
5. Run `docker push ahaapp/aha-circle-docker:x.x.x` -- `x.x.x` should be your new version number

## Testing

I use Kitematic GUI.

1. Create and run a container.
2. Login to the container
3. Run `sh /root/start.sh`
