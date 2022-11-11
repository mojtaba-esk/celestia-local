#!/bin/sh

set -o errexit -o nounset


if systemctl --all --type service | grep -q "observiq-otel-collector";then
    echo "OTEL colelctor service exists."
else
    echo "Installing OTEL collector..."
    sudo sh -c "$(curl -fsSlL https://github.com/observiq/observiq-otel-collector/releases/latest/download/install_unix.sh)" install_unix.sh
    sudo mv /opt/observiq-otel-collector/config.yaml /opt/observiq-otel-collector/config.yaml.bak
    sudo ln -s $(pwd)/otel-collector/config.yml /opt/observiq-otel-collector/config.yaml
fi

# Just to read the config file again
sudo systemctl restart observiq-otel-collector

systemctl status observiq-otel-collector
# journalctl -fu observiq-otel-collector.service

sudo tail -f /opt/observiq-otel-collector/log/collector.log



exit 0
# Uninstalling it
sudo sh -c "$(curl -fsSlL https://github.com/observiq/observiq-otel-collector/releases/latest/download/install_unix.sh)" install_unix.sh -r