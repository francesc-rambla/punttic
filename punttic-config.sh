#!/bin/bash

#######################################################################
#
#   Configuració de les estacions dels PuntTIC/Òmnia 
#   (c) 2020 Generalitat de Catalunya
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>. 
#

ENV=./env
[ -e $ENV ] && source $ENV

# Es carreguen les funcions d'utilitat de PuntTIC
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/punttic-utils.sh

# Es llegeix la configuració de l'estació
readSettings

# Fitxers de configuració
PROXY_CONFIG_FILE=/etc/apt/apt.conf.d/95proxy
ENVIRONMENT_FILE=/etc/environment
HOSTS_FILE=/etc/hosts
FSTAB_FILE=/etc/fstab
SAMBA_CONF_FILE=/etc/samba/smb.conf

# Paràmetres de configuració
CONNECTION_NAME=ConnexioPuntTIC
SAMBA_USER=dinamitzacio
SAMBA_GROUP=dinamitzacio
SAMBA_MODELS_DIR=/home/$SAMBA_USER/Públic/models
SAMBA_TALLERS_DIR=/home/$SAMBA_USER/Públic/tallers
SAMBA_PRIVATE_DIR=/home/$SAMBA_USER/Imatges/confidencial
MODELS_MOUNTPOINT=/media/models
TALLERS_MOUNTPOINT=/media/tallers
MOUNT_USER=curs.curs

DEFAULTBACKGROUND=$PUNTTIC/images/fonspantalla.png
OMNIABACKGROUND=$PUNTTIC/images/fonspantalla_omnia.png
PUNTTICBACKGROUND=$PUNTTIC/images/fonspantalla_punttic.png

DEFAULTHOMEPAGE=$PUNTTIC/redirect.html
DEFAULTOMNIA=$PUNTTIC/redirect-omnia.html
DEFAULTPUNTTIC=$PUNTTIC/redirect-punttic.html

PUPPET_SERVERIP=88.198.97.147

##
# setHostname
#
# setHostname <hostname>

function setHostname {
    if (( ! DEBUG ))
    then
        hostnamectl set-hostname $1
        sed -i -e "s/127\.0\.1\.1.*/127\.0\.1\.1\t$1/" $HOSTS_FILE
    else
        echo "Fixant el nom de l'estació a $1"
    fi
}

##
# Configura el proxy de sistema a través de les variables d'entorn
#
# setEnvironmentProxyConfig <ip_proxy> <port_proxy> <fitxer_environment>

function setEnvironmentProxyConfig {
  read -d '' PROXY_CONFIG <<EO
http_proxy=http://system:system@$1:$2/
https_proxy=http://system:system@$1:$2/
ftp_proxy=http://system:system@$1:$2/
no_proxy='localhost,127.0.0.1,localaddress,.localdomain.com'

HTTP_PROXY=http://system:system@$1:$2/
HTTPS_PROXY=http://system:system@$1:$2/
FTP_PROXY=http://system:system@$1:$2/
NO_PROXY='localhost,127.0.0.1,localaddress,.localdomain.com'
EO
  removePuntTIC $3
  insertPuntTIC "$PROXY_CONFIG" $3
}

##
# Configura el proxy per l'APT
#
# setAptProxyConfig <ip_proxy> <port_proxy> <fitxer_environment>

function setAptProxyConfig {
  read -d '' PROXY_CONFIG <<EO
Acquire::http::proxy "http://system:system@$1:$2";
Acquire::https::proxy "http://system:system@$1:$2";
Acquire::ftp::proxy "http://system:system@$1:$2";
EO
  removePuntTIC $3
  insertPuntTIC "$PROXY_CONFIG" $3
}

##
# Configura el proxy de sistema
#
#´
function setSystemProxy {
  read -d '' PROXY_CONFIG <<EO
[system/proxy]
mode='manual'

[system/proxy/http]
host="$1"
port=$2
use-authentication=true
authentication-user='system'
authentication-password='system'

[system/proxy/https]
host="$1"
port=$2
use-authentication=true
authentication-user='system'
authentication-password='system'

[system/proxy/ftp]
host="$1"
port=$2
use-authentication=true
authentication-user='system'
authentication-password='system'
EO
    if (( ! DEBUG ));
    then
        [ ! -e /etc/dconf/profile/user ] && echo -e "user-db:user\nsystem-db:local" > /etc/dconf/profile/user
        [ ! -d /etc/dconf/db/local.d ] && mkdir -p /etc/dconf/db/local.d
        removePuntTIC /etc/dconf/db/local.d/95-proxy
        [ -e /etc/dconf/db/local.d/95-proxy.punttic.bak ] && rm /etc/dconf/db/local.d/95-proxy.punttic.bak
        insertPuntTIC "$PROXY_CONFIG" /etc/dconf/db/local.d/95-proxy \
          && dconf update || echo "Actualitzant dconf..."
    fi
}

function clearProxySettings {
      read -d '' PROXY_CONFIG <<EO
[system/proxy]
mode='none'

EO
    removePuntTIC $ENVIRONMENT_FILE
    removePuntTIC $PROXY_CONFIG_FILE
    removePuntTIC /etc/dconf/db/local.d/95-proxy
    [ -e /etc/dconf/db/local.d/95-proxy.punttic.bak ] && rm /etc/dconf/db/local.d/95-proxy.punttic.bak
    [ -e /etc/dconf/db/local.d/95-proxy ] \
      && insertPuntTIC "$PROXY_CONFIG" /etc/dconf/db/local.d/95-proxy \
      && (( ! DEBUG )) && dconf update || echo "Actualitzant dconf..."
}

## 
# Configura la IP del servidor Samba
#
# setSambaServer <server_ip> <hosts_file>

function setSambaServer {
  read -d '' SERVER_HOST <<EO
$PUPPET_SERVERIP	puppet.xarxa-omnia.org	puppet
$1		dinamitzacio
EO
  removePuntTIC $2
  insertPuntTIC "$SERVER_HOST" $2
}

##
# Configura el muntatge de les carpetes compartides
# 
# setSambaMounts

function setSambaMounts {
  read -d '' TALLERS_SHARE_CONFIG <<EO
//dinamitzacio/tallers  $TALLERS_MOUNTPOINT  cifs    user,credentials=/home/dinamitzacio/.credentials,noauto,file_mode=0770,dir_mode=0770,uid=curs,gid=curs,vers=2.0	0	0
EO

  read -d '' MODELS_SHARE_CONFIG <<EO
//dinamitzacio/models  $MODELS_MOUNTPOINT  cifs    user,credentials=/home/dinamitzacio/.credentials,noauto,file_mode=0770,dir_mode=0770,uid=curs,gid=cdrom,vers=2.0	0	0
EO
 
  read -d '' CONFIG_SHARE_CONFIG <<EO
//dinamitzacio/config  $SHARED_CLIENT_DIR cifs    user,credentials=/home/dinamitzacio/.credentials,auto,x-systemd.automount,_netdev,file_mode=0644,dir_mode=0755,uid=dinamitzacio,gid=dinamitzacio,vers=2.0 0	0
EO
  SAMBA_CONFIG=""
  if (( SAMBA_SHARE_TALLERS ))
  then
	  SAMBA_CONFIG="$TALLERS_SHARE_CONFIG"
      [ -d $TALLERS_MOUNTPOINT ] \
      || mkdir -p $TALLERS_MOUNTPOINT \
      && chown $MOUNT_USER $TALLERS_MOUNTPOINT
  fi
  if (( SAMBA_SHARE_MODELS ))
  then
	  SAMBA_CONFIG="${SAMBA_CONFIG}\n\n${MODELS_SHARE_CONFIG}"
      [ -d $MODELS_MOUNTPOINT ] \
      || mkdir -p $MODELS_MOUNTPOINT \
      && chown $MOUNT_USER $MODELS_MOUNTPOINT
  fi	
  if (( SAMBA_SHARE_CONFIG ))
  then
	  SAMBA_CONFIG="${SAMBA_CONFIG}\n\n${CONFIG_SHARE_CONFIG}"
      [ -d $SHARED_CLIENT_DIR ] || mkdir -p $SHARED_CLIENT_DIR
  fi	
  removePuntTIC $1
  insertPuntTIC "$SAMBA_CONFIG" $1
}

function createDefaultSambaConfig {
   read -d '' SAMBA_CONFIG <<EO
##
# Fitxer generat automàticament per l'eina de configuració de PuntTIC/Òmnia
# Els canvis que hi feu a mà es perdran al proper reinici de l'ordinador

[global]
   workgroup = WORKGROUP
   server string = Samba Server %v
   dns proxy = no
   log file = /var/log/samba/log.%m
   max log size = 1000
   syslog = 0
   panic action = /usr/share/samba/panic-action %d
   server role = standalone server
   passdb backend = tdbsam
   obey pam restrictions = yes
   unix password sync = yes
   passwd program = /usr/bin/passwd %u
   passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
   pam password change = yes
   map to guest = bad user
   usershare allow guests = yes

[printers]
   comment = All Printers
   browseable = no
   path = /var/spool/samba
   printable = yes
   guest ok = no
   read only = yes
   create mask = 0700


[print\$]
   comment = Printer Drivers
   path = /var/lib/samba/printers
   browseable = yes
   read only = yes
   guest ok = no

# PUNTTIC
## Configuració específica pels PuntTIC/Òmnia
# PUNTTIC
EO
    [ -e ${SAMBA_CONF_FILE} ] && [ ! -e ${SAMBA_CONF_FILE}.PRE_PUNTTIC ] && cp ${SAMBA_CONF_FILE} ${SAMBA_CONF_FILE}.PRE_PUNTTIC
    echo "$SAMBA_CONFIG" > ${SAMBA_CONF_FILE}
}

## 
# Configura aquesta estació com a servidor de fitxers
#
# setAsASambaServer <smbconf_file>

function setAsASambaServer {
  createDefaultSambaConfig
  read -d '' TALLERS_SHARE_CONFIG <<EO
[tallers]
   comment = Carpeta compartida dels tallers
   path = $SAMBA_TALLERS_DIR
   available = yes
   writeable = yes
   browseable = yes
EO
  read -d '' MODELS_SHARE_CONFIG <<EO
[models]
   comment = Carpeta compartida de models
   path = $SAMBA_MODELS_DIR
   available = yes
   writeable = no
   browseable = yes
EO
 
  read -d '' CONFIG_SHARE_CONFIG <<EO
[config]
   comment = Carpeta de configuració del PuntTIC
   path = $SHARED_SETTINGS_DIR
   available = yes
   writeable = no
   browseable = no
EO
  read -d '' PRIVATE_SHARE_CONFIG <<EO
[confidencial]
    comment = Carpeta compartida per escanejar documentació confidencial
    path = $SAMBA_PRIVATE_DIR
    available = yes
    writable = yes
    browseable = no
EO

  SAMBA_CONFIG=""
  if (( SAMBA_SHARE_MODELS ))
  then
	  SAMBA_CONFIG="$TALLERS_SHARE_CONFIG"
      [ -d $SAMBA_TALLERS_DIR ] \
        || mkdir -p $SAMBA_TALLERS_DIR
      chown $SAMBA_USER.$SAMBA_GROUP $SAMBA_TALLERS_DIR
  fi
  if (( SAMBA_SHARE_TALLERS ))
  then
	  SAMBA_CONFIG="${SAMBA_CONFIG}\n\n${MODELS_SHARE_CONFIG}"
      [ -d $SAMBA_MODELS_DIR ]  \
        || mkdir -p $SAMBA_MODELS_DIR
      chown $SAMBA_USER.$SAMBA_GROUP $SAMBA_MODELS_DIR
  fi	
  if (( SAMBA_SHARE_CONFIG ))
  then
	  SAMBA_CONFIG="${SAMBA_CONFIG}\n\n${CONFIG_SHARE_CONFIG}"
      [ -d $SHARED_SETTINGS_DIR ] || mkdir -p $SHARED_SETTINGS_DIR
  fi	
  if [ "$CENTER_TYPE" == "PuntÒmnia" ]
  then
	  SAMBA_CONFIG="${SAMBA_CONFIG}\n\n${PRIVATE_SHARE_CONFIG}"
      [ -d $SAMBA_PRIVATE_DIR ] || mkdir -p $SAMBA_PRIVATE_DIR
      chown -R $SAMBA_USER.$SAMBA_GROUP $SAMBA_PRIVATE_DIR
  fi
  removePuntTIC $1
  insertPuntTIC "$SAMBA_CONFIG" $1
}

##
# Torna els bits significatius (=1) d'una màscara de subxarxa en el 
# format X.X.X.X (per exemple, per 255.255.255.0 torna 24)
#
# subnetmaskToSuffix <subnet_mask>

function subnetmaskToSuffix {
    c=0 
    x=0$(printf '%o' ${1//./ })
    while [ $x -gt 0 ]
    do
        let c+=$((x%2)) 'x>>=1'
    done
    echo "$c"
}

##
# Crea una nova connexió al NetworkManager amb el nom proporcionat, si
# ja existeix, primer l'esborra i la crea de zero
#
# createEmptyConnection <connection_name>

function createEmptyConnection {
  # Obtenim el nom de dispositiu del primer adaptador de xarxa ethernet
  DEVICE=$(nmcli | grep -G '^\(e.*\): con' | sed -e 's/^\(e.*\):.*$/\1/g')

  if (( ! DEBUG ))
  then
    # Si la connexió existeix, l'esborrem
    nmcli connection delete "$1"
    # Fem una petita pausa per assegurar que s'hagi esborrat i la tornem a crear buida
    sleep 1
    nmcli connection add save yes autoconnect yes type ethernet ifname $DEVICE con-name "$1"
  else
    DEVICE=$(nmcli | grep -G '^\(e.*\): con' | sed -e 's/^\(e.*\):.*$/\1/g')
    echo "Creant connexió amb: nmcli connection add save yes autoconnect yes type ethernet ifname $DEVICE con-name \"$1\""
  fi
}

## 
# Activa la connexió per defecte si existeix
#
# upConnection <NetworkManager_connection-name>

function upConnection {
  nmcli connection show | grep -q "$1"
  if [ $? -eq 0 ]
  then
    if (( !DEBUG ))
    then
        nmcli connection up "$1"
    else
        echo "Aixecant la connexió $1"
    fi
  else
    echo "No s'ha trobat la connexió $1, però intentarem aixecar-la igualment"
    nmcli connection up "$1"
  fi  
}

function modifyConnection {
    CON="$1"
    shift
    if (( ! DEBUG ))
    then
        # echo "Executant: nmcli connection modify \"$CON\" $@"
        nmcli connection modify "$CON" $@
    else
        echo "Executant: nmcli connection modify \"$CON\" $@"
    fi
}

## 
# Configura l'obtenció automàtica d'IP per DHCP
#
# setDHCPNetworking <NetworkManager_connection-name>
function setDHCPNetworking {
    createEmptyConnection "$1"
    modifyConnection "$1" ipv4.method auto ipv6.method auto
    upConnection "$1"
}

## 
# Configura una IP fixa a aquesta estació
#
# setFixedIPNetworking <NetworkManager_connection-name> <ip_address> <subnetmask> <default_gateway> [<dns_server>]
function setFixedIPNetworking {
    createEmptyConnection "$1"
    SUBNET=$(subnetmaskToSuffix $3)
    PARAMS="ipv4.method manual ip4 $2/$SUBNET gw4 $4"
    if [ $# -eq 5 ]; then
        PARAMS="$PARAMS ipv4.dns $5 ipv4.ignore-auto-dns yes"
    fi
    modifyConnection "$1" $PARAMS
    upConnection "$1"
}

##
# Determina la IP d'una estació client a partir del seu nom
#
# getClientIP

function getClientIP {
	if [ "$CLIENT_DHCP" == "Manual" ]
	then
		DHCP="Manual"
		IP_PREFIX=$(echo "$CLIENT_RANGE" | cut -d'.' -f 1,2,3)
		IP_POSTFIX=$(echo "$CLIENT_RANGE" | cut -d'.' -f 4)
		NUM_ESTACIO=${CLIENTNAME:7:2}
        NUM_ESTACIO=$((NUM_ESTACIO-1))
		IP_POSTFIX=$((IP_POSTFIX+NUM_ESTACIO))
		IP_ADDRESS=${IP_PREFIX}.${IP_POSTFIX}
		
		echo "Fixant l'adreça ${IP_ADDRESS} a l'estació ${CLIENTNAME}"
	fi
}

##
# Configura Puppet per a un Punt Òmnia
#
# configurePuppet <codi-estacio>

function configurePuppet {
    if (( DEBUG ));
    then
        echo "Configurant puppet amb el certificat de l'estacio $1"
        exit 0
    fi
    
	if [ "$TYPE" == "dinamitzacio" ] || [ "$SERVERADDRESS" == "" ];
	then
	      read -d '' SERVER_HOST <<EO
127.0.0.1               dinamitzacio
$PUPPET_SERVERIP        puppet.xarxa-omnia.org  puppet
EO
	      removePuntTIC $HOSTS_FILE
	      insertPuntTIC "$SERVER_HOST" $HOSTS_FILE
	fi

    if [ "$CENTER_TYPE" == "PuntÒmnia" ];
    then
        cd /etc/puppetlabs/puppet
        wget https://xarxaomnia.gencat.cat/puppet/$1.tar.bz2
        cd / 
        tar -xjf /etc/puppetlabs/puppet/$1.tar.bz2
        rm /etc/puppetlabs/puppet/$1.tar.bz2
    fi
    
    if [ "$CENTER_TYPE" == "PuntTIC" ];
    then
        cd /etc/puppetlabs/puppet
        PUPPET_ENVIRONMENT=$(echo "$1" | awk -F - '{ print $1 $2 $3 }')
        [ -e puppet.conf ] && grep "$1" puppet.conf
        if [ $? -ne 0 ];
        then
            read -d '' PUPPET_CONF <<EO
[main]
server=puppet.xarxa-omnia.org
certname=$1

[agent]
runinterval=1d 
report=true
environment=$PUPPET_ENVIRONMENT
EO
            echo "${PUPPET_CONF}" > puppet.conf 
            [ -d ssl ] && rm -Rf ssl
        fi 
    fi
    /opt/puppetlabs/puppet/bin/puppet resource service puppet ensure=running enable=true
    /opt/puppetlabs/puppet/bin/puppet agent -t
}

##
# Mostra la interfície gràfica de configuració del PuntTIC
#
# showConfigDialog

function showConfigDialog {
  python3 $PUNTTIC_DLG > /tmp/punttic.cfg
  RESULT=$?
  if (( ! RESULT ));
  then
	mv /tmp/punttic.cfg $SETTINGS
  else
	rm /tmp/punttic.cfg
  fi
  return $RESULT
}

#######################################################################
# Configuració del PuntTIC 
#

[ "$1" == "--apply" ] && APPLY=1 || APPLY=0
[ "$1" == "--update" ] && UPDATE=1 || UPDATE=0

##
# Obrim la interfície gràfica de configuració, excepte si s'ha demanat
# que apliquem la configuració (això es va silenciosament)
if [ "$1" != "--apply" ] && [ "$1" != "--update" ]
then
    showConfigDialog
    if (( $? != 0 )); then
        exit $?
    fi
fi

## 
# Tornem a llegim la configuració amb els paràmetres que s'hagin introduït
readSettings

if [ "$CENTER_TYPE" == "PuntÒmnia" ]
then
    NEWBACKGROUND="$OMNIABACKGROUND"
    NEWHOMEPAGE="$DEFAULTOMNIA"
else
    NEWBACKGROUND="$PUNTTICBACKGROUND"
    NEWHOMEPAGE="$DEFAULTPUNTTIC"
fi

##
# Establim el fons de pantalla, la pàgina d'inici dels navegadors i configurem el puppet
if (( ! DEBUG ))
then
    rm $DEFAULTBACKGROUND
    ln $NEWBACKGROUND $DEFAULTBACKGROUND
    rm $DEFAULTHOMEPAGE
    ln -s $NEWHOMEPAGE $DEFAULTHOMEPAGE
    (( ! UPDATE )) && [ "$HOST_CODE" != "" ] && configurePuppet $HOST_CODE
else
    echo "Canviant el fons d'escriptori a $NEWBACKGROUND"
    echo "Canviant la pàgina d'inici a $NEWHOMEPAGE"
fi

#######################################################################
# Comencem la configuració diferenciant si es tracta d'una estació d'usuari o no

if (( ! UPDATE)); then
    if [ "$TYPE" == "dinamitzacio" ]; then
    #----------------------------------------------------------------------
    # Configuració d'una estació servidora
    
        if (( DEBUG )); then
            echo "Configuració com a estació servidora"
        else
            # Mostra el compte de dinamització al greeter
            sed -i {s/SystemAccount=true/SystemAccount=false/g} /var/lib/AccountsService/users/dinamitzacio
        fi
        
        setHostname $HOSTNAME
        if (( SAMBA_SERVER )) 
        then
            setAsASambaServer $SAMBA_CONF_FILE
            systemctl restart smbd
        fi
        if (( SAMBA_SHARE_CONFIG ))
        then
            cp $SETTINGS $SHARED_SETTINGS
        fi
    else
    #----------------------------------------------------------------------
    # Configuració d'una estació client
    
        if (( DEBUG )); then
           echo "Configuració com a estació client"
        else
            # Amaga el compte de dinamització al greeter
            sed -i {s/SystemAccount=false/SystemAccount=true/g} /var/lib/AccountsService/users/dinamitzacio
        fi
    
        HOSTNAME=$CLIENTNAME
        setHostname $HOSTNAME
         
        if [ "$SERVERADDRESS" != "" ]; 	then
            setSambaServer $SERVERADDRESS $HOSTS_FILE
            setSambaMounts $FSTAB_FILE
        fi
    fi
fi

#######################################################################
# Configuració de la xarxa

if [ "$TYPE" != "dinamitzacio" ];
then
    if (( SHARED_CONFIG ))
    then
        DHCP=$CLIENT_DHCP
        if [ "$CLIENT_DHCP" == "Manual" ]; then
            getClientIP
        fi
    fi
fi

if [ "$DHCP" == "Automàtica" ]; then
	setDHCPNetworking $CONNECTION_NAME
else
    DNS_SERVERS=$( echo "$DNS_SERVERS" | tr ';' ',' )
	setFixedIPNetworking $CONNECTION_NAME $IP_ADDRESS $SUBNETMASK $ROUTER $DNS_SERVERS
fi

if (( PROXY == 1 )); then
	setEnvironmentProxyConfig $PROXY_ADDRESS $PROXY_PORT $ENVIRONMENT_FILE
	setAptProxyConfig $PROXY_ADDRESS $PROXY_PORT $PROXY_CONFIG_FILE
    setSystemProxy $PROXY_ADDRESS $PROXY_PORT
else
    clearProxySettings
fi

# Activem la connexió per defecte (cas que existeixi)
upConnection $CONNECTION_NAME


#######################################################################
# Finalització
if (( DEBUG )); then
    echo "IP: $IP_ADDRESS - Subnet mask: $SUBNETMASK - Router: $ROUTER - DNS: $DNS_ADDRESS"
    echo "PROXY: $PROXY_SERVER:$PROXY_PORT"
    echo "SAMBA SERVER: $SAMBA_SERVER"
fi
