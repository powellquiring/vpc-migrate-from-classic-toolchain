#! /usr/bin/env bash
set -eo pipefail

LB_HOSTNAME=$(cat lb_public_hostname.txt)

# sleep for 90 seconds to allow enough time for the load balancer to recognize a server is available.
sleep 90

if [ $(curl -sL -w "%{http_code}\\n" "http://${LB_HOSTNAME}/health" -o /dev/null --connect-timeout 3 --max-time 5 --retry 3 --retry-max-time 30) == "200" ]; then
  echo "----------------------------------------------------------------------------------------------------------"
  echo "Access the web application using the following url: http://${LB_HOSTNAME}/sampleapp"
  echo ""
  echo "Successfully reached health endpoint: http://${LB_HOSTNAME}/health"
  echo ""
  echo "Access the server using the following url: http://${LB_HOSTNAME}"
  echo "----------------------------------------------------------------------------------------------------------"
else
  echo "Could not reach health endpoint: http://${LB_HOSTNAME}/health"
  exit 1;
fi;