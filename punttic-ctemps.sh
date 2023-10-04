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


# Es carreguen les funcions d'utilitat de PuntTIC
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${DIR}/punttic-utils.sh
# Es llegeix la configuració de l'estació
readSettings

##
# Fixem la durada d'un segon (si estem en depuració, durarà 100ms)
if (( DEBUG ))
then
    T_MISSATGE=40
else
    T_MISSATGE=1000
fi

OSD="${DIR}/osd.sh"

function logMessage {
    echo "[$(date '+%Y-%m-%d %H:%M')] - $1" >> /tmp/ctemps.log
}

function cincminuts {
  echo -e "En 5 minuts es tancarà la sessió" | ${OSD} --center --middle --huge --green --d $(( 5 * T_MISSATGE ))
  for i in 5 4 3 2
  do
    echo "Queden $i minuts"
    echo -e "Queden $i minuts" | ${OSD} --right -x -10 -y 30 --normal --green --d $(( 60 * T_MISSATGE ))
  done 
}

function darrerminut {
  echo -e "En 1 minut es tancarà la sessió" | ${OSD} --center --middle --huge --red --d $(( 5 * T_MISSATGE ))
  for i in $(seq 55 -1 11)
  do
    echo -e "Queden $i segons"  | ${OSD} --right -x -10 -y 30 --normal --green --d $T_MISSATGE
  done
  
  for i in $(seq 9 -1 0)
  do
    echo -e "Queden $i segons" | ${OSD} --center --middle --huge --red --d $T_MISSATGE
  done  
  echo -e "Tancant la sessió... Fins aviat!" | ${OSD} --center --middle --huge --green --d $(( 5 * T_MISSATGE ))
}

if [ "${DISPLAY}" == "" ]
then
    DISPLAY=:0; export DISPLAY
fi

logMessage "Control de temps iniciat per a $USERNAME"
if [ "$USERNAME" == "$AUTOLOGOUT_USERNAME" ] && [ $AUTOLOGOUT -ne 0 ]
then
    logMessage "Control de temps habilitat per a $USERNAME"
    (( TIMEOUT=AUTOLOGOUT_TIMEOUT - 5 ))
    logMessage "La sessió durarà $(( AUTOLOGOUT_TIMEOUT * 60 * T_MISSATGE / 1000 )) segons"
    sleep $(( TIMEOUT * 60 * T_MISSATGE / 1000 - 5))
    cincminuts
    darrerminut
    
    if (( ! DEBUG ))
    then
        gnome-session-quit --logout --no-prompt
    else
        echo "Ara tancaríem la sessió"
    fi
else
    logMessage "Control de temps no habilitat per a $USERNAME"
fi
