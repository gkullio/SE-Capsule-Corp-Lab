#!/bin/bash

# docker installation
sudo apt update -y
sudo apt upgrade -y
sudo apt-get install net-tools -y
sudo apt-get install curl -y
sudo apt-get install unzip -y
sudo apt-get install apache2-utils -y
ping -c 50 127.0.0.1
echo "PING COMPLETE" > ping_done.txt;
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null;
echo "TODAY HAS FINALLY COME" > echo_done.txt;
sudo apt update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
echo "Install Done" > install_done.txt;
sudo service docker start
sudo usermod -a -G docker kulland

# Install spa-demo-app 
mkdir /etc/capsule_corp
git init ~/capsule_corp
cd ~/capsule_corp
git remote add origin "https://github.com/gkullio/xc-cc-exercise.git"
git fetch origin main
git checkout main

mv ~/capsule_corp /etc/capsule_corp
sudo bash /etc/capsule_corp/capsule_corp/install-lab-service-with-chamber.sh