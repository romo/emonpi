#!/bin/bash
source config.ini

echo "-------------------------------------------------------------"
echo "Install Emoncms Modules"
echo "-------------------------------------------------------------"
# Review default branch: e.g stable
cd $emoncms_www/Modules
for module in ${!emoncms_modules[@]}; do
    branch=${emoncms_modules[$module]}
    if [ ! -d $module ]; then
        echo "- Installing module: $module"
        git clone -b $branch https://github.com/emoncms/$module.git
    else
        echo "- Module $module already exists"
    fi
done

# wifi module sudoers entry
sudo visudo -cf $usrdir/emonpi/sudoers.d/wifi-sudoers && \
sudo cp $usrdir/emonpi/sudoers.d/wifi-sudoers /etc/sudoers.d/
sudo chmod 0440 /etc/sudoers.d/wifi-sudoers
echo "wifi sudoers entry installed"
# wpa_supplicant permissions
sudo chmod 644 /etc/wpa_supplicant/wpa_supplicant.conf 

# Install emoncms modules that do not reside in /var/www/emoncms/Modules
if [ ! -d $usrdir/modules ]; then
    # sudo mkdir $usrdir
    # sudo chown $user $usrdir
    mkdir $usrdir/modules
    # emoncms-sync.log is written to data folder
    # change to /var/log or use emoncms logger
    mkdir $usrdir/modules/data
fi

cd $usrdir/modules
for module in ${!emoncms_modules_usrdir[@]}; do
    branch=${emoncms_modules_usrdir[$module]}
    if [ ! -d $module ]; then
        echo "- Installing module: $module"
        git clone -b $branch https://github.com/emoncms/$module.git
        # If module contains emoncms UI folder, symlink to $emoncms_www/Modules
        if [ -d $usrdir/modules/$module/$module-module ]; then
            echo "-- UI directory symlink"
            ln -s $usrdir/modules/$module/$module-module $emoncms_www/Modules/$module
        fi
        # run module install script if present
        if [ -f $usrdir/modules/$module/install.sh ]; then
            $usrdir/modules/$module/install.sh $usrdir
            echo
        fi
    else
        echo "- Module $module already exists"
    fi
done

# backup module
if [ -d $usrdir/modules/backup ]; then
    cd backup
    if [ ! -f config.cfg ]; then
        cp default.config.cfg config.cfg
        sed -i "s~USER~$user~" config.cfg
        sed -i "s~BACKUP_SCRIPT_LOCATION~$usrdir/modules/backup~" config.cfg
        sed -i "s~EMONCMS_LOCATION~$emoncms_www~" config.cfg
        sed -i "s~BACKUP_LOCATION~$usrdir/data~" config.cfg
        sed -i "s~DATABASE_PATH~$emoncms_datadir~" config.cfg
        sed -i "s~EMONHUB_CONFIG_PATH~$usrdir/data~" config.cfg
        sed -i "s~EMONHUB_SPECIMEN_CONFIG~$usrdir/emonhub/conf~" config.cfg
        sed -i "s~BACKUP_SOURCE_PATH~$usrdir/data/uploads~" config.cfg
    fi
    cd
fi

echo "Update Emoncms database"
php $usrdir/emonpi/update/emoncmsdbupdate.php
