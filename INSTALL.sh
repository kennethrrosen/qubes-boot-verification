#!/bin/bash

set -e

# Install required packages
echo "Installing required packages..."
sudo qubes-dom0-update tpm2-tss tpm2-tools

# Create boot verification script
echo "Creating boot verification script..."
cat > ~/boot_verify.sh << EOL
#!/bin/bash

# Read the current PCR value
sudo tpm2_pcrread sha256:0 | sudo tee /tmp/current_pcr_value > /dev/null

# Compare the current PCR value to the known good value
if cmp -s /tmp/current_pcr_value ~/.boot_verif/good_pcr_value; then
    echo "Boot process is unchanged." | sudo tee /etc/motd
    notify-send "Boot Verification" "Boot process is unchanged."
else
    echo "Boot process has changed!" | sudo tee /etc/motd
    notify-send "Boot Verification" "Boot process has changed!"
fi

# Open dom0 terminal and show MOTD if in GUI mode
if [ -n "\$DISPLAY" ]; then
    qvm-run -a --service dom0 'run-terminal' < /dev/null &>/dev/null &
fi
EOL

chmod +x ~/boot_verify.sh
echo "Boot verification script created at ~/boot_verify.sh"

# Set up systemd service
echo "Setting up systemd service..."
sudo bash -c 'cat > /etc/systemd/system/boot-verify.service << EOL
[Unit]
Description=Boot Verification

[Service]
Type=oneshot
ExecStart=/home/user/boot_verify.sh

[Install]
WantedBy=multi-user.target
EOL'

sudo systemctl enable boot-verify.service
echo "Systemd service enabled."

# Configure autostart for GUI users
echo "Configuring autostart for GUI users..."
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/boot-verify.desktop << EOL
[Desktop Entry]
Type=Application
Name=Boot Verification
Exec=/home/user/boot_verify.sh
EOL

# Configure shell profile for headless users
echo "Configuring shell profile for headless users..."
echo "~/boot_verify.sh" >> ~/.bashrc

# Create the .boot_verif directory and store the known good PCR value
echo "Storing the known good PCR value..."
mkdir -p ~/.boot_verif
sudo tpm2_pcrread sha256:0 > ~/.boot_verif/good_pcr_value

echo "Boot veification setup completed!"
echo "Reboot for changes to take effect."
