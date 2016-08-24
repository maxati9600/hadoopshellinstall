filename="hadoop-2.7.2.tar.gz"
client_list="slave1 slave2"
master_name="master"
master_user="min"
client_user="min"

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
echo "Setting hadoop configure"
echo '<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>hadoop.tmp.dir</name>
    <value>file:/opt/hadoop/tmp</value>
  </property>
  <property>
    <name>fs.default.name</name>
    <value>hdfs://master:54310</value>
  </property>
<property>
    <name>hadoop.security.authentication</name>
    <value>kerberos</value>
</property>
<property>
    <name>hadoop.security.authorization</name>
    <value>true</value>
</property>
</configuration>' > /opt/hadoop/etc/hadoop/core-site.xml

echo '<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
    <name>dfs.namenode.name.dir</name>
    <value>file:/opt/hadoop/dfs/nn</value>
</property>
<property>
    <name>dfs.datanode.data.dir</name>
    <value>file:/opt/hadoop/dfs/dn</value>
</property>
<property>
    <name>dfs.replication</name>
    <value>2</value>
</property>
<property>
    <name>dfs.namenode.keytab.file</name>
    <value>/opt/key/hdfs.keytab</value>
</property>
<property>
    <name>dfs.namenode.kerberos.principal</name>
    <value>hdfs/_HOST@master</value>
</property>
<property>
    <name>dfs.namenode.kerberos.https.principal</name>
    <value>HTTP/_HOST@master</value>
</property>
<property>
    <name>dfs.datanode.keytab.file</name>
    <value>/opt/key/hdfs.keytab</value>
</property>
<property>
    <name>dfs.datanode.kerberos.principal</name>
    <value>hdfs/_HOST@master</value>
</property>
<property>
    <name>dfs.datanode.kerberos.https.principal</name>
    <value>HTTP/_HOST@master</value>
</property>
</configuration>' > /opt/hadoop/etc/hadoop/hdfs-site.xml


echo '<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
 <name>mapred.job.tracker</name>
    <value>master:54311</value>
</property>
<property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
</property>
<property>  
    <name>mapreduce.jobhistory.keytab</name>  
    <value>/opt/key/mapred.keytab</value>  
</property>  
<property>  
    <name>mapreduce.jobhistory.principal</name>  
    <value>mapred/_HOST@master</value>  
</property>  
</configuration>' > /opt/hadoop/etc/hadoop/mapred-site.xml


echo '<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
</property>
 <property>
    <name>yarn.resourcemanager.scheduler.address</name>
    <value>master:8030</value>
  </property> 
  <property>
    <name>yarn.resourcemanager.address</name>
    <value>master:8032</value>
  </property>
  <property>
    <name>yarn.resourcemanager.webapp.address</name>
    <value>master:8088</value>
  </property>
  <property>
    <name>yarn.resourcemanager.resource-tracker.address</name>
    <value>master:8031</value>
  </property>
  <property>
    <name>yarn.resourcemanager.admin.address</name>
    <value>master:8033</value>
  </property>
<property>  
    <name>yarn.resourcemanager.keytab</name>  
    <value>/opt/key/yarn.keytab</value>  
</property>  
<property>  
    <name>yarn.resourcemanager.principal</name>  
    <value>yarn/_HOST@master</value>  
</property>  
<property>  
    <name>yarn.nodemanager.keytab</name>  
    <value>/opt/key/yarn.keytab</value>  
</property>  
<property>  
    <name>yarn.nodemanager.principal</name>  
    <value>yarn/_HOST@master</value>  
</property>  
<property>  
    <name>yarn.nodemanager.container-executor.class</name>  
    <value>org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor</value>  
</property>  
<property>  
    <name>yarn.nodemanager.linux-container-executor.group</name>  
    <value>hadoop</value>  
</property> 

</configuration>' > /opt/hadoop/etc/hadoop/yarn-site.xml

echo 'slave1
slave2' > /opt/hadoop/etc/hadoop/slaves

sed -i -e 's#${JAVA_HOME}#/usr/lib/jvm/java-8-openjdk-amd64#i' /opt/hadoop/etc/hadoop/hadoop-env.sh
echo "=========================================="
echo "start to copy dir to all client"
echo "=========================================="
for client_name in ${client_list}; do
	echo "Now is copy file to ${client_name}"
	ssh ${client_user}@${client_name} -t "sudo scp -r ${master_user}@${master_name}:/opt/hadoop/ /opt/ > /dev/null"
done
