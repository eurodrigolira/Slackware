#!/bin/bash
#
# Autor: Rodrigo Lira
# E-mail: eurodrigolira@gmail.com
# Blog:	https://rodrigolira.eti.br
#
# Este script instala o Zabbix Server 5.2 no Slackware Linux Current. 
#
# Use este script se o servidor for dedicado apenas para o Zabbix, não aconselho o uso do mesmo junto com outros serviços,  
# caso esteja rodando mais algum serviço, leia o script e entenda o que ele faz e adeque de acordo com as suas necessidades.
#
# DEFINIÇÕES DAS VARIÁVEIS
#
VERSION="5.2.5"
URL="https://cdn.zabbix.com/zabbix/sources/stable/5.2/"
ZABBIX="$URL/zabbix-$VERSION.tar.gz"
DIR="/tmp"
LOG="$DIR/zabbix-install.log"
TIMEZONE="America\/Recife"
RC_FILE="https://raw.githubusercontent.com/eurodrigolira/Slackware/master/Zabbix/slackware-current/zabbix-$VERSION/zabbix-server/rc.zabbix_server"
echo -e "\e[32m+---------------------------------------------------+"
echo -e "|        INSTALAÇÃO DO ZABBIX SERVER $VERSION NO       |"
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
echo -e "[\e[32m+\e[0m] Fazendo o download do Zabbix Server $VERSION.\e[96m" 
cd $DIR
wget --quiet $ZABBIX
#
echo -e "\e[0m[\e[32m+\e[0m] Descompactanto o Zabbix Server."
tar xzf zabbix-$VERSION.tar.gz
cd zabbix-$VERSION
#
echo -e "[\e[32m+\e[0m] Instalando o Zabbix Server."
./configure \
  --prefix=/usr \
  --sysconfdir=/etc/zabbix \
  --datadir=/etc \
  --localstatedir=/var/lib \
  --mandir=/usr/man \
  --docdir=/usr/doc/zabbix-$VERSION \
  --libdir=/usr/lib64 \
  --enable-server \
  --with-mysql \
  --with-libcurl \
  --with-net-snmp \
  --with-ssh2 \
  --with-ldap \
  --with-ipv6 \
  --with-libxml2 \
  &>> $LOG
make install &>> $LOG
#
echo -e "[\e[32m+\e[0m] Configurando e iniciando MySQL Server."
mysql_install_db --user=mysql &>> $LOG
chown -R mysql.mysql /var/lib/mysql
chmod +x /etc/rc.d/rc.mysqld
/etc/rc.d/rc.mysqld start &>> $LOG
#
echo -e "[\e[32m+\e[0m] Configurações de usuário e senha para o banco de dados MySQL."
#
echo -e "\e[33m+--------------------------------------------------+"
echo -e "| DIGITE A SENHA DO USUÁRIO ROOT DO BANCO DE DADOS |"
echo -e "+--------------------------------------------------+\e[0m"
read PASS_ROOTDB
echo -e "\e[33m+------------------------------------------------------+"
echo -e "| DIGITE O NOME DO BANCO DE DADOS PARA O ZABBIX SERVER |"
echo -e "+------------------------------------------------------+\e[0m"
read DB_NAME
echo -e "\e[33m+-------------------------------------------------------------+"
echo -e "| DIGITE O NOME DO USUARIO DO BANCO DE DADOS DO ZABBIX SERVER |"
echo -e "+-------------------------------------------------------------+\e[0m"
read MYSQL_USER
echo -e "\e[33m+--------------------------------------------------------------+"
echo -e "| DIGITE A SENHA DO USUARIO DO BANCO DE DADOS DO ZABBIX SERVER |"
echo -e "+--------------------------------------------------------------+\e[0m"
read PASS_MYSQL_USER
#
echo -e "\e[0m[\e[32m+\e[0m] Criando o banco de dados, usuário e configurando as permissões."
/usr/bin/mysqladmin -u root password "$PASS_ROOTDB"
mysql -u root -p$PASS_ROOTDB -e "create database $DB_NAME character set utf8 collate utf8_bin;"
mysql -u root -p$PASS_ROOTDB -e "grant all on zabbix.* to $MYSQL_USER@localhost identified by '$PASS_MYSQL_USER';"
mysql -u root -p$PASS_ROOTDB -e "flush privileges;"
#
echo -e "[\e[32m+\e[0m] Configurando o banco de dados do Zabbix Server."
mysql -u root -p$PASS_ROOTDB $DB_NAME < database/mysql/schema.sql
mysql -u root -p$PASS_ROOTDB $DB_NAME < database/mysql/images.sql
mysql -u root -p$PASS_ROOTDB $DB_NAME < database/mysql/data.sql
#
echo -e "[\e[32m+\e[0m] Configurando o arquivo /etc/php.ini."
sed -i "s/;date\.timezone =/date.timezone = $TIMEZONE/" /etc/php.ini
sed -i "s/post_max_size = 8M/post_max_size = 16M/" /etc/php.ini
sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php.ini
sed -i "s/max_input_time = 60/max_input_time = 300/" /etc/php.ini
#
echo -e "[\e[32m+\e[0m] Configurando o HTTPd."
sed -i "s/#ServerName www\.example\.com:80/ServerName $HOSTNAME:80/" /etc/httpd/httpd.conf
sed -i "s/DirectoryIndex index\.html/DirectoryIndex index.php index.html/" /etc/httpd/httpd.conf
sed -i "s/#Include \/etc\/httpd\/mod_php\.conf/Include \/etc\/httpd\/mod_php.conf/" /etc/httpd/httpd.conf
#
echo -e "[\e[32m+\e[0m] Copiando o frontend do Zabbix Server para o diretório /var/www/htdocs."
rm -rf /var/www/htdocs/*
cp -R ui/* /var/www/htdocs/
chown -fR apache:apache /var/www/htdocs/
#
echo -e "[\e[32m+\e[0m] Criando o diretório de logs e definindo as permissões."
mkdir /var/log/zabbix/
touch /var/log/zabbix/zabbix_server.log
chown -fR zabbix:zabbix /var/log/zabbix/
#
echo -e "[\e[32m+\e[0m] Configurando o arquivo zabbix_server.conf."
sed -i "s/LogFile=\/tmp\/zabbix_server\.log/LogFile=\/var\/log\/zabbix\/zabbix_server.log/" /etc/zabbix/zabbix_server.conf
sed -i "s/DBName=zabbix/DBName=$DB_NAME/" /etc/zabbix/zabbix_server.conf
sed -i "s/DBUser=zabbix/DBUser=$MYSQL_USER/" /etc/zabbix/zabbix_server.conf
sed -i "s/# DBPassword=/DBPassword=$PASS_MYSQL_USER/" /etc/zabbix/zabbix_server.conf
#
echo -e "[\e[32m+\e[0m] Iniciando o HTTPd."
chmod +x /etc/rc.d/rc.httpd
/etc/rc.d/rc.httpd start
#
echo -e "[\e[32m+\e[0m] Copiando o rc.zabbix_server para o /etc/rc.d."
wget $RC_FILE -O /etc/rc.d/rc.zabbix_server --quiet
chmod +x /etc/rc.d/rc.zabbix_server
#
echo -e "[\e[32m+\e[0m] Iniciando o Zabbix Server."
/etc/rc.d/rc.zabbix_server start &>> $LOG
#
echo -e "\e[32m+--------------------------------------------------------------+"
echo -e "|     INSTALAÇÃO DO ZABBIX SERVER REALIZADA COM SUCESSO        |"
echo -e "+--------------------------------------------------------------+\e[0m"
