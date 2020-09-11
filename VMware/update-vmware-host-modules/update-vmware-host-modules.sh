#/bin/bash
#
# Autor: Rodrigo Lira
# E-mail: eurodrigolira@gmail.com
# Blog: https://rodrigolira.eti.br
#
# VARIAVÉIS
#
VMWARE_VERSION=`vmware -v | cut -d " " -f 3`
KERNEL_VERSION=`uname -r | cut -d "." -f 1,2`
DIR='/tmp/vmware-host-modules'
URL='https://github.com/mkubecek/vmware-host-modules/archive/'
#
if [ ! -e /usr/bin/vmware ]; then
	echo "VMware Workstation/Player not installed"
	exit 0
fi
#
if [ -d $DIR ]; then
	rm -rf $DIR/* && cd $DIR
else	
	mkdir $DIR && cd $DIR
fi 
#
if [ $? -eq 0 ]; then
	wget $URL\w$VMWARE_VERSION\-k$KERNEL_VERSION\.tar.gz \
	&& tar -xzvf w$VMWARE_VERSION-k$KERNEL_VERSION\.tar.gz
fi
#
if [ $? -eq 0 ]; then
	cd vmware-host-modules-w$VMWARE_VERSION-k$KERNEL_VERSION
else
	exit 0
fi
#
if [ $? -eq 0 ]; then
	make && make install
else
	exit 0
fi
#
if [ -x /etc/init.d/vmware ]; then
  /etc/init.d/vmware start
fi
#

