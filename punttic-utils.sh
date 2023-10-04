#!/bin/bash

#######################################################################
#
#   Configuració de les estacions dels PuntTIC/Òmnia 
#   (c) 2018 Generalitat de Catalunya
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

# Configuració del PuntTIC
if (( ! DEBUG ))
then
    SHARED_CLIENT_DIR=/etc/punttic/cfg
    SHARED_CLIENT_SETTINGS=${SHARED_CLIENT_DIR}/punttic.cfg
    SHARED_SETTINGS_DIR=/etc/punttic/shared
    SHARED_SETTINGS=${SHARED_SETTINGS_DIR}/punttic.cfg
    SETTINGS=/etc/punttic/punttic.cfg
    PUNTTIC=/opt/punttic
    PUNTTIC_DLG=$PUNTTIC/bin/punttic-config.py
else
    SHARED_CLIENT_SETTINGS=./punttic/cfg/punttic.cfg
    SHARED_SETTINGS=./punttic/shared/punttic.cfg
    SETTINGS=./punttic/punttic.cfg
    PUNTTIC=.
    PUNTTIC_DLG=./punttic-config.py
fi


# Fitxers de configuració
PROXY_CONFIG_FILE=/etc/apt/apt.conf.d/95proxy
ENVIRONMENT_FILE=/etc/environment
HOSTS_FILE=/etc/hosts
SAMBA_CONF_FILE=/etc/samba/smb.conf
CONNECTION_FILE=/etc/NetworkManager/system-connections/ConnexioPuntTIC.nmconnection

DHCP=Automàtica

# Funcions generals

##
# Elimina tot el contingut que hi hagi entre dos comentaris amb el text "# PUNTTIC" inclosos
# els comentaris del fitxer que passem com a paràmetre
#
# removePuntTIC <nom_fitxer>
function removePuntTIC {
    [ ! -e $1 ] && return 0
    [ ! $DEBUG ] && [ ! -e $1.punttic.bak ] && cp $1 $1.punttic.bak
    if (( DEBUG ))
    then
        TEMPFILE=$(tempfile --prefix=punttic)
        cp $1 $TEMPFILE
        gawk -i inplace -v PUNTTIC=1 -- '{if ( $0 == "# PUNTTIC") PUNTTIC=!PUNTTIC; else if ( PUNTTIC ) print $0; }' $TEMPFILE
        cat $TEMPFILE
        rm $TEMPFILE
    else
        gawk -i inplace -v PUNTTIC=1 -- '{if ( $0 == "# PUNTTIC") PUNTTIC=!PUNTTIC; else if ( PUNTTIC ) print $0; }' $1
    fi
}

##
# Insereix el text indicat com a primer paràmetre al final del fitxer indicat com a segon
# paràmetre, delimitat per dos comentaris amb el text "# PUNTTIC"
#
# insertPuntTIC <text-a-afegir> <nom_fitxer>

function insertPuntTIC {
    if (( DEBUG )); then
        echo -e "$2 ++++\n\n# PUNTTIC\n$1\n# PUNTTIC"
    else
        echo -e "# PUNTTIC\n$1\n# PUNTTIC" >> $2
    fi
}

## 
# Llegeix els fitxers de configuració
#
# readSettings

function readSettings {
    if (( DEBUG )); then 
        echo -e "Configuració \n$(cat $SETTINGS)"
    fi
    # Establim la configuració per defecte, cas que no hi hagi fitxer de configuració
    TYPE="ciutadania"; export TYPE
    HOSTNAME="estacio01"; export HOSTNAME
    SERVERADDRESS=""; export SERVERADDRESS
    CLIENTNAME="estacio01"; export CLIENTNAME
    SHARED_CONFIG="0"; export SHARED_CONFIG
    SAMBA_SHARE_MODELS="1"; export SAMBA_SHARE_MODELS
    SAMBA_SHARE_TALLERS="1"; export SAMBA_SHARE_TALLERS
    SAMBA_SHARE_CONFIG="1"; export SAMBA_SHARE_CONFIG
    SAMBA_SERVER="0"; export SAMBA_SERVER
    DHCP="Automàtica"; export DHCP
    IP_ADDRESS="192.168.1.100"; export IP_ADDRESS
    SUBNETMASK="255.255.255.0"; export SUBNETMASK
    ROUTER="192.168.1.1"; export ROUTER
    DNS_SERVERS="8.8.8.8,8.8.4.4"; export DNS_SERVERS
    CLIENT_DHCP="Automàtica"; export CLIENT_DHCP
    CLIENT_RANGE=""; export CLIENT_RANGE
    PROXY="0"; export PROXY
    PROXY_ADDRESS=""; export PROXY_ADDRESS
    PROXY_PORT=""; export PROXY_PORT
    AUTOLOGOUT="0"; export AUTOLOGOUT
    AUTOLOGOUT_TIMEOUT="30"; export AUTOLOGOUT_TIMEOUT
    AUTOLOGOUT_USERNAME="ciutadania"; export AUTOLOGOUT_USERNAME
    XARXAOMNIA_ENDPOINT="https://xarxaomnia.gencat.cat/puppet/dadespunts.json"; export XARXAOMNIA_ENDPOINT
    
    [ -e $SETTINGS ] && source $SETTINGS

    if [ $SHARED_CONFIG -ne 0 ] && [ "$TYPE" == "ciutadania" ]
    then
        if (( DEBUG )); then 
            echo -e "Configuració compartida \n$(cat $SHARED_CLIENT_SETTINGS)"
        fi
        [ -e $SHARED_CLIENT_SETTINGS ] && source $SHARED_CLIENT_SETTINGS
        [ -e $SETTINGS ] && source $SETTINGS
    fi
}

if [ "$1" == "--show" ]
then
    OLDDEBUG=$DEBUG
    DEBUG=1
    readSettings
    DEBUG=OLDDEBUG
fi
