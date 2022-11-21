#!/bin/bash

PS3='Select an action: '
options=(
"Install Node"
"Start Engine"
"Register Validator"
"Exit")

select opt in "${options[@]}"
do
case $opt in

"Install Node")

echo -e "\e[1m\e[32m	Enter eth private key:\e[0m"
echo "_|-_|-_|-_|-_|-_|-_|"
read eth_key
echo "_|-_|-_|-_|-_|-_|-_|"

echo -e "\e[1m\e[32m    Enter ip address:\e[0m"
echo "_|-_|-_|-_|-_|-_|-_|"
read ip_addr
echo "_|-_|-_|-_|-_|-_|-_|"

echo -e "\e[1m\e[32m    Enter wss eth client:\e[0m"
echo "_|-_|-_|-_|-_|-_|-_|"
read wss_eth_client
echo "_|-_|-_|-_|-_|-_|-_|"

echo -e "\e[1m\e[32m    Enter https eth client:\e[0m"
echo "_|-_|-_|-_|-_|-_|-_|"
read https_eth_client
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

echo "===== Configuration File ====="
sudo mkdir -p /etc/chainflip/config

sudo tee <<EOF /etc/chainflip/config/Default.toml
# Default configurations for the CFE
[node_p2p]
node_key_file = "/etc/chainflip/keys/node_key_file"
ip_address="$ip_addr"
port = "8078"

[state_chain]
ws_endpoint = "ws://127.0.0.1:9944"
signing_key_file = "/etc/chainflip/keys/signing_key_file"

[eth]
# Ethereum RPC endpoints (websocket and http for redundancy).
ws_node_endpoint = "$wss_eth_client"
http_node_endpoint = "$https_eth_client"

# Ethereum private key file path. This file should contain a hex-encoded private key.
private_key_file = "/etc/chainflip/keys/ethereum_key_file"

[signing]
db_file = "/etc/chainflip/data.db"
EOF

echo "===== Start up ====="
sudo systemctl start chainflip-node
sudo systemctl status chainflip-node
sudo systemctl enable chainflip-node
tail -f /var/log/chainflip-node.log

break
;;

"Start Engine")

sudo systemctl start chainflip-engine
sudo systemctl status chainflip-engine
sudo systemctl enable chainflip-engine
tail -f /var/log/chainflip-engine.log

break
;;

"Register Validator")

echo -e "\e[1m\e[32m    Enter node name:\e[0m"
echo "_|-_|-_|-_|-_|-_|-_|"
read node_name
echo "_|-_|-_|-_|-_|-_|-_|"

sudo chainflip-cli --config-path /etc/chainflip/config/Default.toml register-account-role Validator
sudo chainflip-cli --config-path /etc/chainflip/config/Default.toml activate
sudo chainflip-cli --config-path /etc/chainflip/config/Default.toml rotate
sudo chainflip-cli --config-path /etc/chainflip/config/Default.toml vanity-name $node_name

break
;;

"Exit")
exit

esac
done
