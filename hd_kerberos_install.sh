filename="hadoop-2.7.2.tar.gz"
client_list="slave1 slave2"
master_name="master"
master_user="min"
client_user="min"
krb5_realm="MIN.LOCAL"
keystore_pass='zz001234'
truststore_pass='zz001234'
cert_signed_passwd='zz001234'
if [ -z $EUID ];then
        echo "This script shoulen't been run as root."
        echo "Run 'sudo su' and run this script again."
        exit 1
fi
if [ -f "/opt/${filename}" ];then
        echo "Start.."
        sleep 3
else
        echo "hadoop install file in path '/opt/${filename}' is missing.."
        echo "Please download/fix filename it and restart command"
        exit
fi
if [ -d "/opt/hadoop" ];then
	rm -rf "/opt/hadoop/"
fi
if [ -d "/opt/hadoop-2.7.2" ];then
        rm -rf "/opt/hadoop-2.7.2"
fi
echo "Start unzip hadoop file.."
tar -C /opt -zxf /opt/${filename}
echo "Moving folder to /opt/hadoop/"
mv /opt/hadoop-2.7.2 /opt/hadoop
echo "Create folder for hadoop"
mkdir -p /opt/hadoop/tmp
mkdir -p /opt/hadoop/dfs/dn
mkdir -p /opt/hadoop/dfs/nn
mkdir -p /opt/hadoop/yarnnm
mkdir -p /opt/key/ca
echo "Setting hadoop configure"
cat core.xml  > /opt/hadoop/etc/hadoop/core-site.xml
cat hdfs.xml |sed -e "s#MIN.LOCAL#${krb5_realm}#g" > /opt/hadoop/etc/hadoop/hdfs-site.xml
cat mapred.xml |sed -e "s#MIN.LOCAL#${krb5_realm}#g"  > /opt/hadoop/etc/hadoop/mapred-site.xml
cat yarn.xml |sed -e "s#MIN.LOCAL#${krb5_realm}#g" > /opt/hadoop/etc/hadoop/yarn-site.xml
cat ssl-client.xml|sed -e "s#tstore_pass#${truststore_pass}#g" > /opt/hadoop/etc/hadoop/ssl-client.xml
cat ssl-server.xml |sed -e "s#truststore_pass#${truststore_pass}#g"|sed -e "s#keystore_pass#${keystore_pass}#g" >/opt/hadoop/etc/hadoop/ssl-server.xml
cat container-executor.cfg |sed -e "s#client_user#${client_user}#g" > /opt/hadoop/etc/hadoop/container-executor.cfg
echo 'slave1
slave2' > /opt/hadoop/etc/hadoop/slaves

sed -i -e 's#${JAVA_HOME}#/usr/lib/jvm/java-8-openjdk-amd64#i' /opt/hadoop/etc/hadoop/hadoop-env.sh
openssl req -new -x509 -keyout /opt/key/ca/test_ca_key -out /opt/key/ca/test_ca_cert -days 9999 -subj '/C=TW/ST=Taipei/L=ccu/O=ccu/OU=ant/CN=min.local' -passout pass:${keystore_pass}
echo "=========================================="
echo "start to copy dir to all client"
echo "=========================================="
for client_name in ${client_list}; do
	echo "==========================================="
	echo "Now is copy file to ${client_name}"
	echo "==========================================="
	ssh ${client_user}@${client_name} -t "sudo scp -r ${master_user}@${master_name}:/opt/hadoop/ /opt/ > /dev/null && sudo mkdir -p /opt/hadoop/logs &&sudo chmod 777 /opt/hadoop/logs&& sudo mkdir -p /opt/key/ &&sudo scp -r ${master_user}@${master_name}:/opt/key/ca/ /opt/key/ > /dev/null && sudo chown -R ${client_user}.${client_user} /opt/key && sudo chown root.${client_user} /opt/hadoop/bin/container-executor && sudo chmod 050 /opt/hadoop/bin/container-executor && sudo chmod u+s /opt/hadoop/bin/container-executor &&sudo chmod g+s /opt/hadoop/bin/container-executor"
	echo "==========================================="
	echo "produce CA for ${client_name}"
	echo "==========================================="
	ssh ${client_user}@${client_name} -t 'keytool -keystore /opt/key/ca/keystore -alias master -validity 9999 -genkey -keyalg RSA -keysize 2048 -dname "CN=${krb5_realm}, OU=ant, O=ccu, L=ccu, ST=Taipei, C=TW"&& keytool -keystore /opt/key/ca/truststore -alias CARoot -import -file /opt/key/ca/test_ca_cert &&keytool -certreq -alias master -keystore /opt/key/ca/keystore -file /opt/key/ca/cert && openssl x509 -req -CA /opt/key/ca/test_ca_cert -CAkey /opt/key/ca/test_ca_key -in /opt/key/ca/cert -out /opt/key/ca/cert_signed -days 9999 -CAcreateserial -passin pass:'${keystore_pass}' &&keytool -keystore /opt/key/ca/keystore -alias CARoot -import -file /opt/key/ca/test_ca_cert &&keytool -keystore /opt/key/ca/keystore -alias master -import -file /opt/key/ca/cert_signed'
done
echo "==========================================="
echo "produce CA for local host"
echo "==========================================="
keytool -keystore /opt/key/ca/keystore -alias master -validity 9999 -genkey -keyalg RSA -keysize 2048 -dname "CN=${krb5_realm}, OU=ant, O=ccu, L=ccu, ST=Taipei, C=TW"
keytool -keystore /opt/key/ca/truststore -alias CARoot -import -file /opt/key/ca/test_ca_cert
keytool -certreq -alias master -keystore /opt/key/ca/keystore -file /opt/key/ca/cert
openssl x509 -req -CA /opt/key/ca/test_ca_cert -CAkey /opt/key/ca/test_ca_key -in /opt/key/ca/cert -out /opt/key/ca/cert_signed -days 9999 -CAcreateserial -passin pass:${keystore_pass}
keytool -keystore /opt/key/ca/keystore -alias CARoot -import -file /opt/key/ca/test_ca_cert
keytool -keystore /opt/key/ca/keystore -alias master -import -file /opt/key/ca/cert_signed
