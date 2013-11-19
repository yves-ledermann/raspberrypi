#!/bin/bash
set -e

# Raspberry Pi jeelabs housemon script
# 
# 
# 
# Usage: $ sudo ./

for i in $*
do
  case $i in
  --update)
   # update
	git pull
	rm -rf node_modules bower_components
	npm install
    printf "updated\n"
    exit 1
    ;;
  *)
    # unknown option
    ;;
  esac
done

# install node.js acc. https://github.com/nathanjohnson320/node_arm

wget http://node-arm.herokuapp.com/node_latest_armhf.deb
sudo dpkg -i node_latest_armhf.deb
# Check installation
node -v

git clone https://github.com/jcw/housemon.git
cd housemon

npm install

echo 'Installation complete. Enjoy!'
