echo "Start unzip hadoop file.."
wget http://apache.stu.edu.tw/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz
tar -C /opt -zxf hadoop-2.7.3.tar.gz
echo "Moving folder to /opt/hadoop/"

mv /opt/hadoop-2.7.3 /opt/hadoop
MasterName="master"
SlavePrefix="slave0"
SlaveNum=7
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
    <value>hdfs://'${MasterName}':54310</value>
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
    <value>'${SlaveNum}'</value>
</property>
</configuration>' > /opt/hadoop/etc/hadoop/hdfs-site.xml


echo '<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
 <name>mapred.job.tracker</name>
    <value>'${MasterName}':54311</value>
</property>
<property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
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
    <value>'${MasterName}':8030</value>
  </property> 
  <property>
    <name>yarn.resourcemanager.address</name>
    <value>'${MasterName}':8032</value>
  </property>
  <property>
    <name>yarn.resourcemanager.webapp.address</name>
    <value>'${MasterName}':8088</value>
  </property>
  <property>
    <name>yarn.resourcemanager.resource-tracker.address</name>
    <value>'${MasterName}':8031</value>
  </property>
  <property>
    <name>yarn.resourcemanager.admin.address</name>
    <value>'${MasterName}':8033</value>
  </property>
</configuration>' > /opt/hadoop/etc/hadoop/yarn-site.xml
slaveTmp=""
for i in $(seq 1 $SlaveNum);
do
	slaveTmp=${slaveTmp}"\n"${SlavePrefix}${i}
done
echo -e ${slaveTmp} > /opt/hadoop/etc/hadoop/slaves
chown -R hduser:hadoop /opt/hadoop
sed -i -e 's#${JAVA_HOME}#/usr/lib/jvm/java-7-openjdk-amd64#i' /opt/hadoop/etc/hadoop/hadoop-env.sh
