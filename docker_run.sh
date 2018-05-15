#!/bin/bash -eu

# Run the docker container with interactive shell, cd to the mounted folder, and source the init.sh file
# the "&& bash" keeps the interactive mode of the docker container alive
docker run -it -v $(pwd):/landscape -w /landscape gardener_landscape bash -c "source ./setup/init.sh && bash"