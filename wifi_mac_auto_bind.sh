#!/bin/ash

#
# usage: "/root/wifi_mac_auto_bind.sh phy0-ap1 start" and
#        replace phy0-ap1 with your hostapd wifi interface
#

pw_flash=/root/wifi_pw.psk
pw_ramfs=/tmp/wifi_pw.psk


wrr="wifi reload radio${1:3:1}" # ubus call hostapd.$1 reload # restarting only phyX-apY may vanish radioX

if ! [ -s $pw_flash ]; then
	
	count=$( cat $pw_ramfs | wc -l )
	total=$(( $count + 420 )) # 0.3 margins, 8 col 0.1 margim, lucida console size 6
	while [ $count -lt $total ]; do
		count=$(( $count + 1 ))
		token=$(</dev/urandom tr -dc a-z0-9+@% | head -c 16)
		echo keyid=$count 00:00:00:00:00:00 ${token:0:4}.${token:4:4}.${token:8:4}.${token:12:4}  >> $pw_ramfs
	done

	cmd="        option wpa_psk_file '$pw_ramfs'" 
	grep -q "$cmd" /etc/config/wireless || echo "$cmd" >> /etc/config/wireless
	echo " ....... You should check if '$cmd' is in the correct interface inside '/etc/config/wireless'"

	grep -q "$wrr" /etc/crontabs/root || echo "59 4 * * * $wrr" >> /etc/crontabs/root
	$wrr
fi

[ -s $pw_ramfs ] || ( cp $pw_flash $pw_ramfs && $wrr )  # use "wpa_passphrase ssid psk" from wpa_supplicant to convert into 64 hex char ?


# phy1-ap1 AP-STA-CONNECTED 88:46:04:64:09:09 keyid=97 auth_alg=open
[[ "${4:0:5}" == "keyid" ]] && sed -i s/$4\ 00:00:00:00:00:00/$3/ $pw_ramfs


# if flash too old, backup from ramfs
[ $(( $(date -r $pw_ramfs "+%s") - $(date -r $pw_flash "+%s") )) -gt 900900 ] && cp $pw_ramfs $pw_flash



if [[ "$2" == "start" ]]; then
	hostapd_cli -i $1 -Bra "$0"  #'/root/wifi_mac_auto_bind.sh'
fi

