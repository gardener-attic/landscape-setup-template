#!/bin/bash -eu

# Build docker image with name "gardener_landscape"
cd setup
docker build . -t gardener_landscape
cd ..