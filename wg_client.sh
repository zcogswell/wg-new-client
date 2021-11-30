#!/usr/bin/env bash

usage() { echo "Usage: $(basename $0) [-n NAME] -e ENDPOINT"; exit; }
while getopts :n:e: opt; do
        case ${opt} in
                n )
                        name=$OPTARG
                        ;;
                e )
                        endpoint=$OPTARG
                        ;;
                /? )
                        usage
                        ;;
        esac
done

num_file="${HOME}/wireguard/num_clients.txt"
if test -f "$num_file"; then
        ip_num=$((`cat $num_file` + 1))
        echo "Client #$ip_num"
else
        echo "Making new num_clients.txt."
        ip_num=2
fi

if [ -z ${name+x} ]; then
        name="peer$ip_num"
fi
echo "Username $name"

if [ -z ${endpoint+x} ]; then
        echo 'No endpoint specified.' 1>&2
        exit 1
fi

name_dir="${HOME}/wireguard/$name"
mkdir $name_dir
cd $name_dir
umask 077
wg genkey > "${name}.key"
wg pubkey < "${name}.key" > "${name}.pub"
wg genpsk > "${name}.psk"

echo -e "[Interface]
Address = 192.168.254.${ip_num}/32
PrivateKey = $(cat ${name}.key)
DNS = 192.168.0.1\n
[Peer]
Endpoint = $endpoint
AllowedIPs = 0.0.0.0/0
PublicKey = $(cat /etc/wireguard/server.pub)
PresharedKey = $(cat ${name}.psk)" > "${name}.conf"

echo -e "\n[Peer]
AllowedIPs = 192.168.254.${ip_num}/32
PublicKey = $(cat ${name_dir}/${name}.pub)
PresharedKey = $(cat ${name_dir}/${name}.psk)" >> /etc/wireguard/wg0.conf

echo $ip_num > "${HOME}/wireguard/num_clients.txt"
