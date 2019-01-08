#!/bin/bash

#Directory in which to place the lock files
export LOCK_FILE_DIR=${lock.file.dir}

if [[ ! -d ${LOCK_FILE_DIR} || ! -w ${LOCK_FILE_DIR} ]]; then
  "Lock file directory ${LOCK_FILE_DIR} does not exist or is not writable. Exiting..."
  exit 1
fi

. ../system/header.sh

. ../ingest/tables-env.sh

# regex matching changed since bash 3.1....ensure we are forward compatible
shopt -s compat31 > /dev/null 2>&1

# load the external password specifications.  The following needs to be defined in this script: PASSWORD, TRUSTSTORE_PASSWORD, KEYSTORE_PASSWORD
function checkForVar (){
   found=`cat $1 | egrep " $2 *="`
   if [[ "$found" == "" ]]; then
      echo "$2,"
   fi
}

PASSWORD_INGEST_ENV="${PASSWORD_INGEST_ENV}"
if [[ "$PASSWORD_INGEST_ENV" != "" ]]; then
   if [[ -e ${PASSWORD_INGEST_ENV} ]]; then
      missing=\
"$(checkForVar $PASSWORD_INGEST_ENV "PASSWORD")\
$(checkForVar $PASSWORD_INGEST_ENV "TRUSTSTORE_PASSWORD")\
$(checkForVar $PASSWORD_INGEST_ENV "KEYSTORE_PASSWORD")"
      if [[ "$missing" != "" ]]; then
         echo "FATAL: ${PASSWORD_INGEST_ENV} is missing the following definitions: $missing"
         exit 10
      fi
      . "$PASSWORD_INGEST_ENV"
   else
      echo "FATAL: ${PASSWORD_INGEST_ENV} was not found  Please create that script on this system."
      exit 10
   fi
else
   echo "FATAL: PASSWORD_INGEST_ENV was not defined.  Please define this in your deployment properties and create that script on this system."
   echo "   e.g. /opt/datawave-ingest/ingest-passwd.sh:"
   echo "        export PASSWORD=\"accumulo_passwd\""
   echo "        export TRUSTSTORE_PASSWORD=\"trust_passwd\""
   echo "        export KEYSTORE_PASSWORD=\"cert_passwd\""
   exit 10
fi

# if a deployment specific environment has been specified, then load it
ADDITIONAL_INGEST_ENV="${ADDITIONAL_INGEST_ENV}"
if [[ "$ADDITIONAL_INGEST_ENV" != "" ]]; then
   . "$ADDITIONAL_INGEST_ENV"
fi

ADDITIONAL_INGEST_LIBS="${ADDITIONAL_INGEST_LIBS}"

# NOTE:
# Make sure to use the following pattern when setting variables and you want to assign them default values.
#
# (1) VARIABLE_X=${VARIABLE_X}
# (2) VARIABLE_X=${VARIABLE_X:-<default value>}
#
# - The first assignment is used by maven during compile to set variables to the value defined in the
#   default.properties (or dev.properties, etc.) files.
# - The second assignment sets a variable to a "default" value in the event that it was not set in the
#   first (previous) assignment.
#

# Provides a method to run map-file-bulk-loader as a different user
MAP_FILE_LOADER_COMMAND_PREFIX="${MAP_FILE_LOADER_COMMAND_PREFIX}"
MAP_FILE_LOADER_EXTRA_ARGS="${MAP_FILE_LOADER_EXTRA_ARGS}"
MAP_FILE_LOADER_SEPARATE_START="${MAP_FILE_LOADER_SEPARATE_START}"
MAP_FILE_LOADER_SEPARATE_START="${MAP_FILE_LOADER_SEPARATE_START:-false}"
RCPT_TO="${RCPT_TO}"
SEND_JOB_EMAIL_DISABLED="${SEND_JOB_EMAIL_DISABLED}"

HADOOP_HOME="${HADOOP_HOME}"
MAPRED_HOME="${MAPRED_HOME}"
MAPRED_HOME="${MAPRED_HOME:-$HADOOP_HOME}"

USERNAME="${USERNAME}"

WAREHOUSE_ACCUMULO_HOME="${WAREHOUSE_ACCUMULO_HOME}"
WAREHOUSE_ACCUMULO_LIB="${WAREHOUSE_ACCUMULO_LIB}"
WAREHOUSE_ACCUMULO_BIN="${WAREHOUSE_ACCUMULO_BIN}"
WAREHOUSE_ACCUMULO_LIB="${WAREHOUSE_ACCUMULO_LIB:-$WAREHOUSE_ACCUMULO_HOME/lib}"
WAREHOUSE_ACCUMULO_BIN="${WAREHOUSE_ACCUMULO_BIN:-$WAREHOUSE_ACCUMULO_HOME/bin}"
WAREHOUSE_HDFS_NAME_NODE="${WAREHOUSE_HDFS_NAME_NODE}"
WAREHOUSE_NAME_BASE_DIR="${WAREHOUSE_NAME_BASE_DIR}"
WAREHOUSE_JOBTRACKER_NODE="${WAREHOUSE_JOBTRACKER_NODE}"
WAREHOUSE_ZOOKEEPERS="${WAREHOUSE_ZOOKEEPERS}"
WAREHOUSE_INSTANCE_NAME="${WAREHOUSE_INSTANCE_NAME}"
# setting these two times may seem unnecessary, but the first one is required if
# the property is set in the assembly properties (see datawave_deploy).  The second
# one is needed if it is not set explicitly but HADOOP_HOME is.
WAREHOUSE_HADOOP_HOME="${WAREHOUSE_HADOOP_HOME}"
WAREHOUSE_HADOOP_HOME="${WAREHOUSE_HADOOP_HOME:-$HADOOP_HOME}"
WAREHOUSE_MAPRED_HOME="${WAREHOUSE_MAPRED_HOME}"
WAREHOUSE_MAPRED_HOME="${WAREHOUSE_MAPRED_HOME:-$MAPRED_HOME}"
WAREHOUSE_HADOOP_CONF="${WAREHOUSE_HADOOP_CONF}"
WAREHOUSE_HADOOP_CONF="${WAREHOUSE_HADOOP_CONF:-$WAREHOUSE_HADOOP_HOME/conf}"

INGEST_ACCUMULO_HOME="${INGEST_ACCUMULO_HOME}"
INGEST_HDFS_NAME_NODE="${INGEST_HDFS_NAME_NODE}"
INGEST_JOBTRACKER_NODE="${INGEST_JOBTRACKER_NODE}"
INGEST_ZOOKEEPERS="${INGEST_ZOOKEEPERS}"
INGEST_INSTANCE_NAME="${INGEST_INSTANCE_NAME}"
# setting these two times may seem unnecessary, but the first one is required if
# the property is set in the assembly properties (see datawave_deploy).  The second
# one is needed if it is not set explicitly but HADOOP_HOME is.
INGEST_HADOOP_HOME="${INGEST_HADOOP_HOME}"
INGEST_HADOOP_HOME="${INGEST_HADOOP_HOME:-$HADOOP_HOME}"
INGEST_MAPRED_HOME="${INGEST_MAPRED_HOME}"
INGEST_MAPRED_HOME="${INGEST_MAPRED_HOME:-$MAPRED_HOME}"
INGEST_HADOOP_CONF="${INGEST_HADOOP_CONF}"
INGEST_HADOOP_CONF="${INGEST_HADOOP_CONF:-$INGEST_HADOOP_HOME/conf}"

# STAGING_HOSTS is a comma delimited list of hosts
STAGING_HOSTS="${STAGING_HOSTS}"
INGEST_HOST="${INGEST_HOST}"
ROLLUP_HOST="${ROLLUP_HOST}"

# hadoop and child opts for ingest
MAPRED_INGEST_OPTS="${MAPRED_INGEST_OPTS}"
HADOOP_INGEST_OPTS="${HADOOP_INGEST_OPTS}"
CHILD_INGEST_OPTS="${CHILD_INGEST_OPTS}"

LIVE_CHILD_MAX_MEMORY_MB="${LIVE_CHILD_MAX_MEMORY_MB}"
BULK_CHILD_MAX_MEMORY_MB="${BULK_CHILD_MAX_MEMORY_MB}"
MISSION_MGMT_CHILD_MAP_MAX_MEMORY_MB="${MISSION_MGMT_CHILD_MAP_MAX_MEMORY_MB}"

# The next two comma delimited lists work in concert with each other and must align
CONFIG_DATA_TYPES="${CONFIG_DATA_TYPES}"
CONFIG_FILES="${CONFIG_FILES}"
if [[ "$CONFIG_FILES" == "" ]]; then
    # attempt to create the CONFIG_DATA_TYPES and CONFIG_FILES by scanning the config directory
    for config_file in ../../config/*.xml; do
        CONFIG_DATA_TYPE=`grep -A 1 -B 1 '>data.name<' $config_file | grep '<value>' | sed 's/.*<value>//' | sed 's/<\/value>.*//' | sed 's/\.//'`
        if [[ "$CONFIG_DATA_TYPE" != "" ]]; then
            CONFIG_DATA_TYPES=$CONFIG_DATA_TYPE,$CONFIG_DATA_TYPES
            CONFIG_FILES=${config_file##*/},$CONFIG_FILES
        fi
    done
fi

BULK_MAP_OUTPUT_COMPRESS=${BULK_MAP_OUTPUT_COMPRESS}
BULK_MAP_OUTPUT_COMPRESS=${BULK_MAP_OUTPUT_COMPRESS:-true}
BULK_MAP_OUTPUT_COMPRESSION_CODEC=${BULK_MAP_OUTPUT_COMPRESSION_CODEC}
BULK_MAP_OUTPUT_COMPRESSION_CODEC=${BULK_MAP_OUTPUT_COMPRESSION_CODEC:-org.apache.hadoop.io.compress.DefaultCodec}
BULK_MAP_OUTPUT_COMPRESSION_TYPE=${BULK_MAP_OUTPUT_COMPRESSION_TYPE}
BULK_MAP_OUTPUT_COMPRESSION_TYPE=${BULK_MAP_OUTPUT_COMPRESSION_TYPE:-RECORD}

LIVE_MAP_OUTPUT_COMPRESS=${LIVE_MAP_OUTPUT_COMPRESS}
LIVE_MAP_OUTPUT_COMPRESS=${LIVE_MAP_OUTPUT_COMPRESS:-true}
LIVE_MAP_OUTPUT_COMPRESSION_CODEC=${LIVE_MAP_OUTPUT_COMPRESSION_CODEC}
LIVE_MAP_OUTPUT_COMPRESSION_CODEC=${LIVE_MAP_OUTPUT_COMPRESSION_CODEC:-org.apache.hadoop.io.compress.DefaultCodec}
LIVE_MAP_OUTPUT_COMPRESSION_TYPE=${LIVE_MAP_OUTPUT_COMPRESSION_TYPE}
LIVE_MAP_OUTPUT_COMPRESSION_TYPE=${LIVE_MAP_OUTPUT_COMPRESSION_TYPE:-RECORD}

BULK_INGEST_DATA_TYPES="${BULK_INGEST_DATA_TYPES}"
LIVE_INGEST_DATA_TYPES="${LIVE_INGEST_DATA_TYPES}"
MISSION_MGMT_DATA_TYPES="${MISSION_MGMT_DATA_TYPES}"

BULK_INGEST_REDUCERS="${BULK_INGEST_REDUCERS}"
LIVE_INGEST_REDUCERS="${LIVE_INGEST_REDUCERS}"

declare -i INGEST_BULK_MAPPERS=${INGEST_BULK_MAPPERS}
declare -i INGEST_MAX_BULK_BLOCKS_PER_JOB=${INGEST_MAX_BULK_BLOCKS_PER_JOB}
declare -i INGEST_LIVE_MAPPERS=${INGEST_LIVE_MAPPERS}
declare -i INGEST_MAX_LIVE_BLOCKS_PER_JOB=${INGEST_MAX_LIVE_BLOCKS_PER_JOB}

MAP_LOADER_HDFS_NAME_NODES="${MAP_LOADER_HDFS_NAME_NODES}"
MAP_LOADER_HDFS_NAME_NODES="${MAP_LOADER_HDFS_NAME_NODES:-$WAREHOUSE_HDFS_NAME_NODE}"
NUM_MAP_LOADERS="${NUM_MAP_LOADERS}"
NUM_MAP_LOADERS="${NUM_MAP_LOADERS:-1}"

ZOOKEEPER_HOME="${ZOOKEEPER_HOME}"

JAVA_HOME="${JAVA_HOME}"
PYTHON="${PYTHON}"

HDFS_BASE_DIR="${HDFS_BASE_DIR}"

BASE_WORK_DIR="${BASE_WORK_DIR}"
BASE_WORK_DIR="${BASE_WORK_DIR:-/data/Ingest}"

HDFS_MONITOR_ARGS="${HDFS_MONITOR_ARGS}"

MONITOR_SERVER_HOST="${MONITOR_SERVER_HOST}"
MONITOR_ENABLED="${MONITOR_ENABLED}"
MONITOR_ENABLED="${MONITOR_ENABLED:-true}"

LOG_DIR="${LOG_DIR}"
FLAG_DIR="${FLAG_DIR}"
BIN_DIR_FOR_FLAGS="${BIN_DIR_FOR_FLAGS}"
FLAG_MAKER_CONFIG="${FLAG_MAKER_CONFIG}"

declare -i NUM_SHARDS=${NUM_SHARDS}
declare -i NUM_DATE_INDEX_SHARDS=${NUM_DATE_INDEX_SHARDS}

MAP_LOADER_MAJC_THRESHOLD="${MAP_LOADER_MAJC_THRESHOLD}"
MAP_LOADER_MAJC_THRESHOLD="${MAP_LOADER_MAJC_THRESHOLD:-32000}"

# using ../ingest instead of ./ allows scripts in other bin directories to use this
findVersion (){
  ls -1 $1/$2-*.jar | grep -v sources | grep -v javadoc | sort | tail -1 | sed 's/.*\///' | sed "s/$2-//" | sed 's/.jar//'
}
findHadoopVersion (){
  $1/bin/hadoop version | head -1 | awk '{print $2}'
}
METRICS_VERSION=$(findVersion ../../lib datawave-metrics-core)
INGEST_VERSION=$(findVersion ../../lib datawave-ingest-csv)
ZOOKEEPER_VERSION=$(findVersion $ZOOKEEPER_HOME zookeeper)
HADOOP_VERSION=$(findHadoopVersion $INGEST_HADOOP_HOME)


# Turn some of the comma delimited lists into arrays
OLD_IFS="$IFS"
IFS=","
FLAG_MAKER_CONFIG=( $FLAG_MAKER_CONFIG )
CONFIG_DATA_TYPES=( $CONFIG_DATA_TYPES )
CONFIG_FILES=( $CONFIG_FILES )
MAP_LOADER_HDFS_NAME_NODES=( $MAP_LOADER_HDFS_NAME_NODES )
NUM_MAP_LOADERS=( $NUM_MAP_LOADERS )
IFS="$OLD_IFS"

# Export the variables as needed (required by some python scripts and some java code)
export LOG_DIR
export FLAG_DIR
export BIN_DIR_FOR_FLAGS
export INGEST_HDFS_NAME_NODE HDFS_BASE_DIR BASE_WORK_DIR
export INGEST_BULK_MAPPERS INGEST_MAX_BULK_BLOCKS_PER_JOB
export INGEST_LIVE_MAPPERS INGEST_MAX_LIVE_BLOCKS_PER_JOB
export BULK_INGEST_REDUCERS LIVE_INGEST_REDUCERS MISSION_MGMT_INGEST_REDUCERS
export BULK_INGEST_DATA_TYPES LIVE_INGEST_DATA_TYPES MISSION_MGMT_DATA_TYPES
export MONITOR_SERVER_HOST MONITOR_ENABLED
export PYTHON INGEST_HADOOP_HOME WAREHOUSE_HADOOP_HOME JAVA_HOME
export NUM_SHARDS NUM_DATE_INDEX_SHARDS
export INDEX_STATS_MAX_MAPPERS

BULK_CHILD_MAP_MAX_MEMORY_MB="${BULK_CHILD_MAP_MAX_MEMORY_MB}"
BULK_CHILD_MAP_MAX_MEMORY_MB="${BULK_CHILD_MAP_MAX_MEMORY_MB:-$BULK_CHILD_MAX_MEMORY_MB}"
LIVE_CHILD_MAP_MAX_MEMORY_MB="${LIVE_CHILD_MAP_MAX_MEMORY_MB}"
LIVE_CHILD_MAP_MAX_MEMORY_MB="${LIVE_CHILD_MAP_MAX_MEMORY_MB:-$LIVE_CHILD_MAX_MEMORY_MB}"

BULK_CHILD_REDUCE_MAX_MEMORY_MB="${BULK_CHILD_REDUCE_MAX_MEMORY_MB}"
BULK_CHILD_REDUCE_MAX_MEMORY_MB="${BULK_CHILD_REDUCE_MAX_MEMORY_MB:-$BULK_CHILD_MAX_MEMORY_MB}"
LIVE_CHILD_REDUCE_MAX_MEMORY_MB="${LIVE_CHILD_REDUCE_MAX_MEMORY_MB}"
LIVE_CHILD_REDUCE_MAX_MEMORY_MB="${LIVE_CHILD_REDUCE_MAX_MEMORY_MB:-$LIVE_CHILD_MAX_MEMORY_MB}"

DEFAULT_IO_SORT_MB="${DEFAULT_IO_SORT_MB}"
DEFAULT_IO_SORT_MB="${DEFAULT_IO_SORT_MB:-"768"}"
BULK_CHILD_IO_SORT_MB="${BULK_CHILD_IO_SORT_MB}"
BULK_CHILD_IO_SORT_MB="${BULK_CHILD_IO_SORT_MB:-$DEFAULT_IO_SORT_MB}"
LIVE_CHILD_IO_SORT_MB="${LIVE_CHILD_IO_SORT_MB}"
LIVE_CHILD_IO_SORT_MB="${LIVE_CHILD_IO_SORT_MB:-$DEFAULT_IO_SORT_MB}"

COMPOSITE_INGEST_DATA_TYPES="${COMPOSITE_INGEST_DATA_TYPES}"
DEPRECATED_INGEST_DATA_TYPES="${DEPRECATED_INGEST_DATA_TYPES}"

BULK_INGEST_GROUPING="${BULK_INGEST_GROUPING}"
BULK_INGEST_GROUPING="${BULK_INGEST_GROUPING:-none}"
LIVE_INGEST_GROUPING="${LIVE_INGEST_GROUPING}"
LIVE_INGEST_GROUPING="${LIVE_INGEST_GROUPING:-none}"

INGEST_BULK_JOBS="${INGEST_BULK_JOBS}"
INGEST_LIVE_JOBS="${INGEST_LIVE_JOBS}"

BULK_INGEST_TIMEOUT_SECS="${BULK_INGEST_TIMEOUT_SECS}"
BULK_INGEST_TIMEOUT_SECS="${BULK_INGEST_TIMEOUT_SECS:-300}"
LIVE_INGEST_TIMEOUT_SECS="${LIVE_INGEST_TIMEOUT_SECS}"
LIVE_INGEST_TIMEOUT_SECS="${LIVE_INGEST_TIMEOUT_SECS:-10}"

declare -i INDEX_STATS_MAX_MAPPERS=${INDEX_STATS_MAX_MAPPERS}

# Export the variables as needed (required by some python scripts and some java code)
export INGEST_BULK_JOBS
export INGEST_LIVE_JOBS
export BULK_INGEST_GROUPING LIVE_INGEST_GROUPING
export BULK_INGEST_TIMEOUT_SECS LIVE_INGEST_TIMEOUT_SECS

# CERT required for various download scripts (PEM format)
export SERVER_CERT="${SERVER_CERT}"
export KEYSTORE="${KEYSTORE}"
export KEYSTORE_TYPE="${KEYSTORE_TYPE}"
export TRUSTSTORE="${TRUSTSTORE}"
export TRUSTSTORE_TYPE="${TRUSTSTORE_TYPE}"


LOAD_JOBCACHE_CPU_MULTIPLIER="${LOAD_JOBCACHE_CPU_MULTIPLIER}"
declare -i LOAD_JOBCACHE_CPU_MULTIPLIER=${LOAD_JOBCACHE_CPU_MULTIPLIER:-2}

# some functions used by script to parse flag file names

isNumber() {
  re='^[0-9]+$'
  if [[ $1 =~ $re ]]; then
    echo "true"
  else
    echo "false"
  fi
}

flagPipeline() {
  BASENAME=${1%.*}
  PIPELINE=${BASENAME##*.}
  if [[ $(isNumber $PIPELINE) == "true" ]]; then
    echo $PIPELINE
  else
    echo 0
  fi
}

flagBasename() {
  f=$1
  BASENAME=${f%%.flag*}
  echo $BASENAME
}