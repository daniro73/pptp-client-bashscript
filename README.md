# pptp-client-bashscript
PPTP client: CRUD PPTP connection using CLI in ubuntu
feature:
  - easy to use
  - auto check requirements
  - auto install requirements when run this command : sudo ./pptpCli.sh -y
  - Create | Read | Update | Delete pptp connection
  - print stauts when connection established or username/password is wrong

# let's start
1- download it
2- run this command ( where file downloaded ) as sudo to able excute script
  $ sudo chmod +x ./pptpCli.sh
  
3- create VPN connection
  $ sudo ./pptpCli.sh create -v VPN_NAME VPN_SERVER_DOMAIN_NAME_OR_IP -u VPN_ACCOUNT_USERNAME VPN_ACCOUNT_PASSWORD
  OR
  $ sudo ./pptpCli.sh -c -v CONNECTION_NAME VPN_SERVER_DOMAIN_NAME_OR_IP -u VPN_ACCOUNT_USERNAME VPN_ACCOUNT_PASSWORD
  
4- easy use (on/off) it:
  #turn on vpn by connection name
  $ ./pptpCli.sh start CONNECTION_NAME
  OR
  $ ./pptpCli.sh -st CONNECTION_NAME
  
  #turn on vpn by connection name
  $ ./pptpCli.sh stop CONNECTION_NAME
  OR
  $ ./pptpCli.sh -sp CONNECTION_NAME
  
- for using other command:
  $ ./pptpCli.sh
