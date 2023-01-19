# A minimal local setup for Celestia

**NOTE:** This repo is not maintained any more, please do not use it. 
A new version of the bundle can be found here: https://github.com/celestiaorg/celestia-local-docker/

----------

This bundle sets up a local validator, a local bridge node with an Otel collector configured to store node metrics data in a Prometheus instance as DB.

## Setup

```bash
git clone https://github.com/mojtaba-esk/celestia-local.git
cd celestia-local
```

It is better to open multiple terminals for each of the following commands to see the logs.

### Launch the OTEL collector and Prometheus server

```bash
docker-compose up
```

**Note:** you may need to use `sudo` if docker username is not added to your privileged group.

### Start the Validator

```bash
./start-app.sh
```

**Note:** This command removes your default validator directory which is `~/.celestia-app`.
If you wanna keep it, just modify the app home path in `.env` file to somewhere else.

```env
APP_HOME_DIR="${HOME}/.celestia-app"
```

### Start the Celestia Node

```bash
./start-node.sh
```

### Start the `Submit random PFD script`

This script submits a random number of PFDs with random length and waits for a random time in between batch submits.
Here is how to initiate it:

```bash
./submit-random-pfds.sh
```

## Config vars

Config vars cane be modified in the `.env` file. The default values are listed here:

```env
DENOM="utia"
VALIDATOR_KEY="validator"
FUND_AMOUNT="5000000000${DENOM}"
CHAINID="test"
APP_HOME_DIR="${HOME}/.celestia-app"

CORE_IP="127.0.0.1"
CORE_RPC_PORT="26657"
CORE_GRPC_PORT="9092"

NODE_VERSION="v0.4.1"
NODE_KEY="my_celes_key"

NODE_TYPE="bridge"

METRICS_ENDPOINT="localhost:4318"
NODE_RPC_URL="http://localhost:26658"
```

## Version notes

This bundle is tested with Celestia-app version `0.7.0` and Celestia-node version `v0.4.1`
