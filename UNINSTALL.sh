#!/bin/bash

set -e

# Remove systemd service
echo "Removing systemd service..."
sudo systemctl disable boot-verification.service
sudo rm /etc/systemd/system/boot-verification.service

# Remove autostart for GUI users
echo "Removing autostart for GUI users..."
rm ~/.config/autostart/boot-verification.desktop

# Remove shell profile configuration for headless users
echo "Removing shell profile configuration for headless users..."
sed -i '/^~\/boot_verification.sh$/d' ~/.bashrc

# Remove boot verification script
echo "Removing boot verification script..."
rm ~/boot_verification.sh

# Remove the .boot_verif directory and PCR value
echo "Removing stored PCR value and .boot_verif directory..."
rm -r ~/.boot_verif

echo "Boot verification uninstalled successfully."
