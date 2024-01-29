#!/bin/bash

#
# This is an example script that will show you the recommend way to create a 
# FOG post install script. There are many ways you can go about this, some will be better than 
# others. 
#
# See also https://forums.fogproject.org/topic/7740/the-magical-mystical-fog-post-download-script/15

# funcs.sh provides access to:
#ftp		# IP Address from Storage Management-General
#hostname	# Host Name from Host Managment-General
#img		# Image Name from Image Management-General
#mac		# Primary MAC from Image Management-General
#osid		# Host Image Index number from Image Management-General
#storage	# IP Address + Image Path from Storage Management-General
#storageip	# IP Address from Storage Management-General
#web		#IP Address + Web root from Storage Management-General
. /usr/share/fog/lib/funcs.sh


if [[ ! -z $mac ]]; then
    curl -A "" -Lkso /tmp/hinfo.sh ${web}/fog/service/hostinfo.php -d "mac=$mac"
    if [[ -f /tmp/hinfo.sh ]]; then
        . /tmp/hinfo.sh
    fi
fi

#After running the above script these additional variables are available for use in your post install script.

#shutdown	# Shut down at the end of imaging
#hostdesc	#Host Description from Host Managment-General
#hostip		# IP address of the FOS client
#hostimageid	# ID of image being deployed
#hostbuilding	# ??
#hostusead	# Join Domain after image task from Host Management-Active Directory
#hostaddomain	# Domain name from Host Management-Active Directory
#hostaduser	# Domain Username from Host Management-Active Directory
#hostadou	# Organizational Unit from Host Management-Active Directory
#hostproductkey=	# Host Product Key from Host Management-Active Directory
#imagename	# Image Name from Image Management-General
#imagedesc	# Image Description from Image Management-General
#imageosid	# Operating System from Image Management-General
#imagepath	# Image Path from Image Management-General (/images/ assumed)
#primaryuser	# Primary User from Host Management-Inventory
#othertag	# Other Tag #1 User from Host Management-Inventory
#othertag1	# Other Tag #2 from Host Management-Inventory
#sysman		# System Manufacturer from Host Management-Inventory (from SMBIOS)
#sysproduct	# System Product from Host Management-Inventory (from SMBIOS)
#sysserial	# System Serial Number from Host Management-Inventory (from SMBIOS)
#mbman		# Motherboard Manufacturer from Host Management-Inventory (from SMBIOS)
#mbserial	# Motherboard Serial Number from Host Management-Inventory (from SMBIOS)
#mbasset		# Motherboard Asset Tag from Host Management-Inventory (from SMBIOS)
#mbproductname	# Motherboard Product Name from Host Management-Inventory (from SMBIOS)
#caseman		# Chassis Manufacturer from Host Management-Inventory (from SMBIOS)
#caseserial	# Chassis Serial from Host Management-Inventory (from SMBIOS)
#caseasset	# Chassis Asset from Host Management-Inventory (from SMBIOS)
#location	# Host Location (name) from Host Management-General


# HTTP GET sample
# wget -q -O /tmp/hinfo.txt "http://${web}service/hostinfo.php?mac=$mac"

# HTTP POST sample
# snpchk=`wget -O - --post-data="mac=${mac}" "http://${web}service/snapcheck.php" 2>/dev/null`
echo ""
echo "postdownpath=${postdownpath}"
echo "Calling update inventory script";
debugPause

#FIXME: hack to update DNS server
echo "nameserver 192.168.24.1" >> /etc/resolv.conf

#TAG=231001
#TAG=$mbasset
#TAG=$othertag
TAG=$hostname
BRAND=$sysman
MODEL=$sysproduct
#SERIAL_NUMBER=123456
SERIAL_NUMBER=$sysserial
MODEL_NAME="$BRAND-$MODEL"
${postdownpath}update-inventory.sh $TAG $SERIAL_NUMBER $MODEL_NAME
