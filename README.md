# Technicolor_TG789
Cambio Firmware TIM Technicolor TG789vac v2 (VANT-6)


Sintesi della guida presente qui: https://www.ilpuntotecnico.com/forum/index.php/topic,77981.0.html

 ## 1. Sbloccare il modem
Versione Firmware AGTOT < 2.0

 - CONSIGLIATO: aggiornamento fw da linea TIM e poi segui le istruzioni per AGTOT >= 2.0.0.
   1. Collegare il gateway ad una linea TIM attiva. Questo può essere fatto sia utilizzando il Gateway come modem, oppure collegarlo attraverso un'altro modem. Per fare questo collegare il Gateway utilizzando una delle porte LAN (quelle gialle)
   2. Staccare il cavo DSL (se utilizzato come modem)
   3. Effettuare un reset-to-factory-default dalla GUI o tramite pin button
   4. attendere che il modem si riaccenda
   5. Accedere alla GUI con le credenziali admin/admin
   6. Sulla homepage della GUI cliccare sulla sezione “sblocco modem”
     
 - sblocco seguendo la guida https://www.ilpuntotecnico.com/forum/index.php/topic,77981.msg261767.html#msg261767

Versione Firmware AGTOT >= 2.0

 1.  individuate e appuntatevi l'ACCESS_KEY di 8 caratteri maiuscoli del vostro gateway stampata sull'etichetta applicata sotto dispositivo  
 2. Scollegate il modem da internet
 3. Effettuare un reset alle impostazioni di fabbrica (ed attendete che il gateway si riavvii completamente
 4. entrate di nuovo nella sua pagina web di configurazione  all'indirizzo  [http://192.168.1.1](http://192.0.0.168/) e accessibile con nome utente `administrator` password  `admin`
 5.  Andre in  **Configurazione** -> **Configurazione Avanzata** -> **Sblocca Modem**
 6. Atendere il riavvio del modem
 
  ## 2 Nuovo Firmware
 1. Rientrate nella webui del gateway, sempre su [http://192.168.1.1](http://192.0.0.168.1.1/), nome utente     `administrator` password `ACCESS_KEY` 
 2. Caricate uno dei due firmware (consigliato MST/UNO)  avviate l'aggiornamento al nuovo firmware ed     attendete che il gateway si riavvii
 3. Reset del modem
 4. Accedere al modem tramite *ssh* con utente: **engineer** e password: **ACCESS KEY**  
 5. Eseguire il comando 
   ```sh
set uci.button.button.@wps.handler "sed -i 's#/root:.*$#/root:/bin/ash#' /etc/passwd && echo root:root | chpasswd && sed -i -e 's/#//' -e 's#askconsole:.*\$#askconsole:/bin/ash#' /etc/inittab && (uci -q delete dropbear.afg || true) && uci add dropbear dropbear && uci rename dropbear.@dropbear[-1]=afg && uci set dropbear.afg.enable='1' && uci set dropbear.afg.Interface='lan' && uci set dropbear.afg.Port='22' && uci set dropbear.afg.IdleTimeout='600' && uci set dropbear.afg.PasswordAuth='on' && uci set dropbear.afg.RootPasswordAuth='on' && uci set dropbear.afg.RootLogin='1' && (uci set dropbear.lan.enable='0' || true) && uci commit dropbear && /etc/init.d/dropbear enable && /etc/init.d/dropbear restart && (uci -q set $(uci show firewall | grep -m 1 $(fw3 -q print | egrep 'iptables -t filter -A zone_lan_input -p tcp -m tcp --dport 22 -m comment --comment \"!fw3: .+\" -j DROP' | sed -n -e 's/^iptables.\+fw3: \(.\+\)\".\+/\1/p') | sed -n -e \"s/\(.\+\).name='.\+'$/\1/p\").target='ACCEPT' || true) && uci commit firewall && /etc/init.d/firewall reload && uci set button.wps.handler='wps_button_pressed.sh' && uci commit"
```
 7.  Premere il bottone WPS sul gateway per un secondo, rilasciarlo, ed attendere qualche istante che l'accesso root venga abilitato.   
 8. Premere di nuovo WPS per controllare che si accendano i led WPS
 9. Login alla shell via SSH all'IP del gateway con utente: root  password: root
 10. Esegui: `sed -i -e 's/#//' -e 's#askconsole:.*$#askconsole:/bin/ash#' /etc/inittab`
 11. Esegui `find /proc/banktable -type f -print -exec cat {} ';' -exec echo ';'''
 12. Se vedi qualcosa tipo

    ...
    /proc/banktable/booted
    <take note of this>
    /proc/banktable/active
    <take note of this>
    ...
Proseguire al punto 12, altrimenti il modem non supporta il dual bank

 12. Dovresti ottenere qualcosa tipo: 

```sh
    /proc/banktable/active         bank_1
    /proc/banktable/activeversion  Unknown
    /proc/banktable/booted         bank_2
    /proc/banktable/bootedversion  xx.x.xxxx-...
```

 13. Esegui: 
```sh
    # Ensure two banks match in sizes
    [ $(grep -c bank_ /proc/mtd) = 2 ] && \
    [ "$(grep bank_1 /proc/mtd | cut -d' ' -f2)" = \
    "$(grep bank_2 /proc/mtd | cut -d' ' -f2)" ] && {

    # Clone and verify firmware into bank_2 if applicable
    [ "$(cat /proc/banktable/booted)" = "bank_1" ] && {
    mtd -e bank_2 write /dev/$(grep bank_1 /proc/mtd | cut -d: -f1) bank_2 && \
    echo Verifying ... && \
    [ $(sha256sum /dev/$(grep bank_1 /proc/mtd | cut -d: -f1) /dev/$(grep bank_2 /proc/mtd | cut -d: -f1) | cut -d' ' -f1 | sort -u | wc -l ) -eq 1 ] || \
    { echo Clone verification failed, retry; exit; } }
    # Make a temp copy of overlay for booted firmware
    cp -rf /overlay/$(cat /proc/banktable/booted) /tmp/bank_overlay_backup
    # Clean up jffs2 space by removing existing old overlays
    rm -rf /overlay/*
    # Use the previously made temp copy as overlay for bank_2
    cp -rf /tmp/bank_overlay_backup /overlay/bank_2
    # Activate bank_1
    echo bank_1 > /proc/banktable/active
    # Make sure above changes get written to flash
    sync
    # Erase firmware in bank_1
    mtd erase bank_1;
    # Emulate system crash to hard reboot
    echo c > /proc/sysrq-trigger; }
    # end
```

Se tutto è andato bene, il modem si arresterà intenzionalmente in modo anomalo. Attendi il riavvio completo.
Ora dovresti essere nel bank ottimale menzionato in precedenza. A ogni riavvio, il dispositivo tenterà di avviare prima il banco attivo. Poiché abbiamo impostato il banco 1 come attivo e abbiamo anche cancellato il firmware del banco 1, si avvierà dal banco 2.


## 3 .Verifiche

 1.  accedere in SSH con credenziali quelle di default dopo il root, ovvero nome utente: root e password: root
 2. se il comando `cat /proc/banktable/booted` restituisce **bank_1** eseguire il comando `[ "$(cat /proc/banktable/booted)" = "bank_1" ] && mtd write /dev/mtd3 bank_2`
 3. eseguire:
    ```sh
    cp -a /overlay/$(cat /proc/banktable/booted) /tmp/bank_overlay_backup
    rm -rf /overlay/*
    cp -a /tmp/bank_overlay_backup /overlay/bank_2
    echo bank_1 > /proc/banktable/active  
    sync  
    mtd erase bank_1
    ```
 4. spegnere e riaccendere manualmente il gateway tramite interruttore
 5. controllare che `cat /proc/banktable/booted` restituisca **bank_2**


## 4. Aggiungi rete guest + correzione bug + lingua italiano (vedi https://www.ilpuntotecnico.com/forum/index.php/topic,77981.msg238343.html#msg238343 )

Possibili opzioni facoltative:
- Aggiunge la lingua italiana alla GUI (i files della traduzione sono presi in prestito dalla GUI del “buon” e spero sempre eterno Ansuel).
- Installa SFTP SERVER per l’uso di programmi tipo Filezilla o il File Manager del Desktop di Linux per navigare tra i files e cartelle del router.
- Installa Nano come editor.
- Configurazione del Wifi che risolve il problema della rete Guest.
- Risolve lo stato della visualizzazione della rete Guest nella GUI.
- Risolve i bugs del Voip  Tim e Tiscali (grazie a @cubamito).
 
Procedura 
1. Scaricare lo zip BugFixes.zip
2. Estrarre la cartella "setup" e copiarla su suppport USB
3. Editate i file come indicato nel  Readme allegato. 
4. Inserite il supporto usb nel router. 
5. Entrate con SSH come root e date questo comando: `sh /tmp/run/mountd/sda1/setup/setup.sh`


Con la pennina  usb inserita (NB copiare la cartella setup nella root)

### Modalità Router
#### ABILITA GUEST WIFI

`cp /etc/config/wireless /etc/config/wireless.save & cp /tmp/run/mountd/sda1/setup/wifi/wireless /etc/config/wireless`

#### PERMETTE LA VISUALIZZAZIONE DELLO STATO DEL WIFI GUEST NELLA GUI - FACOTATIVO

```sh 
cp /www/cards/004_wireless.lp /www/cards/004_wireless.lp.save & cp /tmp/run/mountd/sda1/setup/wifi/004_wireless.lp /www/cards/ & /etc/init.d/nginx restart
```

### Modalità AP

#### Abilita Guest Wifi
- Utilizzare il file  "AccessPoint_modality/wireless"

#### Visualizzazione delle rete Guest nel pannello
- ToDo. Attulamente non funziona


## 5. Consigli
- installare il supporto per sftp server: `opkg install /tmp/run/mountd/sda1/setup/sftp/openssh-sftp-server_7.1p2-1_brcm63xx-tch.ipk `
- Utilizzare FileZilla per spostare e rinominare i file

