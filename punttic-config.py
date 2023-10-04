#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  punttic-config.py
#
#  Copyright 2020 Generalitat de Catalunya
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#
#
import PySimpleGUI as sg
import os
import unidecode

import requests
from IPy import IP

sg.theme('SystemDefaultForReal')

######################################################################
# Inicialitzacions

width = 45
__DEBUG__ = False

# Paràmetres que llegirem en obrir l'aplicació i desarem en sortir
params = [
    'CENTER_TYPE', 'TYPE', 'HOSTNAME', 'SERVERADDRESS', 'CLIENTNAME',
    'SHARED_CONFIG', 'SAMBA_SHARE_MODELS', 'SAMBA_SHARE_TALLERS',
    'SAMBA_SHARE_CONFIG', 'SAMBA_SERVER',
    'DHCP', 'IP_ADDRESS', 'SUBNETMASK', 'ROUTER', 'DNS_SERVERS', 'CLIENT_DHCP',
    'CLIENT_RANGE', 'PROXY', 'PROXY_ADDRESS', 'PROXY_PORT',
    'AUTOLOGOUT', 'AUTOLOGOUT_TIMEOUT', 'AUTOLOGOUT_USERNAME',
    'XARXAOMNIA_ENDPOINT', 'CENTER_CITY', 'CENTER_NAME', 'CENTER_HOST',
    'HOST_CODE', 'PUNTTIC_NAME'
]

client_params = [
    'CENTER_TYPE', 'TYPE', 'CLIENTNAME', 'SERVERADDRESS', 'IP_ADDRESS',
    'SHARED_CONFIG', 'SAMBA_SHARE_MODELS', 'SAMBA_SHARE_TALLERS',
    'SAMBA_SHARE_CONFIG', 'XARXAOMNIA_ENDPOINT',
    'CENTER_CITY', 'CENTER_NAME', 'CENTER_HOST', 'HOST_CODE'
]

# Relació dels noms d'estació del PuntTIC
estacions = [
    'estacio01', 'estacio02', 'estacio03', 'estacio04', 'estacio05',
    'estacio06', 'estacio07', 'estacio08', 'estacio09', 'estacio10'
]

# Elements que hi ha a la configuració de la IP
tab3_ip_items = ['-IP_ADDRESS-', '-SUBNETMASK-', '-ROUTER-', '-DNS_SERVERS-']

omniaData = []
centerList = []
hostsList = []
citiesList = []
endpoint = False
allowSharedConfig = True

######################################################################
# UI


def initLayout():
    # General tab layout
    tab1_omnia = [
        [sg.Text('Municipi')],
        [sg.Combo(citiesList, size=(width, 1), enable_events=True,
                  key='-CENTER_CITY-')],
        [sg.Text('Nom del centre')],
        [sg.Combo(centerList, size=(width, 1), enable_events=True,
                  key='-CENTER_NAME-')],
        [sg.Text('Nom de l\'estació')],
        [sg.Spin(hostsList, size=(width, 1), enable_events=True,
                 key='-CENTER_HOST-')],
        [sg.InputText(key='-XARXAOMNIA_ENDPOINT-', visible=False,
                      enable_events=False),
         sg.InputText(key='-HOST_CODE-', visible=False, enable_events=False)]
    ]
    tab1_punttic = [
        [sg.Text('Lloc i nom del centre (Municipi - nom del centre)')],
        [sg.InputText(key='-PUNTTIC_NAME-', size=(width, 1),
                      enable_events=True)],
    ]
    tab1_layout = [
        [sg.Text('Tipus de centre')],
        [sg.Combo(['PuntTIC', 'PuntÒmnia'], size=(width, 1),
                  enable_events=True, key='-CENTER_TYPE-')],
        [sg.Text('Tipus d\'estació')],
        [sg.Combo(['dinamitzacio', 'ciutadania'], size=(width, 1),
                  enable_events=True, key='-TYPE-')],
        [sg.Text('Nom de l\'estació', key='-HOSTNAME_LABEL-')],
        [sg.InputText(key='-HOSTNAME-', size=(width, 1), visible=False,
                      enable_events=True),
         sg.Spin(estacions, key='-CLIENTNAME-', size=(width, 1),
                 visible=False)],
        [sg.Text('Adreça de l\'equip servidor')],
        [sg.InputText(key='-SERVERADDRESS-', size=(width, 1), disabled=True,
                      enable_events=True)],
        [sg.Checkbox('Llegeix la configuració de l\'equip servidor',
                     key='-SHARED_CONFIG-', enable_events=True,
                     visible=allowSharedConfig, size=(width, 1))],
        [sg.Frame('Configuració Punt Òmnia', tab1_omnia, key='-OMNIA-',
                  visible=False)],
        [sg.Frame('Configuració PuntTIC', tab1_punttic, key='-PUNTTIC-',
                  visible=False)]
    ]

    # Network shares tab layout
    tab2_shares = [
        [sg.Checkbox('Carpeta Models', key='-SAMBA_SHARE_MODELS-',
                     size=(width, 1), default=True)],
        [sg.Checkbox('Carpeta Tallers', key='-SAMBA_SHARE_TALLERS-',
                     size=(width, 1), default=True)],
        [sg.Checkbox('CONFIG (aquest equip configura tot el PuntTIC)',
                     key='-SAMBA_SHARE_CONFIG-', size=(width, 1),
                     default=allowSharedConfig, disabled=not allowSharedConfig,
                     visible=allowSharedConfig)]
    ]

    tab2_layout = [
        [sg.Text('Servidor de fitxers')],
        [sg.Checkbox('Aquest equip actua com a servidor de fitxers',
                     key='-SAMBA_SERVER-', size=(width, 1),
                     enable_events=True)],
        [sg.Frame('Recursos compartits', tab2_shares, key='-SHARES-',
                  visible=False)]
    ]

    # Network configuration tab layout
    tab3_ip = [
        [sg.Text('Adreça IP')],
        [sg.InputText(key='-IP_ADDRESS-', size=(width, 1))],
        [sg.Text('Màscara de subxarxa')],
        [sg.InputText(key='-SUBNETMASK-', size=(width, 1))],
        [sg.Text('Adreça encaminador')],
        [sg.InputText(key='-ROUTER-', size=(width, 1))],
        [sg.Text('Servidors de noms (separats per ",")')],
        [sg.InputText(key='-DNS_SERVERS-', size=(width, 1))]
    ]

    tab3_client = [
        [sg.Text('Configuració de l\'adreça IP de les estacions d\'usuari')],
        [sg.Combo(['Automàtica', 'Manual'], size=(width, 1),
                  enable_events=True, key='-CLIENT_DHCP-',
                  default_value='Automàtica')],
        [sg.Text('Adreça per l\'"estacio01"')],
        [sg.InputText(key='-CLIENT_RANGE-', size=(width, 1),
                      enable_events=True)]
    ]

    tab3_proxy = [
        [sg.Text('Adreça del proxy')],
        [sg.InputText(key='-PROXY_ADDRESS-', size=(width, 1))],
        [sg.Text('Port del proxy')],
        [sg.InputText(key='-PROXY_PORT-', size=(width, 1))]
    ]

    tab3_layout = [
        [sg.Text('Configuració de l\'adreça IP')],
        [sg.Combo(['Automàtica', 'Manual'], size=(width, 1),
                  enable_events=True, key='-DHCP-',
                  default_value='Automàtica')],
        [sg.Frame('Configuració IP', tab3_ip, key='-IP_SETTINGS-',
                  visible=True)],
        [sg.Checkbox('Assigna les IP de les estacions client',
                     key='-SET_CLIENT_IPS-', enable_events=True)],
        [sg.Frame('Configuració IPs estacions client', tab3_client,
                  key='-CLIENT_IPS-', visible=False)],
        [sg.Checkbox('Fa servir un proxy', key='-PROXY-',
                     size=(width, 1), enable_events=True)],
        [sg.Frame('Configuració proxy', tab3_proxy, key='-PROXY_SETTINGS-',
                  visible=False)]
    ]

    # Session timeout configuration tab layout
    tab4_layout = [
        [sg.Checkbox('Finalització automàtica de sessió', key='-AUTOLOGOUT-',
                     size=(width, 1), enable_events=True)],
        [sg.Text('Temps màxim de sessió (en minuts)')],
        [sg.InputText(key='-AUTOLOGOUT_TIMEOUT-', size=(width, 1))],
        [sg.Text("Usuari amb finalització automàtica de sessió")],
        [sg.InputText(key='-AUTOLOGOUT_USERNAME-', size=(width, 1))],
    ]

    layout = [
        [sg.TabGroup([
                [sg.Tab('General', tab1_layout, key='-TAB1_GENERAL-')],
                [sg.Tab('Servidor de fitxers', tab2_layout, key='-TAB2_SAMBA-',
                        disabled=True)],
                [sg.Tab('Xarxa', tab3_layout, key='-TAB3_NETWORK-')],
                [sg.Tab('Sessions temporitzades', tab4_layout,
                        key='-TAB4_TIMEOUT-')]
            ])],
        [sg.Button('D\'acord', key='-OK-', disabled=True),
         sg.Button('Anul·la', key='-CANCEL-')]
    ]
    return layout

######################################################################
# Funcions de suport


def setHostname(hostname, window, values):
    if values['-HOSTNAME-'] == '':
        window['-HOSTNAME-'].update(hostname)


def readSystemParams(window):
    global endpoint
    for param in params:
        component = '-'+param+'-'
        if param in os.environ:
            value = os.environ[param]
            # Si es tracta d'un Checkbox, convertim el valor a bool
            if isinstance(window[component], sg.Checkbox):
                value = False if value == '0' else True
            window[component].update(value)
    if 'XARXAOMNIA_ENDPOINT' in os.environ:
        endpoint = os.environ['XARXAOMNIA_ENDPOINT']
    else:
        endpoint = False


def printClientParams(values):
    values['-SAMBA_SHARE_MODELS-'] = True
    values['-SAMBA_SHARE_TALLERS-'] = True
    values['-SAMBA_SHARE_CONFIG-'] = True

    for param in client_params:
        component = '-'+param+'-'
        value = values[component]
        if isinstance(value, bool):
            value = '1' if value else '0'
        elif not isinstance(value, str):
            value = str(value)
        print(param+'="'+value+'"; export '+param)


def printSystemParams(values):
    if values['-TYPE-'] == 'usuari' and values['-SHARED_CONFIG-']:
        printClientParams(values)
    else:
        for param in params:
            component = '-'+param+'-'
            value = values[component]
            if isinstance(value, bool):
                value = '1' if value else '0'
            elif not isinstance(value, str):
                value = str(value)
            print(param+'="'+value+'"; export '+param)


def enableIPSettings(window, enabled=True):
    for item in tab3_ip_items:
        window[item].update(disabled=not enabled)


def validIP(ip):
    counter = ip.count('.')
    if counter != 3:
        return False
    try:
        IP(ip)
        return True
    except ValueError:
        return False


def updateValue(window, values, element, newvalue):
    window[element].update(value=newvalue)
    values[element] = newvalue

############################################################################
# Configuració de Puppet als centres Òmnia


def getOmniaData():
    global omniaData
    if omniaData is False:
        return False
    if len(omniaData) > 0:
        return omniaData
    if endpoint:
        try:
            resp = requests.get(endpoint)
            if resp.status_code == 200:
                data = resp.json()
                omniaData = data["nodes"]
        except:
            omniaData = False
    else:
        omniaData = [
            {
                "node": {
                    "municipi": "Prova 0",
                    "punt": "prova òmnia 1",
                    "maxHost": 9, "codi":
                    "prova0-provaomnia1"
                }
            },
            {
                "node": {
                    "municipi": "Prova 0",
                    "punt": "prova òmnia 2",
                    "maxHost": 7, "codi": "prova0-provaomnia2"
                }
            },
            {
                "node": {
                    "municipi": "Prova 1",
                    "punt": "prova òmnia 3",
                    "maxHost": 5,
                    "codi": "prova1-provaomnia3"
                }
            }
        ]
    return omniaData


def getCitiesList():
    getOmniaData()
    if not omniaData:
        return False

    cities = []
    for n in omniaData:
        c = n["node"]
        if not c["municipi"] in cities:
            cities.append(c["municipi"])
    cities.sort()
    return cities


def getCenterList(city):
    getOmniaData()
    if not omniaData:
        return False

    centers = []
    for n in omniaData:
        c = n["node"]
        if c["municipi"] == city:
            centers.append(c["punt"])
    centers.sort()
    return centers


def getHostsList(city, center):
    getOmniaData()
    list = [
        'servidor', 'estacio01', 'estacio02', 'estacio03', 'estacio04',
        'estacio05', 'estacio06', 'estacio07', 'estacio08', 'estacio09'
    ]
    centre = False
    for n in omniaData:
        c = n["node"]
        if c["municipi"] == city and (c["punt"] == center):
            centre = c
            break

    if centre:
        hosts = centre["maxHost"]
        if not hosts:
            hosts = 9
        return list[:hosts]

    return list


def getHostCode(city, center, hostname):
    getOmniaData()
    if not omniaData:
        return False

    centre = False
    for n in omniaData:
        c = n["node"]
        if c["municipi"] == city and (c["punt"] == center):
            centre = c
            break
    if centre:
        return c["codi"] + "-" + hostname
    else:
        return False


def updateOmnia(window, values):
    # És un punt Òmnia. Anem a carregar els municipis, els centres
    # de cada municipi i el nombre d'estacions
    global citiesList
    global centersList
    global hostsList

    # Si no hem carregat la llista de municipis, ho fem ara
    if len(citiesList) == 0:
        list = getCitiesList()
        if not list:
            return False
        for c in list:
            citiesList.append(c)
        window['-CENTER_CITY-'].update(values=citiesList)

    # Si no està donat el nom de la ciutat, sortim de la funció
    if not values['-CENTER_CITY-']:
        updateValue(window, values, '-HOSTNAME-', "")
        updateValue(window, values, '-CENTER_HOST-', "")
        return True

    city = values['-CENTER_CITY-']
    # Recuperem el llistat de centres del municipi
    centersList = []
    list = getCenterList(city)
    if not list:
        return False
    for c in list:
        centersList.append(c)
    window['-CENTER_NAME-'].update(values=centersList)
    updateValue(window, values, '-HOST_CODE-', "")

    # Si el nom del centre no està definit, sortim de la funció
    if not values['-CENTER_NAME-']:
        updateValue(window, values, '-HOSTNAME-', "")
        updateValue(window, values, '-CENTER_HOST-', "")
        return True

    center = values['-CENTER_NAME-']
    # Si el nom del centre no correspon al municipi, l'esborrem i sortim
    if center not in list:
        updateValue(window, values, '-CENTER_NAME-', "")
        updateValue(window, values, '-HOSTNAME-', "")
        updateValue(window, values, '-CENTER_HOST-', "")
        return True

    # Si és la màquina de dinamització, directament li posem el nom
    if values['-TYPE-'] == 'dinamitzacio':
        hostsList = []
        hostsList.append('servidor')
        hostName = hostsList[0]

        window['-CENTER_HOST-'].update(values=hostsList, disabled=False)
        updateValue(window, values, '-CENTER_HOST-', hostName)
        updateValue(window, values, '-HOSTNAME-', hostName)

        hostcode = getHostCode(city, center, hostName)
        if not hostcode:
            print("No s'ha pogut recuperar el codi de l'estació")
            return False
        updateValue(window, values, '-HOST_CODE-', hostcode)
        return True

    # Altrament, recuperem la relació d'estacions
    hostsList = []

    list = getHostsList(values['-CENTER_CITY-'], values['-CENTER_NAME-'])
    for h in list:
        if h != 'servidor':
            hostsList.append(h)

    if values['-CENTER_HOST-']:
        hostName = values['-CENTER_HOST-']
    else:
        hostName = hostsList[0]
    if hostName not in hostsList:
        hostName = hostsList[0]

    window['-CENTER_HOST-'].update(values=hostsList, value=hostName,
                                   disabled=False)
    window['-CLIENTNAME-'].update(value=hostName)
    hostcode = getHostCode(city, center, hostName)
    updateValue(window, values, '-HOST_CODE-', hostcode)

    return True


def enableOmnia(window, enabled):
    elements = ['-CENTER_CITY-', '-CENTER_NAME-', '-CENTER_HOST-']
    for e in elements:
        window[e].update(disabled=not enabled)

######################################################################
# Lògica de la UI


def updateWindow(window, values):
    # Principals casos
    omnia = values['-CENTER_TYPE-'] == 'PuntÒmnia'
    punttic = values['-CENTER_TYPE-'] == 'PuntTIC'
    dinamitzacio = values['-TYPE-'] == 'dinamitzacio'
    usesSharedConfig = (values['-SHARED_CONFIG-'] and not dinamitzacio)

    if values['-SAMBA_SERVER-']:
        window['-DHCP-'].update('Manual', disabled=True)
        values['-DHCP-'] = 'Manual'
    else:
        window['-DHCP-'].update(disabled=False)

    # És un Punt Òmnia
    if omnia:
        window['-OMNIA-'].update(visible=True)
        if not updateOmnia(window, values):
            enableOmnia(window, False)
        else:
            enableOmnia(window, True)
    else:
        # No és un punt Òmnia. Amaguem-ho
        window['-OMNIA-'].update(visible=False)

    # És un PuntTIC
    if punttic:
        window['-PUNTTIC-'].update(visible=True)
        if values['-PUNTTIC_NAME-'] != '':
            punttic_name = unidecode.unidecode(values['-PUNTTIC_NAME-'])
            hostcode = 'punttic-' + punttic_name.replace(" ", "").lower()
            hostcode = hostcode.replace("'", "")
            if (values['-TYPE-'] == 'dinamitzacio'
               and values['-HOSTNAME-'] != ''):
                hostcode = hostcode + '-' + values['-HOSTNAME-']
                updateValue(window, values, '-HOST_CODE-', hostcode)

            if (values['-TYPE-'] != 'dinamitzacio'
               and values['-CLIENTNAME-'] != ''):
                hostcode = hostcode + '-' + values['-CLIENTNAME-']
                updateValue(window, values, '-HOST_CODE-', hostcode)
    else:
        window['-PUNTTIC-'].update(visible=False)

    if values['-SHARED_CONFIG-'] and not validIP(values['-SERVERADDRESS-']):
        updateValue(window, values, '-SHARED_CONFIG-', False)

    window['-TAB2_SAMBA-'].update(disabled=usesSharedConfig)
    window['-TAB3_NETWORK-'].update(disabled=usesSharedConfig)
    window['-TAB4_TIMEOUT-'].update(disabled=usesSharedConfig)
    enableIPSettings(window, enabled=(values['-DHCP-'] == 'Manual'))
    window['-PROXY_SETTINGS-'].update(visible=values['-PROXY-'])
    window['-SHARES-'].update(visible=values['-SAMBA_SERVER-'])
    window['-HOSTNAME_LABEL-'].update(visible=not omnia)
    window['-HOSTNAME-'].update(visible=dinamitzacio and not omnia,
                                disabled=True)
    window['-CLIENTNAME-'].update(visible=not dinamitzacio and not omnia)
    window['-CLIENT_IPS-'].update(visible=values['-SET_CLIENT_IPS-'])
    window['-SHARED_CONFIG-'].update(
        disabled=dinamitzacio or not validIP(values['-SERVERADDRESS-']))

    disableOK = ((values['-CENTER_TYPE-'] != ''
                 and values['-HOST_CODE-'] == '')
                 or (values['-CENTER_TYPE-'] == '')
                 or (values['-TYPE-'] == ''))

    # És l'estació de dinamització
    if dinamitzacio:
        window['-TAB2_SAMBA-'].update(disabled=False)
        window['-SERVERADDRESS-'].update(disabled=True)
        window['-SET_CLIENT_IPS-'].update(visible=True)
        window['-CLIENT_IPS-'].update(visible=values['-SET_CLIENT_IPS-'])
        window['-CLIENT_RANGE-'].update(
            visible=(values['-CLIENT_DHCP-'] == 'Manual'))
        window['-CENTER_HOST-'].update(disabled=True)
        updateValue(window, values, '-HOSTNAME-', 'servidor')

        window['-OK-'].update(
            disabled=(
                disableOK
                or values['-HOSTNAME-'] == ''
                or (values['-CLIENT_DHCP-'] == 'Manual'
                    and not validIP(values['-CLIENT_RANGE-']))
            )
        )
    else:
        window['-TAB2_SAMBA-'].update(disabled=True)
        window['-SERVERADDRESS-'].update(disabled=False)
        window['-DHCP-'].update(disabled=False)
        window['-SET_CLIENT_IPS-'].update(visible=False)
        window['-CLIENT_IPS-'].update(visible=False)
        updateValue(window, values, '-SAMBA_SERVER-', False)
        window['-OK-'].update(
            disabled=(
                disableOK
                or (values['-SERVERADDRESS-'] != ''
                    and not validIP(values['-SERVERADDRESS-']))
            )
        )

    window['-CLIENT_RANGE-'].update(disabled=values['-CLIENT_DHCP-'])

    window['-SET_CLIENT_IPS-'].update(
        disabled=not values['-SAMBA_SHARE_CONFIG-']
    )


def main(args):
    layout = initLayout()
    window = sg.Window('Configuració del PuntTIC', layout, finalize=True)
    readSystemParams(window)
    event, values = window.read(timeout=0, timeout_key='-TIMEOUT-')
    updateWindow(window, values)

    # Bucle principal per processar els esdeveniments de la finestra
    while True:
        event, values = window.read()
        if __DEBUG__:
            print(event, values)

        # Tanca la finestra sense validar els continguts (cancel·la)
        if event == sg.WIN_CLOSED or event == '-CANCEL-':
            exit_value = 1
            break

        # Tanca la finestra validant els continguts (accepta)
        if event == '-OK-':
            if values['-SHARED_CONFIG-']:
                printClientParams(values)
            else:
                printSystemParams(values)
            exit_value = 0
            break

        updateWindow(window, values)

    window.close()
    return exit_value


exit(main([]))
