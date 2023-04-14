#!/bin/bash

set -e

# Remove installed packages
echo "Removing installed packages..."
sudo dnf remove -y tpm2-tss tpm2-tools

# Remove systemd service
echo "Removing systemd service..."
sudo systemctl disable boot-verify.service
sudo rm /etc/systemd/system/boot-verify.service

# Remove autostart for GUI users
echo "Removing autostart for GUI users..."
rm ~/.config/autostart/boot-verify.desktop

# Remove shell profile configuration for headless users
echo "Removing shell profile configuration for headless users..."
sed -i '/^~\/boot_verify.sh$/d' ~/.bashrc

# Remove boot verification script
echo "Removing boot verification script..."
rm ~/boot_verify.sh

# Remove the .boot_verif directory and PCR value
echo "Removing stored PCR value and .boot_verif directory..."
rm -r ~/.boot_verif

echo "Boot verification uninstalled successfully."
