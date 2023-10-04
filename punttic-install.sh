#!/bin/bash

#######################################################################
#
#   Instal·lació de les estacions dels PuntTIC/Òmnia 
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

######################################################################
# Llegim el fitxer de configuració

CONFIG=./punttic.cfg
ENV=./env
source $ENV
source $CONFIG

######################################################################
# Funcions de suport

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)

col=80

function errcho {
    >&2 echo "$@"
}

function logError {
    printf '%s%s%*s%s\n' "$@" "$RED" $col "[ERROR]" "$NORMAL"
    echo "[FAIL] $@" >> /tmp/punttic-install.log
}

function logSuccess {
    printf '%s%s%*s%s\n' "$@" "$GREEN" $col "[OK]" "$NORMAL"    
    echo "[OK]   $@" >> /tmp/punttic-install.log
}

LASTFUNCTION=""
function runCommand {
  if (( ! DEBUG )); then
    COMMAND="$@"
    eval $COMMAND 2>> /tmp/punttic-install-error.log
    if [ $? -eq 0 ]
    then
        logSuccess "$@"
    else
        logError "$@"
    fi
  else
    F=${FUNCNAME[1]}
    if [ "$F" == "$LASTFUNCTION" ]; then
      errcho -e "\t$@"
    else
      errcho -e "----------------------------------------------------------------"
      errcho -e "|$F"
      errcho -e "----------------------------------------------------------------"
      errcho -e "\t$@"
      LASTFUNCTION=$F
    fi
  fi
}

##
# newStage stageName
function newStage {
  if (( $DEBUG == 0 )); then
    clear
  fi
  echo ""
  echo "################################################################"
  echo " $1"
  echo "################################################################"
  echo ""
}

##
# getRoleGroups role
function getRoleGroups {
   case "$1" in
     admin)
       ROLEGROUPS="$ADMINGROUPS"
       ;;
     user)
       ROLEGROUPS="$USERGROUPS"
       ;;
     nopasswd)
       ROLEGROUPS="$USERGROUPS,nopasswdlogin"
       ;;
   esac
 }
 
##
# addUser user
function addUser {
  # Segons quin sigui el rol de l'usuari, determinem a quins grups ha 
  # ha de pertànyer
  getUserParams $1
  
  # Obtenim els grups als quals haurà de pertànyer l'usuari pel seu rol
  getRoleGroups $ROLE
  
  # Afegim l'usuari
  COMMAND="useradd -m -s /bin/bash -G $ROLEGROUPS $USERNAME"
  runCommand $COMMAND
  
  # Li assignem la contrasenya
  COMMAND="echo \"$USERNAME:$PASSWD\" | /usr/sbin/chpasswd"
  runCommand $COMMAND
  
  # Fem les carpetes d'usuari que corresponguin
  COMMAND="su - $USERNAME -c /usr/bin/xdg-user-dirs-update"
  runCommand $COMMAND
  
  # Copiem els fitxers de configuració generals del compte
  COMMAND="cp -rT $PUNTTICDIR/templates/all/. /home/$USERNAME && chown -R $USERNAME:$USERNAME /home/$USERNAME"
  runCommand $COMMAND
  
  # Copiem els fitxers de configuració que corresponguin segons els rols
  COMMAND="cp -rT $PUNTTICDIR/templates/$ROLE/. /home/$USERNAME && chown -R $USERNAME:$USERNAME /home/$USERNAME"
  runCommand $COMMAND
}

##
# getUserParams user
function getUserParams {
  local IFS="/"
  USUARI=($1)
  USERNAME=${USUARI[0]}
  PASSWD=${USUARI[1]}
  ROLE=${USUARI[2]}
}

##
# createUsers
function createUsers {
  newStage "Creant els usuaris"
  COMMAND="groupadd nopasswdlogin"; runCommand $COMMAND
  for i in "${USUARIS[@]}"
  do
    addUser $i
  done
}

##
# addRepositories
function addRepositories {
  newStage "Afegint els repositoris"	
  for i in "${REPOSITORIES[@]}"
  do
    COMMAND="apt-add-repository -y $i"
    runCommand $COMMAND
  done
}

##
# installDependencies 
function installExternalDependencies {
  newStage "Afegint dependències externes"
  CURRENTDIR=`pwd`
  COMMAND="cd /tmp"; runCommand $COMMAND
  COMMAND="mkdir DEPENDENCIES"; runCommand $COMMAND
  COMMAND="cd DEPENDENCIES"; runCommand $COMMAND
  for i in "${DEPENDENCIES[@]}"
  do
    COMMAND="wget $i"; runCommand $COMMAND
    PACKAGE=`basename $i`
    COMMAND="dpkg -i $PACKAGE"; runCommand $COMMAND
  done
  COMMAND="cd .."; runCommand $COMMAND
  COMMAND="rm -R DEPENDENCIES"; runCommand $COMMAND
  COMMAND="cd \"$CURRENTDIR\""; runCommand $COMMAND
  COMMAND="apt -y --fix-broken install"; runCommand $COMMAND
}

##
# installPackageGroup group
function installPackageGroup {
  local IFS=","
  local PACKAGES=($1)
  INSTALLPKG=""
  for i in "${PACKAGES[@]}"
  do
    if [ "$INSTALLPKG" == "" ]; then
      INSTALLPKG=$i
    else
      INSTALLPKG="$INSTALLPKG $i"
    fi
  done
  COMMAND="apt -y install $INSTALLPKG"; runCommand $COMMAND
}

##
# installPackages
function installPackages {
  newStage "Instal·lant paquets"
  COMMAND ""
  for i in "${SOFTWARE[@]}"
  do
    installPackageGroup $i
  done
}

##
#runCommands
function runCommands {
  local IFS=$'\n'
  for i in "${COMMANDS[@]}"
  do
    COMMAND="$i"; runCommand $COMMAND
  done
}

##
# preInstall
function preInstall {
  newStage "Executant les comandes prèvies a la instal·lació"
  local IFS=$'\n'
  COMMANDS=( "${PRE_COMMANDS[@]}" )
  runCommands
}

##
# postInstall
function postInstall {
  newStage "Executant les comandes posteriors a la instal·lació"
  local IFS=$'\n'
  COMMANDS=( ${POST_COMMANDS[@]} )
  runCommands
}

##
# runCustomCommands
function runCustomCommands {
  newStage "Executant les commandes personalitzades"
  local IFS=$'\n'
  COMMANDS=( ${CUSTOM_COMMANDS[@]} )
  runCommands
}

##
# copyFiles
function copyFiles {
  newStage "Copiant fitxers..."
  COMMAND="cp -a ./root/* /"; runCommand $COMMAND
}

##
# setBackground for current user
function setBackground {
  BACKGROUND=$DEFAULTBACKGROUND
  USERNAME=$1
  case $DESKTOP in
    gnome)
      COMMAND="sudo -Hu $USERNAME dbus-launch gsettings set org.gnome.desktop.background picture-uri file://$BACKGROUND"
      runCommand $COMMAND
      ;;
    xfce)
      COMMAND="rm /usr/share/xfce4/backdrops/xubuntu-wallpaper.png"; runCommand $COMMAND
      COMMAND="ln -s $BACKGROUND /usr/share/xfce4/backdrops/xubuntu-wallpaper.png"
      runCommand $COMMAND
      ;;
  esac
}

##
# setDefaultDesktop for current user
function setDefaultDesktop {
	USERNAME=$1
	ISADMIN=$2
	echo "[User]
Session=
XSession=Ubuntu
Icon=/home/$USERNAME/.face
SystemAccount=$ISADMIN

[InputSource0]
xkb=es+cat" > /var/lib/AccountsService/users/$USERNAME
}

##
# setTheme
function setTheme {
	USERNAME=$1
	COMMAND="sudo -Hu $USERNAME dbus-launch gsettings set org.gnome.desktop.interface gtk-theme ""$DEFAULTGTKTHEME"""
	runCommand $COMMAND
	COMMAND="sudo -Hu $USERNAME dbus-launch gsettings set org.gnome.desktop.interface icon-theme ""$DEFAULTICONTHEME"""
	runCommand $COMMAND
	COMMAND="sudo -Hu $USERNAME dbus-launch gsettings set org.gnome.desktop.wm.preferences theme ""$DEFAULTWINDOWTHEME"""
	runCommand $COMMAND
}

function getFavorites {
    USERNAME=$1
    COMMAND="__FAVS=\"\$(sudo -Hu $USERNAME dbus-launch gsettings get org.gnome.shell favorite-apps)\""
    runCommand $COMMAND
    echo "$__FAVS"
}

function setFavorites {
    USERNAME=$1
    FAVORITES=$2
    COMMAND="sudo -Hu $USERNAME dbus-launch gsettings get org.gnome.shell favorite-apps \"$FAVORITES\""
    runCommand $COMMAND
}

##
# Add favourite app
function addFavorite {
    USERNAME=$1
    FAVORITE=$2
    FAVORITES=$(getFavorites $1)
    FAVORITES="$(echo $FAVORITES | sed -e 's/.$//'), '$FAVORITE']"
    setFavorites "$USERNAME" "$FAVORITES"
}

##
# Customize desktop
function customizeDesktop {
  newStage "Preparant l'escriptori dels usuaris"
  for u in "${USUARIS[@]}"
  do
    getUserParams $u
    for i in "${LAUNCHERS[@]}"
    do
      addFavorite $USERNAME $i
    done
    setBackground $USERNAME
    ISADMIN=`[ "$ROLE" == "admin" ] || [ "$USERNAME" == "perfil" ] && echo "true" || echo "false"`
    if [ "$ROLE" == "admin" ]
    then
        for i in "${ADMIN_LAUNCHERS[@]}"
        do
            addFavorite $USERNAME $i
        done
          
        # Si és un usuari del grup admin, l'afegim a samba
        COMMAND="echo -e \"$SAMBA_PWD\n$SAMBA_PWD\n\" | smbpasswd -a $USERNAME"
        runCommand $COMMAND
        COMMAND="echo -e \"user=$USERNAME\npassword=$SAMBA_PWD\" > /home/$USERNAME/.credentials"
        runCommand $COMMAND
    fi
    setDefaultDesktop $USERNAME $ISADMIN
    setTheme $USERNAME
  done
}


######################################################################
# Instal·lació del PuntTIC

# Executem les comandes prèvies
preInstall

# Copiem els fitxers de la distribució a la seva ubicació real
copyFiles

# Afegim els repositories extra
addRepositories

# Instal·lem les dependències externes
installExternalDependencies

# Instal·lem el programari
installPackages

# Executem les comandes personalitzades
runCustomCommands

# Fem els comptes d'usuari
createUsers

# Amaguem el compte d'usuari de l'administrador
setDefaultDesktop administrador true

# Personalitzem els escriptoris
customizeDesktop

# Executem les comandes post-instal·lació
postInstall
