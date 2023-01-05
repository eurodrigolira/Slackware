#!/bin/bash
#
# Autor: Rodrigo Lira
# E-mail: eurodrigolira@gmail.com
# Blog:	https://rodrigolira.eti.br
# 06/09/2018 - Versão 1.0
#
# Este script instala o Zabbix Server/Agent 3.4.X no Slackware 14.2. 
# O script procura pela versão mais rescente, faz o download e compila o server e agent.
# Use este script se o servidor for dedicado apenas para o Zabbix, não aconselho o uso do mesmo junto com outros serviços,  
# caso esteja rodando mais algum serviço, leia o script e entenda o que ele faz, adeque de acordo com as suas necessidades.
#   
# DEFINIÇÃO DAS VARIÁVEIS
#
DIR="/zabbix-install"
LOG="/zabbix-install/zabbix-install.log"
URL_OPENJDK="https://slackonly.com/pub/packages/14.2-x86_64/development/openjdk/"
OPENJDK=`curl -s $URL_OPENJDK | grep .txz | cut -d \" -f 14 | head -n 1`
#
URL_IKSEMEL="https://slackonly.com/pub/packages/14.2-x86_64/libraries/iksemel/"
IKSEMEL=`curl -s $URL_IKSEMEL | grep .txz | cut -d \" -f 14 | head -n 1`
#
URL_ZABBIX="https://www.zabbix.com/download_sources/"
ZABBIX=`curl -s $URL_ZABBIX | grep sourceforge | grep 3.4.* | cut -d \" -f 2 | head -n 1 | sed -e "s/\/download//g"`
#
echo -e "[\e[32m+\e[0m] Criando usuário e grupo do Zabbix..."
groupadd -g 228 zabbix
useradd -u 228 -g zabbix -d /dev/null -s /bin/false zabbix
#
echo -e "[\e[32m+\e[0m] Criando diretório para instalação..."
mkdir $DIR
cd $DIR
#
echo -e "[\e[32m+\e[0m] Fazendo o download do Zabbix e das dependências...\e[96m" 
wget --quiet --show-progress $URL_OPENJDK$OPENJDK
wget --quiet --show-progress $URL_IKSEMEL$IKSEMEL
wget --quiet --show-progress $ZABBIX
#
echo -e "\e[0m[\e[32m+\e[0m] Fazendo a instalação das dependências...\e[96m"
installpkg --terse $OPENJDK $IKSEMEL
#
echo -e "\e[0m[\e[32m+\e[0m] Descompactanto o Zabbix..."
tar -xzf zabbix-*
cd zabbix-*
#
echo -e "[\e[32m+\e[0m] Instalando o Zabbix..."
./configure --enable-server --enable-agent --with-mysql --enable-ipv6 --with-net-snmp --with-libcurl --with-libxml2 &>> $LOG
make install &>> $LOG
#
echo -e "[\e[32m+\e[0m] Iniciando o banco de dados..."
mysql_install_db &>> $LOG
chown -R mysql.mysql /var/lib/mysql
chmod +x /etc/rc.d/rc.mysqld
/etc/rc.d/rc.mysqld start $>> $LOG
#
echo -e "[\e[32m+\e[0m] Configuração do usuário e senha para o banco de dados MySQL..."
echo -en "\e[33mDIGITE UMA SENHA PARA O USUÁRIO ROOT DO MYSQL:\e[34m "
read PASS_ROOTDB
echo -en "\e[33mDIGITE UM NOME PARA O USUÁRIO DO MYSQL\e[31m(padrão '"zabbix"')\e[33m:\e[34m "
read MYSQL_USER
echo -en "\e[33mDIGITE UMA SENHA DO USUÁRIO DO MYSQL:\e[34m "
read PASS_MYSQL_USER
echo -en "\e[33mDIGITE O NOME DO BANCO DE DADOS QUE VAI SER USADO PELO ZABBIX\e[31m(padrão '"zabbix"')\e[33m:\e[34m "
read DB_NAME
#
echo -e "\e[0m[\e[32m+\e[0m] Criando banco de dados, usuários e configurando as permissões..."
/usr/bin/mysqladmin -u root password "$PASS_ROOTDB"
mysql -u root -p$PASS_ROOTDB -e "create database $DB_NAME character set utf8;"
mysql -u root -p$PASS_ROOTDB -e "grant all on zabbix.* to $MYSQL_USER@localhost identified by '$PASS_MYSQL_USER';"
mysql -u root -p$PASS_ROOTDB -e "flush privileges;"
#
echo -e "[\e[32m+\e[0m] Configurando o banco de dados..."
mysql -u root -p$PASS_ROOTDB $DB_NAME < database/mysql/schema.sql
mysql -u root -p$PASS_ROOTDB $DB_NAME < database/mysql/images.sql
mysql -u root -p$PASS_ROOTDB $DB_NAME < database/mysql/data.sql
#
echo -e "[\e[32m+\e[0m] Configurando o php.ini..."
sed -i "s/;date\.timezone =/date.timezone = America\/Recife/" /etc/php.ini
sed -i "s/post_max_size = 8M/post_max_size = 16M/" /etc/php.ini
sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php.ini
sed -i "s/max_input_time = 60/max_input_time = 300/" /etc/php.ini
sed -i "s/;always_populate_raw_post_data = -1/always_populate_raw_post_data = -1/" /etc/php.ini
#
echo -e "[\e[32m+\e[0m] Configurando o httpd.conf..."
sed -i "s/#ServerName www\.example\.com:80/ServerName $HOSTNAME:80/" /etc/httpd/httpd.conf
sed -i "s/DirectoryIndex index\.html/DirectoryIndex index.php index.html/" /etc/httpd/httpd.conf
sed -i "s/#Include \/etc\/httpd\/mod_php\.conf/Include \/etc\/httpd\/mod_php.conf/" /etc/httpd/httpd.conf
#
echo -e "[\e[32m+\e[0m] Copiando o frontend do zabbix para o htdocs..."
rm -rf /var/www/htdocs/*
cp -R frontends/php/* /var/www/htdocs/
chown -fR apache:apache /var/www/htdocs/
#
echo -e "[\e[32m+\e[0m] Criando a pasta de logs..."
mkdir /var/log/zabbix
chown -fR zabbix.zabbix /var/log/zabbix
#
echo -e "[\e[32m+\e[0m] Configurando o arquivo zabbix_server.conf..."
sed -i "s/LogFile=\/tmp\/zabbix_server\.log/LogFile=\/var\/log\/zabbix\/zabbix_server.log/" /usr/local/etc/zabbix_server.conf
sed -i "s/# LogFileSize=1/LogFileSize=1/" /usr/local/etc/zabbix_server.conf
sed -i "s/# DebugLevel=3/DebugLevel=3/" /usr/local/etc/zabbix_server.conf
sed -i "s/# DBHost=localhost/DBHost=localhost/" /usr/local/etc/zabbix_server.conf
sed -i "s/DBName=zabbix/DBName=$DB_NAME/" /usr/local/etc/zabbix_server.conf
sed -i "s/DBUser=zabbix/DBUser=$MYSQL_USER/" /usr/local/etc/zabbix_server.conf
sed -i "s/# DBPassword=/DBPassword=$PASS_MYSQL_USER/" /usr/local/etc/zabbix_server.conf
#
echo -e "[\e[32m+\e[0m] Configurando o arquivo zabbix_agentd.conf..."
sed -i "s/LogFile=\/tmp\/zabbix_agentd\.log/LogFile=\/var\/log\/zabbix\/zabbix_agent.log/" /usr/local/etc/zabbix_agentd.conf
sed -i "s/# LogFileSize=1/LogFileSize=1/" /usr/local/etc/zabbix_agentd.conf
sed -i "s/# DebugLevel=3/DebugLevel=3/" /usr/local/etc/zabbix_agentd.conf
sed -i "s/# StartAgents=3/StartAgents=3/" /usr/local/etc/zabbix_agentd.conf
#
echo -e "[\e[32m+\e[0m] Criando os links simbólicos para o /etc/zabbix..."
mkdir /etc/zabbix
ln -s /usr/local/etc/zabbix* /etc/zabbix
#
echo -e "[\e[32m+\e[0m] Iniciando o httpd..."
chmod +x /etc/rc.d/rc.httpd
/etc/rc.d/rc.httpd start
#
echo -e "[\e[32m+\e[0m] Copiando o rc.zabbix_server para o /etc/rc.d..."
wget --quiet https://gitlab.com/eurodrigolira/slackware/raw/master/zabbix/3.4.x/rc.zabbix_server -O /etc/rc.d/rc.zabbix_server
chmod +x /etc/rc.d/rc.zabbix_server
#
echo -e "[\e[32m+\e[0m] Copiando o rc.zabbix_agent para o /etc/rc.d..."
wget --quiet https://gitlab.com/eurodrigolira/slackware/raw/master/zabbix/3.4.x/rc.zabbix_agent -O /etc/rc.d/rc.zabbix_agent
chmod +x /etc/rc.d/rc.zabbix_agent
#
echo -e "[\e[32m+\e[0m] Iniciando o Zabbix Server..."
/usr/local/sbin/zabbix_server
#
echo -e "[\e[32m+\e[0m] Iniciando o Zabbix Agent..."
/usr/local/sbin/zabbix_agentd
echo -e "[\e[32m+\e[0m] Instalação do Zabbix Server/Agent concluída..."
