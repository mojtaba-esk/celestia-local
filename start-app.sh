#!/bin/bash

set -o errexit -o nounset
source .env

rm -rf ${APP_HOME_DIR}

if [[ `which celestia-appd` == "" ]] || [[ `celestia-appd version 2>&1 | grep "${APP_VERSION}"` == "" ]]; then

    echo -n "Building the app binary..."
    
    rm -rf celestia-app
    git clone https://github.com/celestiaorg/celestia-app.git
    cd celestia-app/
    git checkout tags/${APP_GIT_TAG} -b ${APP_GIT_TAG}
    make install
    cd ..
    rm -rf celestia-app

fi

echo "App Version: " `celestia-appd version 2>&1`
sleep 1

# Build genesis file incl account for passed address
coins="1000000000000000${DENOM}"
celestia-appd init $CHAINID --chain-id $CHAINID --home ${APP_HOME_DIR}
celestia-appd keys add ${VALIDATOR_KEY} --keyring-backend="test" --home ${APP_HOME_DIR}
# this won't work because the some proto types are decalared twice and the logs output to stdout (dependency hell involving iavl)
celestia-appd add-genesis-account $(celestia-appd keys show ${VALIDATOR_KEY} -a --keyring-backend="test" --home ${APP_HOME_DIR}) $coins --home ${APP_HOME_DIR}
celestia-appd gentx ${VALIDATOR_KEY} 5000000000${DENOM} \
  --keyring-backend="test" \
  --chain-id $CHAINID \
  --home ${APP_HOME_DIR} \
  --orchestrator-address $(celestia-appd keys show ${VALIDATOR_KEY} -a --keyring-backend="test" --home ${APP_HOME_DIR}) \
  --evm-address 0x966e6f22781EF6a6A82BBB4DB3df8E225DfD9488 # private key: da6ed55cb2894ac2c9c10209c09de8e8b9d109b910338d5bf3d747a7e1fc9eb9

celestia-appd collect-gentxs --home ${APP_HOME_DIR}

# Set proper defaults and change ports
sed -i 's#"tcp://127.0.0.1:26657"#"tcp://0.0.0.0:26657"#g' ${APP_HOME_DIR}/config/config.toml
sed -i 's/timeout_commit = "25s"/timeout_commit = "1s"/g' ${APP_HOME_DIR}/config/config.toml
sed -i 's/timeout_propose = "3s"/timeout_propose = "1s"/g' ${APP_HOME_DIR}/config/config.toml
sed -i 's/index_all_keys = false/index_all_keys = true/g' ${APP_HOME_DIR}/config/config.toml
sed -i 's/mode = "full"/mode = "validator"/g' ${APP_HOME_DIR}/config/config.toml

# Change the grpc port as it has conflict with prometheous
sed -i "s#\"0.0.0.0:9090\"#\"0.0.0.0:${CORE_GRPC_PORT}\"#g" ${APP_HOME_DIR}/config/app.toml

# Start the celestia-app
celestia-appd start --home ${APP_HOME_DIR}
