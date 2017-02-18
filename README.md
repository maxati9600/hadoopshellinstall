#Environment
This is a hadoop install script for hadoop-2.7.2.<br>
os 	: ubuntu 16.04<br>
openjdk	: 1.8.0<br>

#First step

1.setup ssh key login for master(kdc server) to slave<br>
2.copy key to slave


#Install
##Install hadoop script

``sudo ./hd_install.sh``

##Install hadoop with secure mode (kerberos)

``
sudo ./krb5.sh<br>
sudo ./hd_kerberos_install.sh``
