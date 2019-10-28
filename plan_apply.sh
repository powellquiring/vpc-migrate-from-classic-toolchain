#! /usr/bin/env bash
set -eo pipefail

commit_state() {
  set +e
  cd - 
  cd temp_repo

  git config --global user.email "vpc.toolchain@noreply.com"
  git config --global user.name "Automatic Build ibmcloud-vpc-toolchain"
  git config --global push.default simple
  git add .
  git commit -m "Published terraform apply updates from ibmcloud-toolchain"
  git push --set-upstream origin br_tfstate -f
  exit 1
}

mkdir ~/.ssh
cp ssh_private_key ~/.ssh/id_rsa 

git clone ${GIT_REMOTE_URL} temp_repo

cd temp_repo

if [ $(git ls-remote --heads ${GIT_REMOTE_URL} br_tfstate | wc -l) == "0" ]; then
  git checkout --orphan br_tfstate
  git rm -rf .
  git config --global user.email "vpc.toolchain@noreply.com"
  git config --global user.name "Automatic Build ibmcloud-vpc-toolchain"
  git config --global push.default simple
  git commit --allow-empty -m "root commit"
  git push origin br_tfstate
else
  git fetch origin br_tfstate
  git checkout br_tfstate
fi

mkdir -p state

cd - 

cd terraform

terraform init -input=false
terraform validate

terraform plan -input=false -state=../temp_repo/state/terraform_${PIPELINE_TOOLCHAIN_ID}.tfstate -out=../temp_repo/state/terraform_${PIPELINE_TOOLCHAIN_ID}.tfplan

# Need to commit the state in the event of a failure and then bail
trap commit_state ERR
terraform apply -auto-approve -input=false -state-out=../temp_repo/state/terraform_${PIPELINE_TOOLCHAIN_ID}.tfstate ../temp_repo/state/terraform_${PIPELINE_TOOLCHAIN_ID}.tfplan

terraform output -state=../temp_repo/state/terraform_${PIPELINE_TOOLCHAIN_ID}.tfstate "vpc_vsi_bastion_fip" > ../vpc_vsi_bastion_fip.txt
terraform output -state=../temp_repo/state/terraform_${PIPELINE_TOOLCHAIN_ID}.tfstate "vpc_vsi_1_ip" > ../vpc_vsi_1_ip.txt
terraform output -state=../temp_repo/state/terraform_${PIPELINE_TOOLCHAIN_ID}.tfstate "vpc_vsi_2_ip" > ../vpc_vsi_2_ip.txt
terraform output -state=../temp_repo/state/terraform_${PIPELINE_TOOLCHAIN_ID}.tfstate "vpc_vsi_3_ip" > ../vpc_vsi_3_ip.txt
terraform output -state=../temp_repo/state/terraform_${PIPELINE_TOOLCHAIN_ID}.tfstate "vpc_zone_count" > ../vpc_zone_count.txt
terraform output -state=../temp_repo/state/terraform_${PIPELINE_TOOLCHAIN_ID}.tfstate "lb_public_hostname" > ../lb_public_hostname.txt

cd -

cd temp_repo

git config --global user.email "vpc.toolchain@noreply.com"
git config --global user.name "Automatic Build ibmcloud-vpc-toolchain"
git config --global push.default simple
git add .
git commit -m "Published terraform apply updates from ibmcloud-toolchain"
git push --set-upstream origin br_tfstate -f