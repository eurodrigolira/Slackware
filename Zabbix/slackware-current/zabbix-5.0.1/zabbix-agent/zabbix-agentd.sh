#!/bin/bash
#
# Autor: Rodrigo Lira
# E-mail: eurodrigolira@gmail.com
# Blog:	https://rodrigolira.eti.br
#
# Este script instala o Zabbix Agent 5 no Slackware Linux Current. 
#
# DEFINIÇÕES DAS VARIÁVEIS
#
VERSION="5.0.1"
ZABBIX="https://cdn.zabbix.com/zabbix/sources/stable/5.0/zabbix-$VERSION.tar.gz"
DIR="/tmp"
LOG="$DIR/zabbix-install.log"
#
echo -e "\e[32m+---------------------------------------------------+"
echo -e "|        INSTALAÇÃO DO ZABBIX AGENT $VERSION NO        |"
echo -e "|              SLACKWARE LINUX CURRENT              |"
echo -e "|                                                   |"
echo -e "|               DÚVIDAS E SUGESTÕES                 |"
echo -e "|         E-mail: eurodrigolira@gmail.com           |"
echo -e "|         Blog: https://rodrigolira.eti.br          |"
echo -e "+---------------------------------------------------+\e[0m"
#
echo -e "[\e[32m+\e[0m] Criando usuário e grupo do Zabbix."

if [ "$(grep zabbixagent /etc/passwd)" = "" -o "$(grep zabbixagent /etc/group)" = "" ] ; then
	groupadd -g 266 zabbixagent && useradd -u 266 -g zabbixagent -d /dev/null -s /bin/false zabbix
else
	echo -e "[\e[32m!\e[0m] Usuário e grupo do Zabbix já existem."
fi
#
echo -e "[\e[32m+\e[0m] Fazendo o download do Zabbix Agent $VERSION.\e[96m" 
cd $DIR
wget --quiet $ZABBIX
#
echo -e "\e[0m[\e[32m+\e[0m] Descompactanto o Zabbix Agent."
tar xzf zabbix-$VERSION.tar.gz
cd zabbix-$VERSION
#
echo -e "[\e[32m+\e[0m] Instalando o Zabbix Agent."
./configure \
  --prefix=/usr \
  --sysconfdir=/etc/zabbix \
  --localstatedir=/var/lib \
  --mandir=/usr/man \
  --docdir=/usr/doc/zabbix-$VERSION \
  --libdir=/usr/lib64 \
  --enable-agent \
  &>> $LOG
make install &>> $LOG
#
echo -e "[\e[32m+\e[0m] Copiando o rc.zabbix_agentd para o /etc/rc.d."
cp rc.zabbix_agentd /etc/rc.d/ 
chmod +x /etc/rc.d/rc.zabbix_agentd
#
echo -e "[\e[32m+\e[0m] Iniciando o Zabbix Agent."
/etc/rc.d/rc.zabbix_agentd start &>> $LOG
#
echo -e "\e[32m+--------------------------------------------------------------+"
echo -e "|      INSTALAÇÃO DO ZABBIX AGENT REALIZADA COM SUCESSO        |"
echo -e "+--------------------------------------------------------------+\e[0m"
