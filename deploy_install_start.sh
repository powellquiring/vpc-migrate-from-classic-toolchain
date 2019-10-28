#! /usr/bin/env bash
set -eo pipefail

VSI_BASTION_HOST=$(cat vpc_vsi_bastion_fip.txt)
VSI_HOST_1=$(cat vpc_vsi_1_ip.txt)
VSI_HOST_2=$(cat vpc_vsi_2_ip.txt)
VSI_HOST_3=$(cat vpc_vsi_3_ip.txt)
VPC_ZONE_COUNT=$(cat vpc_zone_count.txt)

mkdir ~/.ssh
cp ssh_private_key ~/.ssh/id_rsa 

cat > ~/.ssh/config <<- EOF
Host $VSI_BASTION_HOST $VSI_HOST_1 $VSI_HOST_2 $VSI_HOST_3
  User root
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  LogLevel=quiet
  BatchMode=yes
  ConnectTimeout=15
  IdentityFile ~/.ssh/id_rsa

Host $VSI_HOST_1 $VSI_HOST_2 $VSI_HOST_3
  # ProxyJump $VSI_BASTION_HOST
  ProxyCommand ssh $VSI_BASTION_HOST -W %h:%p
EOF

chmod 400 ~/.ssh/config

for ((i = 1 ; i < $VPC_ZONE_COUNT + 1; i++ )); do 
  if [ "$i" = "1" ]; then
    # Copy the new archive to the VSI
    scp target/liberty/wlp/usr/servers/defaultServer/sampleapp.zip root@$VSI_HOST_1:/
    # Kills the running process, since the load balancer will no longer pass health check for that VSI it will not send traffic to it while it is not available)
    ssh root@$VSI_HOST_1 "pkill java; sleep 10; cd /; rm -rf wlp; unzip -o sampleapp.zip; wlp/bin/server start"
  elif [ "$i" = "2" ]; then
    sleep 60
    # Copy the new archive to the VSI
    scp target/liberty/wlp/usr/servers/defaultServer/sampleapp.zip root@$VSI_HOST_2:/
    # Kills the running process, since the load balancer will no longer pass health check for that VSI it will not send traffic to it while it is not available)
    ssh root@$VSI_HOST_2 "pkill java; sleep 10; cd /; rm -rf wlp; unzip -o sampleapp.zip; wlp/bin/server start"
  elif [ "$i" = "3" ]; then
    sleep 60  
    # Copy the new archive to the VSI
    scp target/liberty/wlp/usr/servers/defaultServer/sampleapp.zip root@$VSI_HOST_3:/
    # Kills the running process, since the load balancer will no longer pass health check for that VSI it will not send traffic to it while it is not available)
    ssh root@$VSI_HOST_3 "pkill java; sleep 10; cd /; rm -rf wlp; unzip -o sampleapp.zip; wlp/bin/server start"
  fi
done