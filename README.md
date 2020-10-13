# aha-circle-docker

Public Docker configuration for test environment.

## Building image

Run `docker build .`

## Run/enter local image

1. Run `docker build .`
2. Run `docker run -i -t IMAGEID /bin/bash`, replacing `IMAGEID` with the ID output at the end of the docker build.
3. You're now inside a bash shell in your container.

## Updating image

Pushing to GitHub will start an image build on CodeBuild which puts an image in ECR tagged with the commit digest. Update the CircleCI config in a project to use this new digest.

## Testing

I use Kitematic GUI.

1. Create and run a container.
2. Login to the container
3. Run `sh /root/start.sh`
