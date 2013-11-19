#!/bin/bash

# Interactive Raspberry Pi setup script
# by Yves Ledermann, Lederman Technologies (www.ltechnet.ch)
# based on the work of Stephen Wood (www.heystephenwood.com)

# USAGE:
# curl "https://raw.github.com/yves-ledermann/raspberrypi/master/configuration/setup.sh" > setup.sh && chmod 777 setup.sh
# sudo ./setup.sh hostname user pass
 

# Public Key Yves
PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAhe0cpZHLaHwrZMWjTSXlhXafd5DC9wzB26drpQnqUxmFq5qINBb/wIBZDcbHQ/OeWzFO+REVsAh8UOL4JWkfZXNADSOfiaFYBCnWbJO/3gpFvrO46vafczpXbW33XH6P/fnpny0J9w7hJHoLA93WiugcTwjBbX6LkIjDa2fAW5imq0jep8bfpQTtfIEZdokTVbLoa9ecj6iDhj7TtRsPrm493NU8lArf+8MQIEWvL3k/ONVMiaisIgH4INqw/U+LoJ12M3XK/4RX7SbimcZwEO7aB0YlA+zwqfsLGXkSYpbd/OUfcZS3i7Sa7kKcFtRke+ZbvI3UvxEPWPbVdYzvAQ== Yves20121027"



# Die on any errors
set -e 

if [[ `whoami` != "root" ]]
then
  echo "Script must be run as root."
  exit 1
fi

if [[ "$1" != "" ]]
then
	echo "Use $1 as Hostname."
	NEW_HOSTNAME=$1
else
	echo -n "Choose a hostname: "
	read NEW_HOSTNAME
fi

if [[ "$2" != "" ]]
then
	echo "Use $2 as Username."
	NEW_USER="$2"
else
	echo -n "User: "
	read NEW_USER
fi

if [[ "$3" != "" ]]
then
	echo "Use $3 as Password."
	PASS_PROMPT=="$3"
else
	echo -n "Password for user (leave blank for disabled): "
	read PASS_PROMPT
fi

# Variables for the rest of the script


#echo -n "Paste public key (leave blank for disabled): "
#read PUBLIC_KEY
#echo -n "Optionally supply an apt-mirror (press enter to skip): "
#read MIRROR





if [[ "$MIRROR" != "" ]]
then
  echo "Acquire::http { proxy '$MIRROR'; };" > /etc/apt/apt.conf.d/02proxy
fi

# APT-GET Cache cleaning because of hash sum errors acc: http://stackoverflow.com/questions/15505775/debian-apt-packages-hash-sum-mismatch
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/lib/apt/lists/partial/*
apt-get clean

apt-get -y update

# Install some base packages
apt-get install -y --force-yes git screen vim

# Update hostname
echo "$NEW_HOSTNAME" > /etc/hostname
sed -i "s/raspberrypi/$NEW_HOSTNAME/" /etc/hosts
hostname $NEW_HOSTNAME

# Set VIM as the default editor
update-alternatives --set editor /usr/bin/vim.basic

# Add user and authorized_keys
if [[ "$PASS_PROMPT" = "" ]]
then
  useradd -b /home --create-home -s /bin/bash -G sudo $NEW_USER
else
  useradd -b /home --create-home -s /bin/bash -G sudo $NEW_USER -p `echo "$PASS_PROMPT" | openssl passwd -1 -stdin` 
fi

# Remove Pi user's password
passwd -d pi

if [[ "$PUBLIC_KEY" != "" ]]
then
  mkdir -p /home/$NEW_USER/.ssh/
  echo "$PUBLIC_KEY" > /home/$NEW_USER/.ssh/authorized_keys
fi
chown -R $NEW_USER:$NEW_USER /home/$NEW_USER

# Allow users in the sudo group to sudo without password
sed -i 's/%sudo.*/%sudo   ALL=NOPASSWD: ALL/g' /etc/sudoers

# Turn off password authentication 
sed -i 's/#   PasswordAuthentication yes/    PasswordAuthentication no/g' /etc/ssh/ssh_config

# Vim settings (colors, syntax highlighting, tab space, etc).
mkdir -p /home/$NEW_USER/.vim/colors
wget "http://www.vim.org/scripts/download_script.php?src_id=11157" \
  -O /home/$NEW_USER/.vim/colors/synic

cat > /home/$NEW_USER/.vimrc <<VIM
:syntax on
:set t_Co=256

:set paste
:set softtabstop=2
:set tabstop=2
:set shiftwidth=2
:set expandtab

:colorscheme synic
VIM

# Now for some memory tweaks!
# Remove unnecessary consoles
sed -ie 's|l4:4:wait:/etc/init.d/rc 4|#l4:4:wait:/etc/init.d/rc 4|g' /etc/inittab
sed -ie 's|l5:5:wait:/etc/init.d/rc 5|#l5:5:wait:/etc/init.d/rc 5|g' /etc/inittab
sed -ie 's|l6:6:wait:/etc/init.d/rc 6|#l6:6:wait:/etc/init.d/rc 6|g' /etc/inittab
# Also disable serial console
sed -ie 's|T0:23:respawn:/sbin/getty -L ttyAMA0 115200 vt100|#T0:23:respawn:/sbin/getty -L ttyAMA0 115200 vt100|g' /etc/inittab 

# Clone Repo to Setup-Tools
git clone https://github.com/yves-ledermann/raspberrypi.git setup-tools


# END
echo "Installation Complete. Some changes might require a reboot."

