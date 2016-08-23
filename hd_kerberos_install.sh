tar -C /opt -zxvf hadoop-2.7.2.tar.gz
mv /opt/hadoop-2.7.2 /opt/hadoop
mkdir -p /opt/hadoop/tmp
mkdir -p /opt/hadoop/dfs/dn
mkdir -p /opt/hadoop/dfs/nn

echo '<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
    <name>fs.defaultFS</name>
    <value>hdfs://master:9000</value>
</property>
<property>
    <name>hadoop.tmp.dir</name>
    <value>file:/opt/hadoop/tmp</value>
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
    <name>dfs.namenode.secondary.http-address</name>
    <value>master:50090</value>
</property>
<property>
    <name>dfs.webhdfs.enabled</name>
    <value>true</value>
</property>
<property>
    <name>dfs.namenode.keytab.file</name>
    <value>hdfs.keytab</value>
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
    <value>hdfs.keytab</value>
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
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
</property>
<property>
    <name>mapreduce.jobhistory.address</name>
    <value>master:10020</value>
</property>
<property>
    <name>mapreduce.jobhistory.webapp.address</name>
    <value>master:19888</value>
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
    <name>yarn.nodemanager.auxservices.mapreduce.shuffle.class</name>
    <value>org.apache.hadoop.mapred.ShuffleHandler</value>
</property>
<property>
    <name>yarn.resourcemanager.address</name>
    <value>master:8032</value>
</property>
<property>
    <name>yarn.resourcemanager.scheduler.address</name>
    <value>master:8030</value>
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
    <name>yarn.resourcemanager.webapp.address</name>
    <value>master:8088</value>
</property>
<property>
    <name>yarn.nodemanager.resource.memory-mb</name>
    <value>768</value>
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


