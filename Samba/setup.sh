#!/bin/bash

# Prompt user for hostname change
read -rp "Do you want to change the hostname? [y/N]: " answer

if [[ $answer =~ ^[Yy]$ ]]; then
    # Prompt for new hostname
    read -rp "Enter the new hostname: " new_hostname

    # Update hostname
    sudo hostnamectl set-hostname "$new_hostname"
    sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$new_hostname/g" /etc/hosts

    echo "Hostname has been changed to: $new_hostname"
else
    echo "No changes were made to the hostname."
fi


# Wait for command to continue
read -p "Press Enter to continue to update and install packages"

# List of packages to install
packages=( -y
    sssd-ad
    sssd-tools
    realmd
	adcli
	ansible
	cockpit
	ssh
	net-tools
	zorin-windows-app-support
)

# Update package lists

echo "Updating the System and Installing Required Packages"

sudo apt update

# Function to check and install packages
check_and_install_packages() {
    for package in "${packages[@]}"; do
        if ! dpkg -s "$package" >/dev/null 2>&1; then
            echo "Package required is not installed. Installing..."
            sudo apt install -y "$package"
            echo "Package  has been installed."
        else
            echo "Package are already installed."
        fi
    done
}

# Check and install packages
check_and_install_packages

# Show the currently installed packages
echo "Currently installed packages:"
dpkg -l | grep '^ii' | awk '{print $2}'

# Wait for command to continue
read -rp "Press Enter to continue to configure and join the domain..."




# DNS and domain settings
dns1="192.168.1.200"
domain="webvio.com"

# Update resolved.conf
sudo sed -i "s/#DNS=/DNS=$dns1 $dns2/" /etc/systemd/resolved.conf
sudo sed -i "s/#Domains=/Domains=$domain/" /etc/systemd/resolved.conf

# Restart systemd-resolved service
sudo systemctl restart systemd-resolved.service

# Restart cocktip service
sudo systemctl enable --now cockpit.socket


# Domain details
domain="webvio.com"
admin_username="admin"
admin_password="$uper@dmin@123"


# Check if system is connected to the domain
if realm list | grep -q "$domain"; then
    echo "System is already connected to the domain."
else
    echo "System is not connected to the domain. Connecting..."

    # Join the domain
    sudo realm join --user="$admin_username" "$domain"

    # Restart SSSD service
    sudo systemctl restart sssd

    echo "System successfully connected to the domain."
fi


##Updating PAM to enable Home Directory
sudo pam-auth-update --enable mkhomedir

read -p "Please press enter to continue"

##sssd Configuration file
config_file="/etc/sssd/sssd.conf"

# Line to add
new_line="ad_gpo_access_control = permissive"

# Search pattern
search_pattern="^\[domain\/webvio\.com\]$"

# Check if the line already exists in the file
if grep -qF "$new_line" "$config_file"; then
    echo "Line already exists in the sssd configuration file."
    exit 0
fi

# Add the new line after the specified section
if sudo sed -i "/$search_pattern/a$new_line" "$config_file"; then
    echo "New line added successfully  in the sssd configuration file."
else
    echo "Failed to add the new line in sssd configuration file."
fi


read -p "Please press enter to install and configure GOOGLE Chrome"

# Install Google Chrome
echo "Installing Google Chrome..."
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt-get install -f -y
rm google-chrome-stable_current_amd64.deb

# Configure Chrome policies
echo "Configuring Chrome policies..."
policy_file="/etc/opt/chrome/policies/managed/policies.json"

# Create the directory if it doesn't exist
sudo mkdir -p $(dirname "$policy_file")

# Write the policies to the file
sudo tee "$policy_file" > /dev/null <<EOT
{
  "DefaultSearchProviderName": "Google",
  "DeveloperToolsDisabled": true,
  "URLBlocklist": ["chrome://settings/", "chrome://history/"],
  "BrowserGuestModeEnabled": false,
  "BrowserAddPersonEnabled": false
}
EOT

echo "Chrome installation and policy configuration completed successfully!\n"



# Prompt user for confirmation
read -rp "System Configuration is completed , do wanna restart? [y/N]: " answer

if [[ $answer =~ ^[Yy]$ ]]; then
    sudo shutdown -r now
else
    echo "System restart canceled."
fi