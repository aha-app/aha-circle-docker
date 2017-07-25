# aha-circle-docker

Public Docker configuration for test environment.

## Building image

Run `docker build .`

## Pushing updated image

1. Run `docker build .`
2. Run `docker image ls` and copy the image ID for the image you just built
3. Run `docker tag IMAGEID ahaapp/aha-circle-docker:x.x.x` -- `IMAGEID` should be the image ID you copied in step 2, `x.x.x` should be a bumped version number
4. Run `docker push ahaapp/aha-circle-docker:x.x.x` -- `x.x.x` should be your new version number
