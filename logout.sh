#!/bin/bash

#######################################################################
#
#   Esborrat de les dades d'usuari a les estacions dels PuntTIC/Òmnia 
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
#   along with this program.  If not, see <http://www.gnu.org/licenses

# Restaura el perfil
function restauraPerfil {
    rm -Rf /home/$1
    # Si aquesta màquina utilitza una configuració compartida i hi
    # ha una carpeta de perfil, es fa servir aquesta
    if [ $SHARED_CONFIG -ne 0 ] && [ -d ${SHARED_CLIENT_DIR}/perfil ]
    then 
        # PERFIL=${SHARED_CLIENT_DIR}/perfil
        PERFIL=/home/perfil
    else
        PERFIL=/home/perfil
    fi
    cp -rT ${PERFIL} /home/$1
    chown -R $1:$1 /home/$1
}

# Crea el perfil
function creaPerfilCompartit {
    rm -Rf ${SHARED_SETTINGS_DIR}/$USER
    cp -rT /home/$USER ${SHARED_SETTINGS_DIR}/$USER
    chown -R $USER:$USER ${SHARED_SETTINGS_DIR}/$USER   
}

# Es carreguen les funcions d'utilitat de PuntTIC
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/punttic-utils.sh
# Es llegeix la configuració de l'estació
readSettings

## Si se'ns passa una relació d'usuaris a la línia de comandes, els
## restaurem la home al contingut de perfil
if [ $# -ge 1 ]
then
    for i in $@
    do 
        restauraPerfil $i 
    done
    exit 0
fi

GRP=( $(id -nG $USER) )
if [[ "${GRP[@]}" =~ "congelat" ]]
then
    restauraPerfil $USER
    exit 0
fi

case $USER in
  ciutadania | curs)
    # Quan un usuari (usuari o curs) finalitza la sessió, s'esborra
    # el contingut de la carpeta on estava treballant i se substitueix
    # pel patró que es troba a perfil
    
    echo "$(date) - $USER surt de la sessió"  >> /tmp/sessions
    restauraPerfil $USER
    ;;
    
  perfil)
    # Si estem a la màquina de la persona dinamitzadora i té la configuració
    # compartida, copiarem perfil a la carpeta compartida
    if [ "$TYPE" == "dinamitzacio" ] && (( SAMBA_SERVER && SAMBA_SHARE_CONFIG ))
    then
        creaPerfilCompartit   
    fi
    ;;
    
  *)
    echo
    ;;
esac
