#!/bin/bash

# set -o errexit -o nounset

DENOM="utia"
VALIDATOR_KEY="validator"
FUND_AMOUNT="5000000000${DENOM}"
CHAINID="dryrun"
APP_HOME_DIR="${HOME}/.celestia-app"

KEYRING_BACKEND="os"

CORE_IP="127.0.0.1"
CORE_RPC_PORT="26657"
CORE_GRPC_PORT="9090"

NODE_VERSION="v0.5.0"
NODE_GIT_TAG="v0.5.0"
NODE_KEY="my_celes_key"

NODE_TYPE="bridge"


METRICS_ENDPOINT="164.92.245.42:4318"
NODE_RPC_URL="http://localhost:26658"
NODE_REST_URL="http://localhost:26659"


# Required tools
# sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu -y

#-----------------#

NODE_HOME_DIR="${HOME}/.celestia-${NODE_TYPE}-${CHAINID}"
rm -rf ${NODE_HOME_DIR}

if [[ `which celestia` == "" ]] || [[ `celestia version | grep "Semantic version: ${NODE_VERSION}"` == "" ]]; then

    echo -n "Building the node binary..."
    
    rm -rf celestia-node
    git clone https://github.com/celestiaorg/celestia-node.git
    cd celestia-node/
    git checkout tags/${NODE_GIT_TAG}
    make install
    make install-key
    cd ..
    rm -rf celestia-node

fi

celestia version
sleep 1

#-----------------#

GENESIS_HASH=$(celestia-appd query block 1  | jq .block_id.hash | xargs)
export CELESTIA_CUSTOM=${CHAINID}:${GENESIS_HASH}

celestia ${NODE_TYPE} init --core.ip ${CORE_IP} --core.rpc.port ${CORE_RPC_PORT}

# Removed node.netwrok as it gives unknown flag error
cel-key delete ${NODE_KEY} --node.type ${NODE_TYPE} --node.network ${CHAINID} --keyring-backend "${KEYRING_BACKEND}" --yes
cel-key add ${NODE_KEY} --node.type ${NODE_TYPE} --node.network ${CHAINID} --keyring-backend "${KEYRING_BACKEND}"
cel-key list --node.type ${NODE_TYPE} --node.network ${CHAINID} --keyring-backend "${KEYRING_BACKEND}"

# cel-key delete ${NODE_KEY} --node.type ${NODE_TYPE} --node.network ${CHAINID} --keyring-backend "${KEYRING_BACKEND}" --yes
# cel-key add ${NODE_KEY} --node.type ${NODE_TYPE} --node.network ${CHAINID} --keyring-backend "${KEYRING_BACKEND}"
# cel-key list --node.type ${NODE_TYPE} --node.network ${CHAINID} --keyring-backend "${KEYRING_BACKEND}"

EXPORTED_KEY=$(echo "12345678" | cel-key export ${NODE_KEY}  --node.network ${CHAINID} --keyring-backend "${KEYRING_BACKEND}" --node.type ${NODE_TYPE} 2>&1)
echo "${EXPORTED_KEY}" > nodeKey.txt
celestia-appd keys delete ${NODE_KEY} --home ${APP_HOME_DIR} --keyring-backend="${KEYRING_BACKEND}" --yes
echo "12345678" | celestia-appd keys import ${NODE_KEY} nodeKey.txt --home ${APP_HOME_DIR} --keyring-backend="${KEYRING_BACKEND}"
rm -rf nodeKey.txt

celestia-appd tx bank send \
$(celestia-appd keys show ${VALIDATOR_KEY} -a --keyring-backend="${KEYRING_BACKEND}" --home ${APP_HOME_DIR}) \
$(celestia-appd keys show ${NODE_KEY} -a --keyring-backend="${KEYRING_BACKEND}" --home ${APP_HOME_DIR}) \
${FUND_AMOUNT} --chain-id $CHAINID --home ${APP_HOME_DIR} --keyring-backend "${KEYRING_BACKEND}" --yes --broadcast-mode block

celestia-appd query bank balances $(celestia-appd keys show ${NODE_KEY} -a --home ${APP_HOME_DIR} --keyring-backend="${KEYRING_BACKEND}") --home ${APP_HOME_DIR}

celestia ${NODE_TYPE} start --core.ip ${CORE_IP} --core.grpc.port ${CORE_GRPC_PORT} --gateway --metrics.tls=false --metrics --metrics.endpoint ${METRICS_ENDPOINT}