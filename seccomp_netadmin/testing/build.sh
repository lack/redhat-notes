#!/bin/bash
# Note: Works with docker or podman; doesn't matter
BUILDER=podman
REPOTAG=quay.io/jramsay/nettest

(cd setsockopt; go build) && \
$BUILDER build . --tag nettest:latest --tag $REPOTAG && \
$BUILDER push $REPOTAG
