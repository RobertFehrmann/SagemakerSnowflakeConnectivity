#!/bin/bash
# install sagemaker libraries on all nodes
sudo pip install sagemaker_pyspark
sudo pip install boto3
sudo pip install sagemaker
sudo /usr/bin/pip-3.4 install sagemaker_pyspark
sudo /usr/bin/pip-3.4 install boto3
sudo /usr/bin/pip-3.4 install sagemaker
# install snowflake drivers on all nodes
SFC_DIR=/usr/local/lib/snowflake
SFC_SPARK_DRV=spark-snowflake_2.11
SFC_SPARK_VER=2.3.1-spark_2.1
SFC_JDBC_DRV=snowflake-jdbc
SFC_JDBC_VER=3.5.3
sudo mkdir $SFC_DIR
sudo wget https://repo1.maven.org/maven2/net/snowflake/$SFC_SPARK_DRV/$SFC_SPARK_VER/$SFC_SPARK_DRV-$SFC_SPARK_VER.jar -P $SFC_DIR
sudo wget https://repo1.maven.org/maven2/net/snowflake/$SFC_JDBC_DRV/$SFC_JDBC_VER/$SFC_JDBC_DRV-$SFC_JDBC_VER.jar -P $SFC_DIR
# update spark-defaults.conf class path with new libraries
SCRIPT_NAME=update_path.bash
SCRIPT=/tmp/$SCRIPT_NAME
echo '#!/bin/bash' > $SCRIPT
echo 'SFC_JARS=':$SFC_DIR/$SFC_SPARK_DRV-$SFC_SPARK_VER.jar:$SFC_DIR/$SFC_JDBC_DRV-$SFC_JDBC_VER.jar >> $SCRIPT
echo 'SM_JARS=$(/usr/local/bin/sagemakerpyspark-emr-jars :)' >> $SCRIPT
echo 'SPARK_DFL=/usr/lib/spark/conf/spark-defaults.conf' >> $SCRIPT
echo 'SPARK_DFL_TMP=/tmp/spark-defaults.conf' >> $SCRIPT
echo 'DRIVER_CLS="spark.driver.extraClassPath"' >> $SCRIPT
echo 'EXEC_CLS="spark.executor.extraClassPath"' >> $SCRIPT
echo 'sudo cp $SPARK_DFL $SPARK_DFL.bk' >> $SCRIPT
echo 'grep -v $DRIVER_CLS $SPARK_DFL.bk | grep -v $EXEC_CLS > $SPARK_DFL_TMP' >> $SCRIPT
echo 'echo $(grep $DRIVER_CLS $SPARK_DFL.bk):$SM_JARS:$SFC_JARS >> $SPARK_DFL_TMP' >> $SCRIPT
echo 'echo $(grep $EXEC_CLS $SPARK_DFL.bk):$SM_JARS:$SFC_JARS >> $SPARK_DFL_TMP' >> $SCRIPT
echo 'sudo cp $SPARK_DFL_TMP $SPARK_DFL'  >> $SCRIPT
sudo cp $SCRIPT $SFC_DIR/$SCRIPT_NAME
SCRIPT=/tmp/wait-for-bootstrap-complete.sh
echo '#!/bin/bash' > $SCRIPT
echo 'while [ ! -f /var/log/spark/spark-history-server.out ]; do sleep 1; done' >> $SCRIPT
echo 'sh '$SFC_DIR/$SCRIPT_NAME >> $SCRIPT
nohup sudo sh $SCRIPT > /tmp/wait-for-bootstrap-complete.out &
