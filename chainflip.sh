#!/bin/bash

PS3='Select an action: '
options=(
"Install Node"
"Exit")

select opt in "${options[@]}"
do
case $opt in

	"Install Node")

echo -e "\e[1m\e[32m	Enter eth private key:\e[0m"
echo "_|-_|-_|-_|-_|-_|-_|"
read eth_key
echo "_|-_|-_|-_|-_|-_|-_|"

echo "===== Adding Chainflip APT Repo ====="
sudo mkdir -p /etc/apt/keyrings
curl -fsSL repo.chainflip.io/keys/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/chainflip.gpg
echo "deb [signed-by=/etc/apt/keyrings/chainflip.gpg] https://repo.chainflip.io/perseverance/ focal main" | sudo tee /etc/apt/sources.list.d/chainflip.list
sudo apt-get update
sudo apt-get install -y chainflip-cli chainflip-node chainflip-engine

echo "===== Generating Keys ====="
sudo mkdir /etc/chainflip/keys
echo "======== Eth Key ========" > keys.txt
echo -n "$eth_key" >> keys.txt
echo -e "\n" >> keys.txt
echo -n "$eth_key" |  sudo tee /etc/chainflip/keys/ethereum_key_file

echo "======== Signing Key ========" >> keys.txt
SECRET_SEED=chainflip-node key generate | tee -a keys.txt | grep "Secret seed" | sed -e 's/  Secret seed:       //'
echo -n "${SECRET_SEED:2}" | sudo tee /etc/chainflip/keys/signing_key_file
echo -e "\n" >> keys.txt

echo "======== Node Key ========" >> keys.txt
sudo chainflip-node key generate-node-key --file /etc/chainflip/keys/node_key_file
sudo cat /etc/chainflip/keys/node_key_file >> keys.txt

sudo chmod 600 /etc/chainflip/keys/ethereum_key_file
sudo chmod 600 /etc/chainflip/keys/signing_key_file
sudo chmod 600 /etc/chainflip/keys/node_key_file
history -c

break
;;

"Exit")
exit

esac
done
