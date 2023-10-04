# Instal·lació i configuració de la maqueta de PuntTIC

Aquest projecte inclou els scripts que s'utilitzen per configurar una instal·lació base d'Ubuntu 20.04 i adaptar-la a les necessitats de la Xarxa PuntTIC i Òmnia.

## Relació d'scripts

* `punttic-install.sh`: s'utilitza per instal·lar i configurar una instal·lació base d'Ubuntu 20.04 i adadaptar-la a les necessitats de la Xarxa PuntTIC i Òmnia. Llegeix la configuració dels fitxers punttic.cfg (inclòs al repositori) i .env (amb els paràmetres específics o secrets de cada configuració)
* `punttic.cfg`: inclou la configuració de la instal·lació específica de la maqueta de 2020
* `punttic-config.sh`: és el programa de configuració del PuntTIC. Si es crida sense cap paràmetre, obre el quadre de diàleg de configuració. L'opció "--apply" fa que s'apliqui la configuració actual i l'opció "--update" simplement actualitza la configuració de xarxa.
* `punttic-ctemps.sh`: s'utilitza per controlar la durada màxima de la sessió de l'usuari indicat a la configuració (passada la durada màxima, la sessió es tanca i tot el seu contingut s'esborra).
