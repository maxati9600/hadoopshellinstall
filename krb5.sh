#/bin/bash
# install krb5 first 
#	sudo su
#	sudo apt-get install krb5-kdc krb5-admin-server haveged -y

passwd="q123456"
echo -e "$passwd\n$passwd\n" |krb5_newrealm
echo "*/admin@master *" >>/etc/krb5kdc/kadm5.acl
echo -e "$passwd\n$passwd" |kadmin.local -q "addprinc admin/admin"
service krb5-admin-server restart
echo -e "$passwd" |kinit admin/admin
klist
for host in master slave1 slave2 ;do
	echo -e "$passwd" |kadmin -p admin/admin -q "addprinc -randkey hdfs/$host@master"
	echo -e "$passwd" |kadmin -p admin/admin -q "addprinc -randkey mapred/$host@master"
	echo -e "$passwd" |kadmin -p admin/admin -q "addprinc -randkey HTTP/$host@master"
	echo -e "$passwd" |kadmin -p admin/admin -q "addprinc -randkey yarn/$host@master"
	kadmin.local -q "xst -norandkey -k hdfs.keytab hdfs/$host@master"
	kadmin.local -q "xst -norandkey -k mapred.keytab mapred/$host@master"
	kadmin.local -q "xst -norandkey -k HTTP.keytab HTTP/$host@master"
	kadmin.local -q "xst -norandkey -k yarn.keytab yarn/$host@master"
done
mkdir /opt/key
mv *.keytab /opt/key
chown -R `users|awk {'print $1'}`.`users|awk {'print $1'}` /opt/key
echo "======================================================================="
echo "start to copy key to slave"
echo "======================================================================="
for sHost in slave1 slave2 ; do
	scp -r /opt/key min@$sHost:/opt/ &
done
echo "======================================================================="
echo "start to install krb5 in slave"
echo "======================================================================="
for sHost in slave1 slave2 ; do
        ssh -t $sHost "sudo apt-get install krb5-user krb5-config"
done


 
