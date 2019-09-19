## hbase服务监控


**HMaster需要监控的指标**

`http://hmaster:16010/jmx?qry=${name}`

```
# OS层的基础监控
{
name: "java.lang:type=OperatingSystem",
modelerType: "sun.management.OperatingSystemImpl",
MaxFileDescriptorCount: 65535,
OpenFileDescriptorCount: 449,
CommittedVirtualMemorySize: 7786803200,
FreePhysicalMemorySize: 20853329920,
FreeSwapSpaceSize: 0,
ProcessCpuLoad: 0.0004575184172025184,
ProcessCpuTime: 133160000000,
SystemCpuLoad: 0.0024376552242798095,
TotalPhysicalMemorySize: 33566535680,
TotalSwapSpaceSize: 0,
Arch: "amd64",
SystemLoadAverage: 0,
Version: "3.10.0-957.21.3.el7.x86_64",
Name: "Linux",
AvailableProcessors: 8,
ObjectName: "java.lang:type=OperatingSystem"
},

# Hbase的Metrics基础监控
{
name: "Hadoop:service=HBase,name=MetricsSystem,sub=Stats",
modelerType: "MetricsSystem,sub=Stats",
tag.Context: "metricssystem",
tag.Hostname: "namenode1",
NumActiveSources: 10,
NumAllSources: 10,
NumActiveSinks: 0,
NumAllSinks: 0,
SnapshotNumOps: 0,
SnapshotAvgTime: 0,
PublishNumOps: 0,
PublishAvgTime: 0,
DroppedPubAll: 0
}


# Hbase Master的文件系统监控
{
name: "Hadoop:service=HBase,name=Master,sub=FileSystem",
modelerType: "Master,sub=FileSystem",
tag.Context: "master",
tag.Hostname: "namenode1",
HlogSplitTime_num_ops: 6,
HlogSplitTime_min: 0,
HlogSplitTime_max: 3,
HlogSplitTime_mean: 0,
HlogSplitTime_25th_percentile: 0
}

# master 服务监控

{
name: "Hadoop:service=HBase,name=Master,sub=Server",
modelerType: "Master,sub=Server",
tag.liveRegionServers: "datanode1,16020,1564462519783;datanode2,16020,1564462604381;datanode3,16020,1564462671635",
tag.deadRegionServers: "",
tag.zookeeperQuorum: "10.10.31.209:2181,10.10.31.210:2181,10.10.31.211:2181",
tag.serverName: "namenode1,16000,1564457233638",
tag.clusterId: "b9c408a1-b5b2-4262-a248-0774f7cf201c",
tag.isActiveMaster: "true",
tag.Context: "master",
tag.Hostname: "namenode1",
mergePlanCount: 0,
splitPlanCount: 0,
masterActiveTime: 1564457235663,
masterStartTime: 1564457233638,
masterFinishedInitializationTime: 1564457304722,
averageLoad: 46.666666666666664,
numRegionServers: 3,
numDeadRegionServers: 0,
clusterRequests: 1881
},

# MJVM 监控

{
name: "Hadoop:service=HBase,name=JvmMetrics",
modelerType: "JvmMetrics",
tag.Context: "jvm",
tag.ProcessName: "IO",
tag.SessionId: "",
tag.Hostname: "namenode1",
MemNonHeapUsedM: 91.52905,
MemNonHeapCommittedM: 93.03516,
MemNonHeapMaxM: -9.536743e-7,
MemHeapUsedM: 361.58408,
MemHeapCommittedM: 1150.7266,
MemHeapMaxM: 5053.5,
MemMaxM: 5053.5,
GcCountParNew: 152,
GcTimeMillisParNew: 1720,
GcCountConcurrentMarkSweep: 3,
GcTimeMillisConcurrentMarkSweep: 115,
GcCount: 155,
GcTimeMillis: 1835,
ThreadsNew: 0,
ThreadsRunnable: 29,
ThreadsBlocked: 0,
ThreadsWaiting: 73,
ThreadsTimedWaiting: 41,
ThreadsTerminated: 0,
}

# Master IPC监控
{
name: "Hadoop:service=HBase,name=Master,sub=IPC",
modelerType: "Master,sub=IPC",
tag.Context: "master",
tag.Hostname: "namenode1",
queueSize: 0,
numCallsInGeneralQueue: 0,
numCallsInReplicationQueue: 0,
numCallsInPriorityQueue: 0,
numCallsInMetaPriorityQueue: 0,
numOpenConnections: 2,
numActiveHandler: 0,
numGeneralCallsDropped: 0,
numLifoModeSwitches: 0,
numCallsInWriteQueue: 0,
numCallsInReadQueue: 0,
numCallsInScanQueue: 0,
numActiveWriteHandler: 0,
numActiveReadHandler: 0,
numActiveScanHandler: 0,
receivedBytes: 174854305,
}

#
```


**regionserver需要监控的指标**

`http://regionserver:16030/jmx?qry=${name}`

```
# OS层的基础监控
{
name: "java.lang:type=OperatingSystem",
modelerType: "sun.management.OperatingSystemImpl",
MaxFileDescriptorCount: 65535,
OpenFileDescriptorCount: 445,
CommittedVirtualMemorySize: 7784267776,
FreePhysicalMemorySize: 4936138752,
FreeSwapSpaceSize: 0,
ProcessCpuLoad: 0.00032409571981128067,
ProcessCpuTime: 54400000000,
SystemCpuLoad: 0.002120495128528452,
TotalPhysicalMemorySize: 33566535680,
TotalSwapSpaceSize: 0,
Arch: "amd64",
SystemLoadAverage: 0,
Version: "3.10.0-957.21.3.el7.x86_64",
AvailableProcessors: 8,
Name: "Linux",
ObjectName: "java.lang:type=OperatingSystem"
}

# Hbase  metrics 监控
{
name: "Hadoop:service=HBase,name=MetricsSystem,sub=Stats",
modelerType: "MetricsSystem,sub=Stats",
tag.Context: "metricssystem",
tag.Hostname: "datanode2",
NumActiveSources: 18,
NumAllSources: 18,
NumActiveSinks: 0,
NumAllSinks: 0,
SnapshotNumOps: 0,
SnapshotAvgTime: 0,
PublishNumOps: 0,
PublishAvgTime: 0,
DroppedPubAll: 0
},

# regionserver上的各个regions的基本信息
{
name: "Hadoop:service=HBase,name=RegionServer,sub=Regions",
modelerType: "RegionServer,sub=Regions",
tag.Context: "regionserver",
tag.Hostname: "datanode2",
Namespace_default_table_SYSTEM.LOG_region_d555760a5fb5b9d980abe9b273ccd8a3_metric_storeCount: 1,
Namespace_default_table_SYSTEM.LOG_region_d555760a5fb5b9d980abe9b273ccd8a3_metric_storeFileCount: 0,
Namespace_default_table_SYSTEM.LOG_region_d555760a5fb5b9d980abe9b273ccd8a3_metric_memStoreSize: 0,
Namespace_default_table_SYSTEM.LOG_region_d555760a5fb5b9d980abe9b273ccd8a3_metric_maxStoreFileAge: 0,
Namespace_default_table_SYSTEM.LOG_region_d555760a5fb5b9d980abe9b273ccd8a3_metric_minStoreFileAge: 0,
Namespace_default_table_SYSTEM.LOG_region_d555760a5fb5b9d980abe9b273ccd8a3_metric_avgStoreFileAge: 0,
Namespace_default_table_SYSTEM.LOG_region_d555760a5fb5b9d980abe9b273ccd8a3_metric_numReferenceFiles: 0,
Namespace_default_table_SYSTEM.LOG_region_d555760a5fb5b9d980abe9b273ccd8a3_metric_storeFileSize: 0
}


# regionserver的gc信息(ParNew收集器)
{
name: "java.lang:type=GarbageCollector,name=ParNew",
modelerType: "sun.management.GarbageCollectorImpl",
LastGcInfo: {
	GcThreadCount: 11,
	duration: 2,
	endTime: 12144044,
	id: 22,
	memoryUsageAfterGc: [],
	memoryUsageBeforeGc: [],
	startTime: 12144042
	},
CollectionCount: 22,
CollectionTime: 167,
Valid: true,
MemoryPoolNames: [],
Name: "ParNew",
ObjectName: "java.lang:type=GarbageCollector,name=ParNew"
}


#  Hbase 的JVM指标信息

{
name: "Hadoop:service=HBase,name=JvmMetrics",
modelerType: "JvmMetrics",
tag.Context: "jvm",
tag.ProcessName: "IO",
tag.SessionId: "",
tag.Hostname: "datanode2",
MemNonHeapUsedM: 81.60928,
MemNonHeapCommittedM: 83.24219,
MemNonHeapMaxM: -9.536743e-7,
MemHeapUsedM: 140.21527,
MemHeapCommittedM: 485.3125,
MemHeapMaxM: 5053.5,
MemMaxM: 5053.5,
GcCountParNew: 22,
GcTimeMillisParNew: 167,
GcCountConcurrentMarkSweep: 1,
GcTimeMillisConcurrentMarkSweep: 17,
GcCount: 23,
GcTimeMillis: 184,
ThreadsNew: 0,
ThreadsRunnable: 28,
ThreadsBlocked: 0,
ThreadsWaiting: 82,
ThreadsTimedWaiting: 45,
ThreadsTerminated: 0,
LogFatal: 0,
LogError: 0,
LogWarn: 0,
LogInfo: 0
},

# regionserver的服务监控

{
name: "Hadoop:service=HBase,name=RegionServer,sub=Server",
modelerType: "RegionServer,sub=Server",
tag.zookeeperQuorum: "10.10.31.209:2181,10.10.31.210:2181,10.10.31.211:2181",
tag.serverName: "datanode2,16020,1564462604381",
tag.clusterId: "b9c408a1-b5b2-4262-a248-0774f7cf201c",
tag.Context: "regionserver",
tag.Hostname: "datanode2",
regionCount: 47,
storeCount: 47,
hlogFileCount: 1,
hlogFileSize: 0,
storeFileCount: 1,
memStoreSize: 0,
storeFileSize: 4896,
maxStoreFileAge: 1126869734,
minStoreFileAge: 1126869734,
avgStoreFileAge: 1126869734,
numReferenceFiles: 0,
regionServerStartTime: 1564462604381,
averageRegionSize: 104,
storeFileIndexSize: 320,
staticIndexSize: 37,
staticBloomSize: 4,
mutationsWithoutWALCount: 0,
mutationsWithoutWALSize: 0,
percentFilesLocal: 100,
}

# regisonserver 的mem监控
{
name: "Hadoop:service=HBase,name=RegionServer,sub=Memory",
modelerType: "RegionServer,sub=Memory",
tag.Context: "regionserver",
tag.Hostname: "datanode2",
blockedFlushGauge: 0,
memStoreSize: 0,
IncreaseBlockCacheSize_num_ops: 0,
}

# regionserver 的IPC监控

{
name: "Hadoop:service=HBase,name=RegionServer,sub=IPC",
modelerType: "RegionServer,sub=IPC",
tag.Context: "regionserver",
tag.Hostname: "datanode2",
queueSize: 0,
numCallsInGeneralQueue: 0,
numCallsInReplicationQueue: 0,
numCallsInPriorityQueue: 0,
numCallsInMetaPriorityQueue: 0,
numOpenConnections: 0,
numActiveHandler: 0,
numGeneralCallsDropped: 0,
numLifoModeSwitches: 0,
numCallsInWriteQueue: 0,
numCallsInReadQueue: 0,
numCallsInScanQueue: 0,
numActiveWriteHandler: 0,
numActiveReadHandler: 0,
numActiveScanHandler: 0,
receivedBytes: 5150,
}

```


## HDFS 监控项

`http://10.10.4.226:50070/jmx`


```
# JVM基础信息
{
name: "Hadoop:service=NameNode,name=JvmMetrics",
modelerType: "JvmMetrics",
tag.Context: "jvm",
tag.ProcessName: "NameNode",
tag.SessionId: null,
tag.Hostname: "namenode1",
MemNonHeapUsedM: 69.99749,
MemNonHeapCommittedM: 71.1875,
MemNonHeapMaxM: -9.536743e-7,
MemHeapUsedM: 330.91583,
MemHeapCommittedM: 393,
MemHeapMaxM: 889,
MemMaxM: 889,
GcCount: 1134,
GcTimeMillis: 4559,
GcNumWarnThresholdExceeded: 0,
GcNumInfoThresholdExceeded: 0,
GcTotalExtraSleepTime: 1512,
ThreadsNew: 0,
ThreadsRunnable: 6,
ThreadsBlocked: 0,
ThreadsWaiting: 4,
ThreadsTimedWaiting: 26,
ThreadsTerminated: 0,
LogFatal: 0,
LogError: 0,
LogWarn: 9,
LogInfo: 313016
},

# OS层面的监控
{
name: "java.lang:type=OperatingSystem",
modelerType: "sun.management.OperatingSystemImpl",
MaxFileDescriptorCount: 65535,
OpenFileDescriptorCount: 233,
CommittedVirtualMemorySize: 2962006016,
FreePhysicalMemorySize: 20853227520,
FreeSwapSpaceSize: 0,
ProcessCpuLoad: 0.00037989635952441725,
ProcessCpuTime: 1539230000000,
SystemCpuLoad: 0.002522764237294172,
TotalPhysicalMemorySize: 33566535680,
TotalSwapSpaceSize: 0,
AvailableProcessors: 8,
Arch: "amd64",
SystemLoadAverage: 0,
Version: "3.10.0-957.21.3.el7.x86_64",
Name: "Linux",
ObjectName: "java.lang:type=OperatingSystem"
},

# namenode相关监控数据

{
name: "Hadoop:service=NameNode,name=FSNamesystem",
modelerType: "FSNamesystem",
tag.Context: "dfs",
tag.HAState: "standby",
tag.Hostname: "namenode1",
MissingBlocks: 0,
MissingReplOneBlocks: 0,
ExpiredHeartbeats: 0,
TransactionsSinceLastCheckpoint: -380895,
TransactionsSinceLastLogRoll: 0,
LastWrittenTransactionId: 20,
LastCheckpointTime: 1564477331310,
CapacityTotal: 3246358032384,
CapacityTotalGB: 3023,
CapacityUsed: 1143771029504,
CapacityUsedGB: 1065,
CapacityRemaining: 1936950764516,
CapacityRemainingGB: 1804,
CapacityUsedNonDFS: 457994240,
TotalLoad: 27,
SnapshottableDirectories: 0,
}

# rpc服务基础监控信息
{
name: "Hadoop:service=NameNode,name=RpcDetailedActivityForPort8020",
modelerType: "RpcDetailedActivityForPort8020",
tag.port: "8020",
tag.Context: "rpcdetailed",
tag.Hostname: "namenode1",
GetServiceStatusNumOps: 1135196,
GetServiceStatusAvgTime: 0,
StandbyExceptionNumOps: 97,
StandbyExceptionAvgTime: 0.07216494845360824,
BlockReportNumOps: 161,
}


# namenode活动信息
{
name: "Hadoop:service=NameNode,name=NameNodeActivity",
modelerType: "NameNodeActivity",
tag.ProcessName: "NameNode",
tag.SessionId: null,
tag.Context: "dfs",
tag.Hostname: "namenode1",
CreateFileOps: 0,
FilesCreated: 0,
FilesAppended: 0,
GetBlockLocations: 22,
FilesRenamed: 0,
FilesTruncated: 0,
GetListingOps: 0,
DeleteFileOps: 0,
FilesDeleted: 0,
FileInfoOps: 68,
}


# 
```
