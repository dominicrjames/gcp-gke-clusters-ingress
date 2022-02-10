#!/bin/bash
#
# Creates subnetwork in 'default' network
#
BIN_DIR=$(dirname ${BASH_SOURCE[0]})
cd $BIN_DIR

project_id="$1"
network_name="$2"
region="$3"
if [[ -z "$project_id" || -z "$network_name" || -z "$region" ]]; then
  echo "Usage: projectid networkName region"
  exit 1
fi

function create_subnet() {
  project_id="$1"
  network_name="$2"
  subnet_name="$3"
  cidr="$4"
  region="$5"

  gcloud compute networks subnets create $subnet_name --project $project_id --network $network_name --range="$cidr" --region=$region
 

}

gcloud config set project $project_id

echo "create VPC network"
set -x
gcloud compute networks create $network_name --subnet-mode=custom

create_subnet $project_id $network_name "pub-10-0-90-0"   "10.0.90.0/24" $region 
create_subnet $project_id $network_name "pub-10-0-91-0"   "10.0.91.0/24" $region
create_subnet $project_id $network_name "prv-10-0-100-0" "10.0.100.0/24" $region
create_subnet $project_id $network_name "prv-10-0-101-0" "10.0.101.0/24" $region


echo "minimal firewall rule for allowing all internal traffic"
# OR --rules=all
gcloud compute firewall-rules create ${network_name}-allow-internal --project=$project_id --direction=INGRESS --priority=1000 --network=mynetwork --action=ALLOW --rules=tcp:0-65535,udp:0-65535 --source-ranges=10.0.0.0/8

echo "allow ssh into vms in public subnets"
gcloud compute firewall-rules create ${network_name}-ext-ssh-allow --project=$project_id --network $network_name --action=ALLOW --rules=icmp,tcp:22 --source-ranges=0.0.0.0/0 --direction=INGRESS --target-tags=pubjumpbox


# Cloud NAT for egress in private subnet
# https://cloud.google.com/sdk/gcloud/reference/compute/routers/nats/create?hl=nb
gcloud compute routers create ${network_name}-router1 --network=$network_name --region=$region

gcloud compute routers nats create ${network_name}-nat-gateway1 --router=${network_name}-router1 --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges --region=$region 