#!/bin/bash

pppDefineServerPath="/etc/ppp/peers"
pppOptionPath="/etc/ppp/"

pppOptionFile="
###############################################################################\n
# \$Id: options.pptp,v 1.4 2012/08/30 21:34:13 quozl Exp $\n
#\n
# Sample PPTP PPP options file /etc/ppp/options.pptp\n
# Options used by PPP when a connection is made by a PPTP client.\n
# This file can be referred to by an /etc/ppp/peers file for the tunnel.\n
# Changes are effective on the next connection.  See \"man pppd\".\n
#
# You are expected to change this file to suit your system.  As\n
# packaged, it requires PPP 2.4.2 or later from http://ppp.samba.org/\n
# and the kernel MPPE module available from the CVS repository also on\n
# http://ppp.samba.org/, which is packaged for DKMS as kernel_ppp_mppe.\n
###############################################################################\n
\n
# Lock the port\n
lock\n
\n
# Authentication\n
# We don't need the tunnel server to authenticate itself\n
noauth\n

# We won't do PAP, EAP, CHAP, or MSCHAP, but we will accept MSCHAP-V2\n
# (you may need to remove these refusals if the server is not using MPPE)\n
refuse-pap\n
refuse-eap\n
refuse-chap\n
refuse-mschap\n
\n
# Compression\n
# Turn off compression protocols we know won't be used\n
nobsdcomp\n
nodeflate\n
"

main () {
    checkPackage pptp-linux no 
    [[ $? != 0 && $1 != -y* ]] && { echo -e "\npptp-linux pkg dosn't exist, install it with ${0#.\/} -y\n"; exit 5; }
    checkPackage network-manager-pptp no
    [[ $? != 0 && $1 != -y* ]] && { echo -e "\nnetwork-manager-pptp pkg dosn't exist, install it with ${0#.\/} -y\n"; exit 5; }
    
    case $1 in
        create | -c*)
            if [[ $2 == -v* ]]
            then    
                [[ -z "$3" ]] && { echo "input connection name"; exit 4; }
                [[ -z "$4" ]] && { echo "input server address"; exit 4; }
                [[ -z "$5" && $5==-u* ]] && { echo "add -u define user"; exit 4; }
                [[ -z "$6" ]] && { echo "input user name"; exit 4; }
                local vpnName=$3
                local server=$4
                local userName=$6
                local password=${7:- $(tr -dc A-Za-z0-9 </dev/urandom | head -c 8)} 
                local vpnConfigPath="${pppDefineServerPath}/${vpnName}"

                if [[ $? == 0 ]];
                then   
                    sudo echo -e $pppOptionFile > "${pppOptionPath}opt-${vpnName}"
                    sudo echo -e "pty \"pptp ${server} --nolaunchpppd\"" > $vpnConfigPath
                    sudo echo "name ${userName}" >> $vpnConfigPath
                    sudo echo "password ${password}" >> $vpnConfigPath
                    sudo echo "remotename PPTP" >> $vpnConfigPath
                    sudo echo "require-mppe-128" >> $vpnConfigPath
                    sudo echo "file ${pppOptionPath}opt-${vpnName}" >> $vpnConfigPath
                    [[ $? == 0 ]]  && { echo -e "\nadd > user {name: $userName, password: $password}\nadd > vpn {name: $vpnName, server: $server}\n"; exit 0; }
                fi
                echo -e "\nsomthing was wrong!\ncan't to add ${vpnName}\n"
                exit 5
            else
                $(echo "${PWD}${0#.} help")
                exit 4
            fi
        ;;
        delete | -d*)   
            if [[ $2 == -v* ]]
            then
                [[ -z "$3" ]] && { echo "input connection name"; exit 4; }

                local vpnName=$3
                local vpnConfigPath="${pppDefineServerPath}/${vpnName}"
                
                
                sudo rm -f $vpnConfigPath
                [[ $? != 0 ]]  && { echo -e "\nsomthing was wrong!\ncan't to delete ${vpnConfigPath}\n"; exit 5; }
                sudo rm -f "${pppOptionPath}opt-${vpnName}"
                [[ $? != 0 ]]  && { echo -e "\nsomthing was wrong!\ncan't to delete ${pppOptionPath}opt-${vpnName}\n"; exit 5; }
                echo -e "\ndel > vpn {name: ${vpnName}}\n"
                exit 0
            else
                $(echo "${PWD}${0#.} help")
                exit 4
            fi
        ;;
        start | -st*)   
                [[ -z "$2" ]] && { echo "input connection name"; exit 4; }

                local vpnName=$2
                local vpnConfigPath="${pppDefineServerPath}/${vpnName}"

                sudo test -f $vpnConfigPath 
                
                if [[ $? == 0 ]];
                then
                    sudo pon $vpnName   
                    checkConnection $vpnName 5 
                    [[ $? == 0 ]] && { 
                    sudo ip route add 0.0.0.0/0 dev ppp0;   
                    echo -e "run > vpn {name: ${vpnName}}\n";
                    sudo truncate -s 0 /var/log/syslog; exit 0; 
                    }
                    echo -e "connection failed\n"
                    exit 1;
                fi
                echo -e "\n${vpnName}'s config file does not exist\n"
                exit 3
        ;;
        stop | -sp*)
                [[ -z "$2" ]] && { echo "input connection name"; exit 4; }

                local vpnName=$2
                local vpnConfigPath="${pppDefineServerPath}/${vpnName}"

                ip a | grep "ppp0" >> /dev/null
                [[ $? != 0 ]] && { sudo ip route del 0.0.0.0/0 dev ppp0; echo -e "all vpns are down\n"; exit 0; }

                [[ $vpnName == -a ]] && {
                    sudo ip route del 0.0.0.0/0 dev ppp0;
                    sudo poff $vpnName >> /dev/null;
                    checkConnection $vpnName 5 >> /dev/null;
                    [[ $? == 1 ]] && { echo -e "all vpns are down\n"; } ;
                    sudo truncate -s 0 /var/log/syslog;
                    exit 0; }

                sudo test -f $vpnConfigPath;
                if [[ $? == 0 ]];
                then
                    sudo ip route del 0.0.0.0/0 dev ppp0;  
                    sudo poff $vpnName >> /dev/null
                    checkConnection $vpnName 5  
                    [[ $? == 1 ]] && { 
                    echo -e "down > vpn {name: ${vpnName}}\n";
                    sudo truncate -s 0 /var/log/syslog;
                    exit 0; }
                    echo -e "action failed\n"
                    exit 1;
                fi
                echo -e "\n${vpnName}'s config file does not exist\n"
                exit 3
        ;;
        -y*)
            checkPackage pptp-linux yes
            [[ $? != 0 ]] && { echo -e "\ncann't install pptp-linux pkg, please install it\n"; exit 1; }
            checkPackage network-manager-pptp yes
            [[ $? != 0 ]] && { echo -e "\nann't install network-manager-pptp pkg,please install it\n"; exit 1; }
            exit 0
        ;;
        *)
            help ${0#.\/}
            exit 0
        ;;
    esac
}



help () {
    introduction="\n *********\n
                maintenance by: daniro\n
                email: mrshstu@gmail.com\n
                *********\n
                > ${1}\t<action>\n\t\t
                help\n\t\t
                init\n\t\t
                stop <vpn connection name | -a>\n\t\t
                start <vpn connection name>\n\t\t
                delete -vpn <vpn connection name>\n\t\t
                create -vpn <vpn connection name> <vpn server address> -user <username> <password>\n\t\t
                    
    "
    echo -e $introduction | less
    exit 0;
}


function checkPackage {
    local REQUIRED_PKG=$1;
    local PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG | grep "install ok installed" );
    if [[ $PKG_OK == '' ]]; then
        [[ $2 == y* ]] && {
            echo -e "\nwaiting to install $REQUIRED_PKG\n";
            sudo apt-get --yes install $REQUIRED_PKG;
            return $?;
        }
        return 1;
    fi
    return 0;
}


checkConnection () {
local x=0
while [[ x -lt $2 ]]
do
  log=$(plog)
  sleep 3s
  { echo $log | grep "local" >> /dev/null ; } &&
  { echo -e "\n${1} connected"; return 0; }
    
  { echo $log | grep "Modem hangup" >> /dev/null ; } &&
  { echo $log | grep "Connection terminated" >> /dev/null ; } &&
  { echo -e "\ncann't to connect to ${1} server"; return 1; }
  
  { echo $log | grep "Access denied" >> /dev/null ; } &&
  { echo $log | grep "authentication failed" >> /dev/null ; } &&
  { echo $log | grep "Connection terminated" >> /dev/null ; } &&
  { echo -e "\n${1}'s password is wrong"; return 1; }
  
  { echo $log | grep "authentication failed" >> /dev/null ; } &&
  { echo $log | grep "Connection terminated" >> /dev/null ; } &&
  { echo -e "\n${1}'s username is wrong"; return 1; }
  x=$((x+1))
done
echo -e "\nsomthing was wrong"
return 5
}

main $@

