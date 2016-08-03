#/bin/bash
# install krb5 first 
#	sudo su
#	sudo apt-get install krb5-kdc krb5-admin-server haveged -y

passwd="q123456"
username="min"
master_uname="master"
slave_uname="slave"
slave_num=2
dir="/opt/key"
#gen slave array. "slave1 skave2 slave3 ...."
for sslave in `seq 1 1 $slave_num`;
do
	slave=$slave" "$slave_uname$sslave
done
##########################################
#gen all set array
all=$master_uname" "$slave
#########################
#Check require package
require_package="krb5-kdc krb5-admin-server haveged vim"
for rp in $require_package ; do
	tmp=""
	tmp=`dpkg-query -l |awk '{print $2}'|grep $rp`
	if [ -z "$tmp" ];
	then
		rpackage=$rpackage" "$rp
	fi		
done

if [ -n "$rpackage" ]; then
	echo "================================================"
	echo "Something missing...Let automatic install it"
	echo "================================================"
	apt install $rpackage -y
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

echo -e "$passwd\n$passwd\n" |krb5_newrealm
echo "*/admin@master *" >>/etc/krb5kdc/kadm5.acl
echo -e "$passwd\n$passwd" |kadmin.local -q "addprinc admin/admin"
service krb5-admin-server restart
echo -e "$passwd" |kinit admin/admin
klist
#create all key for all host
echo "======================================================================="
echo "generate key for all machine"
echo "======================================================================="
for host in $all ;do
	echo -e "$passwd" |kadmin -p admin/admin -q "addprinc -randkey hdfs/$host@master"
	echo -e "$passwd" |kadmin -p admin/admin -q "addprinc -randkey mapred/$host@master"
	echo -e "$passwd" |kadmin -p admin/admin -q "addprinc -randkey HTTP/$host@master"
	echo -e "$passwd" |kadmin -p admin/admin -q "addprinc -randkey yarn/$host@master"
	kadmin.local -q "xst -norandkey -k hdfs.keytab hdfs/$host@master"
	kadmin.local -q "xst -norandkey -k mapred.keytab mapred/$host@master"
	kadmin.local -q "xst -norandkey -k HTTP.keytab HTTP/$host@master"
	kadmin.local -q "xst -norandkey -k yarn.keytab yarn/$host@master"
done
#########
#move key in /opt/key and chang owner
echo "======================================================================="
echo "move key to /opt/key"
echo "======================================================================="
if [ -d $dir ];
then
	rmdir $dir
fi
mkdir -p $dir
mv *.keytab $dir
chown -R `users|awk {'print $1'}`.`users|awk {'print $1'}` $dir

#copy key to slave 
echo "======================================================================="
echo "start to copy key to slave"
echo "======================================================================="
for sHost in $slave ; do
	ssh -t $username@$sHost "sudo chmod  777 /etc"
	scp -r $dir $username@$sHost:/opt/ && scp /etc/krb5.conf $username@$sHost:/etc &&scp /etc/krb5kdc/kdc.conf $username@$sHost:/etc/krb5kdc/
	ssh -t $username@$sHost "sudo chmod  755 /etc"
done

#install require package
echo "======================================================================="
echo "start to install krb5 in slave"
echo "======================================================================="
for sHost in $slave ; do
        ssh -t $username@$sHost "sudo apt-get install krb5-user krb5-config -y"
done


 
