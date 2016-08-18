#/bin/bash
# install krb5 first 
#	sudo su
#	sudo apt-get install krb5-kdc krb5-admin-server haveged -y

passwd="q123456"
username="min"
master_uname="master"
krb_realm="master"
slave_uname="slave"
slave_num=2
dir="/opt/key"
#gen slave array. "slave1 skave2 slave3 ...."
for sslave in `seq 1 1 ${slave_num}`;
do
	slave=${slave}" "${slave_uname}${sslave}
done
##########################################
#gen all set array
all=${master_uname}" "${slave}
#########################
#Check require package
require_package="krb5-kdc krb5-admin-server haveged vim"
for rp in ${require_package} ; do
	tmp=""
	tmp=`dpkg-query -l |awk '{print $2}'|grep ${rp}`
	if [ -z "${tmp}" ];
	then
		rpackage=${rpackage}" "${rp}
	fi		
done

if [ -n "${rpackage}" ]; then
	clear
	echo "================================================"
	echo "Something missing...automatic install it"
	echo "================================================"
	sleep 2
	apt-get install ${rpackage} -y
fi

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
	echo "./krb5.conf not exist please clone it from github!"
        exit
fi

echo -e "${passwd}\n${passwd}\n" |krb5_newrealm
for host in ${all}; do
	echo "*/${host}@${krb_realm} *" >>/etc/krb5kdc/kadm5.acl
done
echo -e "${passwd}\n${passwd}" |kadmin.local -q "addprinc admin/admin"
service krb5-admin-server restart
echo -e "${passwd}" |kinit admin/admin
klist
#create all key for all host
echo "======================================================================="
echo "generate key for all machine"
echo "======================================================================="
for host in $all ;do
	mkdir -p ${dir}"/"${host}
	kadmin.local -q "addprinc -randkey hdfs/${host}"
        kadmin.local -q "addprinc -randkey mapred/${host}"
        kadmin.local -q "addprinc -randkey HTTP/${host}"
        kadmin.local -q "addprinc -randkey yarn/${host}"
	kadmin.local -q "ktadd -norandkey -k ${dir}/${host}/hdfs.keytab hdfs/${host}"
        kadmin.local -q "ktadd -norandkey -k ${dir}/${host}/mapred.keytab mapred/${host}"
        kadmin.local -q "ktadd -norandkey -k ${dir}/${host}/HTTP.keytab HTTP/${host}"
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
echo "======================================================================="
echo "start to copy key to slave"
echo "======================================================================="
for sHost in ${slave} ; do
	echo "Start copy to"${sHost}
	ssh -t ${username}@${sHost} "sudo mkdir -p ${dir} && sudo chown ${username}.${username} ${dir}"
	scp $dir/${sHost}/* ${username}@${sHost}:${dir}/ 
done


 
