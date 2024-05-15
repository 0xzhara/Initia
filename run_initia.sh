#!/bin/bash

curl -s https://raw.githubusercontent.com/zrhraJETTOKOSUTA/bash-nobi.sh/main/bash%20logo.sh | bash
echo "Join the Airdrop Nobi Telegram channel: https://t.me/airdropnobi"
sleep 5

sudo apt update && sudo apt upgrade -y
sudo apt install -y clang pkg-config libssl-dev curl git wget htop tmux build-essential jq make lz4 gcc unzip

if ! command -v go &> /dev/null || [[ $(go version | awk '{print $3}' | cut -d. -f2) -lt 19 ]]; then
    echo "Go version 1.19 or above is required. Installing the latest version..."
    cd $HOME
    sudo rm -rf /usr/local/go
    curl -Ls https://go.dev/dl/go1.21.7.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
    echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh
    echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile
    source /etc/profile.d/golang.sh
    source $HOME/.profile
fi

if ! command -v go &> /dev/null; then
    echo "Failed to install Go. Exiting..."
    exit 1
fi

echo "Go version: $(go version)"

if ! command -v git &> /dev/null; then
    echo "Git is not installed. Installing..."
    sudo apt update
    sudo apt install -y git
fi

if ! command -v curl &> /dev/null; then
    echo "curl is not installed. Installing..."
    sudo apt update
    sudo apt install -y curl
fi

if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing..."
    sudo apt update
    sudo apt install -y jq
fi

cd $HOME
git clone https://github.com/initia-labs/initia
cd initia
git checkout v0.2.12
make install
initiad version --long

read -p "Enter your name: " moniker
initiad init "$moniker" --chain-id initiation-1

wget https://initia.s3.ap-southeast-1.amazonaws.com/initiation-1/genesis.json
cp genesis.json ~/.initia/config/genesis.json

sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.initia/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.initia/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.initia/config/app.toml

sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.15uinit,0.01uusdc"|g' $HOME/.initia/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.initia/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.initia/config/config.toml

echo "Setting Peers"
sleep 3

SEEDS="cd69bcb00a6ecc1ba2b4a3465de4d4dd3e0a3db1@initia-testnet-seed.itrocket.net:51656"
PEERS="aee7083ab11910ba3f1b8126d1b3728f13f54943@initia-testnet-peer.itrocket.net:11656,16a7709332221a8b1c1edeb6533076fd7a445113@5.252.55.156:26656,e6a35b95ec73e511ef352085cb300e257536e075@37.252.186.213:26656,07632ab562028c3394ee8e78823069bfc8de7b4c@37.27.52.25:19656,d59ced58011e8c56ad89448094b3270863aa962f@62.210.173.57:26656,767fdcfdb0998209834b929c59a2b57d474cc496@207.148.114.112:26656,093e1b89a498b6a8760ad2188fbda30a05e4f300@35.240.207.217:26656,5f934bd7a9d60919ee67968d72405573b7b14ed0@65.21.202.124:29656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.initia/config/config.toml

curl -Ls https://ss-t.initia.nodestake.org/addrbook.json > ~/.initia/config/addrbook.json

sudo tee /etc/systemd/system/initiad.service > /dev/null <<EOF
[Unit]
Description=Initia Daemon

[Service]
Type=simple
User=$(whoami)
ExecStart=$(go env GOPATH)/bin/initiad start
Restart=on-abort
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=initiad
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable initiad
sudo systemctl daemon-reload
sudo systemctl restart initiad

