#!/bin/bash -x

DOCKER_IMAGE_NAME="prlprg/project-strictr"

base_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
docker_working_dir="/home/rstudio/strictR"
local_working_dir="$base_dir"
cmd="bash"

[ $# -gt 0 ] && cmd="$@"

docker run \
    -ti \
    --rm \
    -e ROOT=TRUE \
    -e DISABLE_AUTH=true \
    -e USERID=$(id -u) \
    -e GROUPID=$(id -g) \
    -v "$(pwd)/../strictr:/R/strictr"\
    -v "$local_working_dir:$docker_working_dir" \
    -w "$docker_working_dir" \
    "$DOCKER_IMAGE_NAME" \
    $cmd

# docker run \
#     --rm \
#     -v "$local_working_dir:$docker_working_dir" \
#     "$DOCKER_IMAGE_NAME" \
#     chown -R $(id -u):$(id -g) "$docker_working_dir"
