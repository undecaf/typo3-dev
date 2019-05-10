#!/bin/sh

podman exec typo3 setenv HOST_IP=$(hostname -I | awk '{print $1}') $@
