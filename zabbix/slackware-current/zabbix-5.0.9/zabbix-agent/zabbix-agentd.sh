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
VERSION="5.0.9"
ZABBIX="https://cdn.zabbix.com/zabbix/sources/stable/5.0/zabbix-$VERSION.tar.gz"
DIR="/tmp"
LOG="$DIR/zabbix-install.log"
RC_FILE="https://raw.githubusercontent.com/eurodrigolira/Slackware/master/Zabbix/slackware-current/zabbix-$VERSION/zabbix-agent/rc.zabbix_agentd"
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
if [ "$(grep 'zabbix:' /etc/passwd)" = "" -o "$(grep 'zabbix:' /etc/group)" = "" ] ; then
        groupadd -g 228 zabbix && useradd -u 228 -g zabbix -d /dev/null -s /bin/false zabbix
else
        echo -e "[\e[32m!\e[0m] Usuário e grupo do Zabbix já existem."
fi
#
echo -e "[\e[32m+\e[0m] Criando usuário e grupo do Zabbix Agent."
if [ "$(grep 'zabbixagent:' /etc/passwd)" = "" -o "$(grep 'zabbixagent:' /etc/group)" = "" ] ; then
        groupadd -g 266 zabbixagent && useradd -u 266 -g zabbixagent -d /dev/null -s /bin/false zabbixagent
else
        echo -e "[\e[32m!\e[0m] Usuário e grupo do Zabbix Agent já existem."
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
echo -e "[\e[32m+\e[0m] Criando o diretório de logs e definindo as permissões."
if [ -d /var/log/zabbix ] ; then
	touch /var/log/zabbix/zabbix_agentd.log
else
	mkdir /var/log/zabbix/
	touch /var/log/zabbix/zabbix_agentd.log
fi
chown -fR zabbix:zabbix /var/log/zabbix/
#
echo -e "[\e[32m+\e[0m] Copiando o rc.zabbix_agentd para o /etc/rc.d."
wget $RC_FILE -O /etc/rc.d/rc.zabbix_agentd --quiet
chmod +x /etc/rc.d/rc.zabbix_agentd
#
echo -e "[\e[32m+\e[0m] Iniciando o Zabbix Agent."
/etc/rc.d/rc.zabbix_agentd start &>> $LOG
#
echo -e "\e[32m+--------------------------------------------------------------+"
echo -e "|      INSTALAÇÃO DO ZABBIX AGENT REALIZADA COM SUCESSO        |"
echo -e "+--------------------------------------------------------------+\e[0m"
