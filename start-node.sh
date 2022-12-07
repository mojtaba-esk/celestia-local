#!/bin/bash

# set -o errexit -o nounset

source .env

#-----------------#

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
    sudo make install
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

cel-key delete ${NODE_KEY} --node.type ${NODE_TYPE} --keyring-backend "test" --yes
cel-key add ${NODE_KEY} --node.type ${NODE_TYPE} --keyring-backend "test"
cel-key list --node.type ${NODE_TYPE} --keyring-backend "test"

EXPORTED_KEY=$(echo "12345678" | cel-key export ${NODE_KEY} --keyring-backend "test" --node.type ${NODE_TYPE} 2>&1)
echo "${EXPORTED_KEY}" > nodeKey.txt
celestia-appd keys delete ${NODE_KEY} --home ${APP_HOME_DIR} --keyring-backend="test" --yes
echo "12345678" | celestia-appd keys import ${NODE_KEY} nodeKey.txt --home ${APP_HOME_DIR} --keyring-backend="test"
rm -rf nodeKey.txt

celestia-appd tx bank send \
$(celestia-appd keys show ${VALIDATOR_KEY} -a --keyring-backend="test" --home ${APP_HOME_DIR}) \
$(celestia-appd keys show ${NODE_KEY} -a --keyring-backend="test" --home ${APP_HOME_DIR}) \
${FUND_AMOUNT} --chain-id $CHAINID --home ${APP_HOME_DIR} --keyring-backend "test" --yes --broadcast-mode block

celestia-appd query bank balances $(celestia-appd keys show ${NODE_KEY} -a --home ${APP_HOME_DIR} --keyring-backend="test") --home ${APP_HOME_DIR}


celestia ${NODE_TYPE} start --core.ip ${CORE_IP} --core.grpc.port ${CORE_GRPC_PORT} --gateway --metrics.tls=false --metrics --metrics.endpoint ${METRICS_ENDPOINT}

exit 0
# Dev version
# clear && make build && ./build/celestia ${NODE_TYPE} init --core.ip ${CORE_IP} --core.rpc.port ${CORE_RPC_PORT}
# clear && make build && ./build/celestia ${NODE_TYPE} start --core.ip ${CORE_IP} --core.grpc.port ${CORE_GRPC_PORT}