#!/bin/bash
for key in $( set | awk '{FS="="}  /^OS_/ {print $1}' ); do unset $key ; done
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=bhjung_pr
export OS_TENANT_NAME=bhjung_pr
export OS_USERNAME=bhjung
export OS_PASSWORD=Admin123!
export OS_AUTH_URL=https://192.168.240.20:5000/v3
export OS_INTERFACE=public
export OS_ENDPOINT_TYPE=publicURL
export OS_MANILA_ENDPOINT_TYPE=publicURL
export OS_IDENTITY_API_VERSION=3
export OS_REGION_NAME=RegionOne
export OS_AUTH_PLUGIN=password

