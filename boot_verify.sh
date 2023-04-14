#!/bin/bash

set -e

# Install required packages
echo "Installing required packages..."
sudo qubes-dom0-update tpm2-tss tpm2-tools

# Create boot verification script
echo "Creating boot verification script..."
cat > ~/boot_verification.sh << EOL
#!/bin/bash

# Read the current PCR value
sudo tpm2_pcrread sha256:0 > /tmp/current_pcr_value

# Compare the current PCR value to the known good value
if cmp -s /tmp/current_pcr_value /path/to/known_good_pcr_value; then
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

chmod +x ~/boot_verification.sh
echo "Boot verification script created at ~/boot_verification.sh"

# Set up systemd service
echo "Setting up systemd service..."
sudo bash -c 'cat > /etc/systemd/system/boot-verification.service << EOL
[Unit]
Description=Boot Verification

[Service]
Type=oneshot
ExecStart=/home/user/boot_verification.sh

[Install]
WantedBy=multi-user.target
EOL'

sudo systemctl enable boot-verification.service
echo "Systemd service enabled."

# Configure autostart for GUI users
echo "Configuring autostart for GUI users..."
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/boot-verification.desktop << EOL
[Desktop Entry]
Type=Application
Name=Boot Verification
Exec=/home/user/boot_verification.sh
EOL

# Configure shell profile for headless users
echo "Configuring shell profile for headless users..."
echo "~/boot_verification.sh" >> ~/.bashrc

# Store the known good PCR value
echo "Storing the known good PCR value..."
read -p "Enter the path to store the known good PCR value: " pcr_value_path
sudo tpm2_pcrread sha256:0 > "$pcr_value_path"

# Update the path in the boot_verification.sh script
echo "Updating the path to the known good PCR value in the boot_verification.sh script..."
sed -i "s|/path/to/known_good_pcr_value|$pcr_value_path|g" ~/boot_verification.sh

echo "Done! Boot verification setup is complete."
