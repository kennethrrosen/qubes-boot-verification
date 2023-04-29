# Boot Verification for Qubes OS with TPM 2.0
*Tested on Lenovo T480*

Securing the boot process is a crucial aspect of maintaining the integrity of any operating system, including Qubes OS. Verifying that your boot process has not been tampered with can help prevent attacks that involve modifying firmware, bootloader, or kernel components. One popular solution for boot verification has been the Anti Evil Maid (AEM) project. However, AEM is not compatible with TPM 2.0, which is now more common in newer hardware.

The TPM (Trusted Platform Module) is a hardware component that can securely store cryptographic keys and other sensitive information. TPM 2.0 is the newer iteration of this technology, which brings enhanced security features and improved algorithms. Unfortunately, the differences between TPM 1.2 and TPM 2.0 make it challenging to use AEM with the latter, leaving users with TPM 2.0 hardware without a straightforward solution for boot verification.

This repository aims to provide an alternative solution for verifying the boot process on systems equipped with TPM 2.0, particularly for users of Qubes OS. The guide and script provided in this repository offer a way to achieve boot verification using the PCR (Platform Configuration Registers) records stored in the TPM.

It's worth noting the ongoing work of the TrenchBoot project, which aims to bring improved security and boot verification to systems with TPM 2.0. As TrenchBoot matures, it may become a more comprehensive solution for Qubes OS users.

For those interested in learning more about Qubes OS security and the importance of boot verification, the following resources are recommended:

- [Qubes OS Documentation](https://www.qubes-os.org/doc/)
- [Qubes OS Security](https://www.qubes-os.org/security/)
- [Anti Evil Maid](https://www.qubes-os.org/doc/anti-evil-maid/)
- [TrenchBoot](https://www.qubes-os.org/news/2023/01/31/trenchboot-aem-for-qubes-os/)

This guide will help you set up boot verification on a Lenovo T480 using TPM PCR values with Qubes OS. The setup includes a script that:

- Displays a GUI notification on boot for GUI users, including a bubble notification and a message on the login screen.
- Leverages PCR records for boot verification.
- Opens a dom0 terminal and shows the MOTD if the user is in GUI mode.
- Shows the MOTD if the user is using a headless-only setup.

### Prerequisites

To use this guide and script, you need a Lenovo T480 with TPM enabled and properly configured in the BIOS/UEFI settings. To enable and configure TPM on your Lenovo T480, follow these steps:
   
- Turn off your T480 and then turn it back on. Press the F1 key when the Lenovo logo appears to enter the BIOS/UEFI settings.
- Navigate to the Security tab using the arrow keys.
- Select TPM 2.0 Security.
- Set the TPM Device option to Enabled.
- Set the TPM Activation option to Enabled.
- Set the TPM Clear option to Disabled.
- Press F10 to save the changes and exit the BIOS/UEFI settings. Your system will restart and apply the changes.

### Implement 

Install the tpm2-tss library and the tpm2-tools package to interact with the TPM in Qubes OS:
```
sudo qubes-dom0-update tpm2-tss tpm2-tools
```
Create a script called boot_verify.sh and add the following content:
```
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
if [ -n "$DISPLAY" ]; then
    qvm-run -a --service dom0 'run-terminal' < /dev/null &>/dev/null &
fi
```
Replace /path/to/known_good_pcr_value with the path where you store the known good PCR value.

Make the script executable: `chmod +x /path/to/boot_verification.sh`

Create a file /etc/systemd/system/boot-verification.service with the following content:
```
[Unit]
Description=Boot Verification

[Service]
Type=oneshot
ExecStart=/path/to/boot_verification.sh

[Install]
WantedBy=multi-user.target
```
Then enable the service: `sudo systemctl enable boot-verification.service`

To run the script at login:

For GUI users, add the script to `~/.config/autostart/boot-verification.desktop` with the following:
```
[Desktop Entry]
Type=Application
Name=Boot Verification
Exec=/path/to/boot_verification.sh
```
For headless users, add the script to.bashrc or .bash_profile file to display the MOTD at login: `/path/to/boot_verification.sh`

### Usage

After completing the setup, the boot verification script will run every time you boot your T480 and log in to Qubes OS. The script will compare the current PCR value to the known good value to verify the boot process.

If the boot process is unchanged, the following will occur: GUI users will see a bubble notification that reads "Boot process is unchanged." Both GUI and headless users will see the MOTD "Boot process is unchanged." when they log in to the shell.

If the boot process has changed, the following will happen: GUI users will see a bubble notification that reads "Boot process has changed!" Both GUI and headless users will see the MOTD "Boot process has changed!" when they log in to the shell.

### How to update the known good PCR value

When you make legitimate changes to your boot process, such as updating the BIOS or changing the boot order, you will need to update the known good PCR value to avoid false alarms.

To update the known good PCR value, boot your T480 after making the legitimate changes to your boot process. Log in to Qubes OS and run the following command to read the current PCR value: `sudo tpm2_pcrread sha256:0 > /path/to/new_known_good_pcr_value`

Verify the new PCR value to ensure that it reflects the expected changes. If the new value is correct, replace the old known good value with the new value: `mv /path/to/new_known_good_pcr_value /path/to/known_good_pcr_value`

Now, the boot verification script will use the updated known good PCR value for future boot process verifications.

### Troubleshooting

If you encounter issues with the boot verification setup, try the following troubleshooting steps:

- Ensure that the TPM is enabled in your T480 BIOS/UEFI settings.
- Check that the tpm2-tss library and tpm2-tools package are installed correctly in Qubes OS.
- Verify that the script paths in the systemd service, autostart configuration, and shell profile are correct.
- Make sure the known good PCR value is up-to-date and reflects the expected boot process.

If the issues persist, consult the Qubes OS documentation and TPM 2.0 resources for further guidance.

### Alternative Setup Option: Automated Script

__Warning:__ This alternative method involves running a script with root privileges in dom0, which is not recommended due to potential security risks. Proceed at your own discretion. For those who prefer a more automated setup, I've provided a script that automates most of the steps described in the manual setup process. 

The script automates the entire setup process, including storing the known good PCR value, creating the `~/.config/autostart/boot-verify.desktop file` and adding the `'~/boot_verify.sh'` line to your .bashrc for headless users. It also includes error handling with set -e, which causes the script to exit if any command fails.

Keep in mind that using this script requires trusting the author of the script and running it in the most security-critical part of your Qubes OS system (dom0). Use this alternative option only if you understand and accept the risks involved.

To use this script, follow the steps below:

1. Clone this repository or download the INSTALL.sh script in a Disposable VM.

2. Copy the INSTALL.sh script from the Disposable VM to the dom0 using qvm-run:
```
qvm-run --pass-io <Disposable_VM_name> 'cat /path/to/INSTALL.sh' > INSTALL.sh
```
3. Make the script executable: `chmod +x INSTALL.sh`

4. Run the script in dom0: `./INSTALL.sh`

###  Uninstalling Boot Verification

If you wish to uninstall the boot verification setup, we provide an uninstall script to help you do so. The `UNINSTALL.sh` script will disable and remove the systemd service, remove the autostart entry for GUI users, remove the shell profile configuration for headless users, and delete the boot verification script and the `.boot_verif` directory containing the PCR value.

To use the uninstall script, follow these steps:

1. Download the `UNINSTALL.sh` script from the repository or copy the script content from above.
2. Make the script executable: `chmod +x UNINSTALL.sh`
3. Run the script: `./UNINSTALL.sh`

After running the uninstall script, the boot verification setup will be removed from your system.

