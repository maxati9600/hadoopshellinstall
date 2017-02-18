#/bin/bash
# install krb5 first 
#	sudo su
#	sudo apt-get install krb5-kdc krb5-admin-server haveged -y

passwd="q123456"      #passwd for krb5 admin 
username=`users`      #linux user for setting 
master_uname="master" #Host name for Krb5-kdc
krb_realm="MIN.LOCAL" #realm(group) for configure krb5.conf
slave_uname="slave"   #automatic produce client host name prefix  
slave_num=2           #number of client(slave1 slave2 ...)
dir="/opt/key"        #kdc key storge path

if [ $EUID -ne 0 ];then
	echo "This script must be run as root."
	echo "Run 'sudo su' and run this script again."
	exit 1
fi

#gen host name set #########
for sslave in `seq 1 1 ${slave_num}`;
do
	slave=${slave}" "${slave_uname}${sslave}
done
all=${master_uname}" "${slave}
############################

#Check require package ############
KDC_req_package="krb5-kdc krb5-admin-server haveged vim"
for rp in ${KDC_req_package} ; do
	tmp=""
	tmp=`dpkg-query -l |awk '{print $2}'|grep ${rp}`
	if [ -z "${tmp}" ];
	then
		rpackage=${rpackage}" "${rp}
	fi		
done
###################################

#install for missing package for KDC ######
if [ -n "${rpackage}" ]; then
	clear
	echo "================================================"
	echo "Something missing...automatic install it"
	echo "================================================"
	sleep 2
	apt-get install ${rpackage} -y
fi

###########################################

#check config
echo "================================================"
echo "Check krb5 require file. and copy in config dir!"
echo "================================================"

if [ -f "./krb5.conf" ];
then
	/bin/cp ./krb5.conf /etc/krb5.conf
else
	echo "./krb5.conf not exist please clone it from github!"
	exit
fi
if [ -f "./kdc.conf" ];
then
	/bin/cp ./kdc.conf /etc/krb5kdc/kdc.conf
else
	echo "./kdc.conf not exist please clone it from github!"
        exit
fi
for host in ${all}; do
	echo "*/${host}@${krb_realm} *" >>/etc/krb5kdc/kadm5.acl
done

service krb5-admin-server restart
echo -e "${passwd}\n${passwd}\n" |krb5_newrealm
echo -e "${passwd}\n${passwd}" |kadmin.local -q "addprinc admin/master"
echo -e "${passwd}" |kinit admin/master
klist
#create all key for all host
echo "======================================================================="
echo "generate key for all machine"
echo "======================================================================="
for host in $all ;do
	mkdir -p ${dir}"/"${host}
	kadmin.local -q "addprinc -randkey nn/${host}"
        kadmin.local -q "addprinc -randkey HTTP/${host}"
	kadmin.local -q "ktadd -norandkey -k ${dir}/${host}/nn.service.keytab nn/${host}"
	kadmin.local -q "addprinc -randkey snn/${host}"
        kadmin.local -q "ktadd -norandkey -k ${dir}/${host}/snn.service.keytab snn/${host}"
        kadmin.local -q "addprinc -randkey dn/${host}"
	kadmin.local -q "ktadd -norandkey -k ${dir}/${host}/dn.service.keytab dn/${host}"
        kadmin.local -q "addprinc -randkey HTTP/${host}"
	kadmin.local -q "ktadd -norandkey -k ${dir}/${host}/spnego.service.keytab HTTP/${host}"
        kadmin.local -q "addprinc -randkey yarn/${host}"
	kadmin.local -q "ktadd -norandkey -k ${dir}/${host}/yarn.keytab yarn/${host}"
done
#########
#move key in /opt/key and chang owner
########
echo "======================================================================="
echo "change key owner /opt/key"
echo "======================================================================="
chown -R `users|awk {'print $1'}`.`users|awk {'print $1'}` ${dir}

#copy key to slave 
sleep 5
clear
echo "======================================================================="
echo "start to copy key to slave"
echo "======================================================================="
for sHost in ${slave} ; do
	echo "Start copy to "${sHost}
	echo "mkdir for hadoop "${sHost}":"${dir}" owner:"${username}
	echo "You might need to enter ${sHost}'s root password "
	ssh -t ${username}@${sHost} "sudo mkdir -p ${dir}/ca && sudo chown ${username}.${username} ${dir} && sudo apt-get install krb5-user krb5-config -y "
	echo "file copy"
	scp ${dir}/${sHost}/* ${username}@${sHost}:${dir}/ 
done
mv /opt/key/${master_uname}/* /opt/key/
