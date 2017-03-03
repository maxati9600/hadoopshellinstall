#/bin/bash
# install krb5 first 
#	sudo su
#	sudo apt-get install krb5-kdc krb5-admin-server haveged -y

passwd="aaaaaaaa@UCCU"            #passwd for krb5 admin 
username="hduser"           #linux file owner for setting 
user_root="hadoop"	    #slave linux account with root privge for install packet
groupid="hadoop"	    #user group for setting
master_host_name="master"   #Host name for Krb5-kdc
krb_realm="CCU.LOCAL"       #realm(group) for configure krb5.conf
slave_uname="slave0"         #automatic produce client host name prefix  
slave_num=7                 #number of client(slave1 slave2 ...)
dir="/opt/key"              #kdc key storge path
krb5_conf_file="conf/krb5.conf conf/kdc.conf" #krb5 configure file list
krb5_conf_file_path[0]="/etc/krb5.conf"
krb5_conf_file_path[1]="/etc/krb5kdc/kdc.conf"
var_list="username passwd user_root groupid master_host_name krb_realm slave_uname slave_num dir "

#set variable manually ##################
echo "[*]Start Program..."
echo "[*]Configure varable..."
echo -e "\n"`date` >>./install.log
for var in ${var_list};
do
    eval t_content="\${$var}"
    echo "Input $var (Default= ${t_content}):"
    read tmpv
    if [  "${tmpv}" != "" ];then
        eval "$var=\"\${tmpv}\""
    fi
    eval "echo '${var}: '\${$var} >>./install.log"
done
#########################################

#privilege check ######
if [ $EUID -ne 0 ];then
	echo "\033[31mThis script must be run as root."
	echo "Run 'sudo su' and run this script again.\033[0m"
	exit 1
fi
#####################

#gen host name set #########
for sslave in `seq 1 1 ${slave_num}`;
do
	slave=${slave}" "${slave_uname}${sslave}
done
all=${master_host_name}" "${slave}
############################

#Check require package ############
KDC_req_package="krb5-kdc krb5-admin-server haveged vim"
echo "[*]Check packet..."
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
	echo "[+]Install packet for KDR :${rpackage}"
	apt-get install ${rpackage} -y
fi

###########################################

#check config for krb5 ###
echo "================================================"
echo "Check krb5 require file. and copy in config dir!"
echo "================================================"
service krb5-admin-server stop
service krb5-kdc stop
sudo mkdir /var/log/kerberos
sudo mkdir /var/log/kerberos
sudo touch /var/log/kerberos/{krb5kdc,kadmin,krb5lib}.log
sudo chmod -R 750  /var/log/kerberos
count=0
for conf_file in ${krb5_conf_file}; do
    if [ -f "$conf_file" ];
    then
	echo "[+]Create ${krb5_conf_file_path[$count]}"	
	/bin/cp ./${conf_file} ${krb5_conf_file_path[$count]}
        sed -i -e "s#{REALM_UPPER}#${krb_realm^^}#i" ${krb5_conf_file_path[$count]}
        sed -i -e "s#{DOMAIN_LOWER}#${krb_realm,,}#i" ${krb5_conf_file_path[$count]}
        sed -i -e "s#{MASTER_NAME}#${master_host_name}#i" ${krb5_conf_file_path[$count]}
    else
	echo "[*]Error !!"
	echo "\033[31m./${conf_file} not exist please clone it from github!\033[0m"
	exit
    fi
    count=$[$count+1]
done
if [ -f /var/lib/krb5kdc/principal ] ; then
	echo "[-]Rmove old principal file..."
	rm -rf /var/lib/krb5kdc/principal*
fi
echo "[+]Create new database..."
echo -e "${passwd}\n${passwd}\n" |krb5_newrealm

#########################
# recreate database for kerberos#######################
#echo "[*]Recreate krb5 database to fix user setting..."
#echo -e "${passwd}\n${passwd}" |kdb5_util create -r ${krb_realm^^} -s
# add host account acl for krb5 ####
echo "[*]Adding kadm5.acl..."
if [ -f /etc/krb5kdc/kadm5.acl ] ; then
        rm -rf /etc/krb5kdc/kadm5.acl
	echo "[-]Remove old kadm5.acl file"
fi
echo "[+]Add */admin@${krb_realm^^} in kadm5.acl}"
echo "*/admin@${krb_realm^^} *" >>/etc/krb5kdc/kadm5.acl	# add admin policy
for host in ${all}; do
	## *   /  instance @ domain  *
	## account / group @ domain  permission
	## permission * means admin
	echo "*/${host}@${krb_realm^^} il" >>/etc/krb5kdc/kadm5.acl	# change normail user policy to "il" 
	echo "[+]Add */${host}@${krb_realm^^} in kadm5.acl}"
done
####################################
echo "================================================"
echo "Create keytable for all all Host"
echo "================================================"
service krb5-admin-server start
service krb5-kdc start
echo -e "${passwd}\n${passwd}" |kadmin.local -q "addprinc admin/${master_host_name}"
echo -e "${passwd}" |kinit admin/${master_host_name}
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
echo "[*]change key owner ${dir}"
chown -R ${username}.${groupid} ${dir}

#copy key to slave 
sleep 5
clear
echo "======================================================================="
echo "start to copy key to slave"
echo "======================================================================="
for sHost in ${slave} ; do
	echo "[*]Start copy to "${sHost}
	echo "[*]mkdir for hadoop "${sHost}":"${dir}" owner:"${username}" group:"${groupid}
	echo "\n\033[31m**********************************************************"
	echo "    You might need to enter ${sHost}'s ROOT password "
	echo "**********************************************************\033[0m\n"
	ssh -t ${user_root}@${sHost} "sudo mkdir -p ${dir}/ca && sudo chown -R ${user_root}.${groupid} ${dir} && sudo apt-get install krb5-user krb5-config -y "
	echo "[+]Copy file to ${sHost}..."
	scp ${dir}/${sHost}/* ${user_root}@${sHost}:${dir}/
	scp ${krb5_conf_file_path[0]} ${user_root}@${sHost}:/tmp/
	echo "[*]Change file owner:"${username}" group:"${groupid}
	ssh -t ${user_root}@${sHost} "sudo chown -R ${username}.${groupid} ${dir}&& sudo mv /tmp/krb5.conf /etc/krb5.conf && sudo chown root.root /etc/krb5.conf" 
done
echo "[*]Move local(${master_host_name}) key to ${dir}..."
mv /opt/key/${master_host_name}/* ${dir}
