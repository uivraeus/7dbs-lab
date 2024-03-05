# Comparison of `wiki` table in EMR and locally

Reproduced steps from Day 2

```shell
aws emr create-cluster \
  --name "My example 6.15-cluster" \
  --release-label emr-6.15.0 \
  --ec2-attributes KeyName=HBaseShell \
  --use-default-roles \
  --instance-type m5.xlarge \
  --instance-count 3 \
  --applications Name=HBase
```

```console
hbase:001:0> version
2.4.17-amzn-3, rUnknown, Thu Nov  2 05:41:41 UTC 2023
Took 0.0003 seconds
hbase:002:0> status
1 active master, 0 backup masters, 2 servers, 0 dead, 1.0000 average load
Took 0.6299 seconds
```

***Local `hbase:meta` scan for `wiki` (Ref):***

```console
wiki,,1709574798242.366ea2578ce7f8b87640155fd column=info:regioninfo, timestamp=2024-03-04T17:53:27.617, value={ENCODED => 366ea2578ce7f8b87640155fd7a6ce16, NAME => 'wiki,,1709574797a6ce16.                                      8242.366ea2578ce7f8b87640155fd7a6ce16.', STARTKEY => '', ENDKEY => 'Church!'}
wiki,,1709574798242.366ea2578ce7f8b87640155fd column=info:server, timestamp=2024-03-04T17:53:27.617, value=3d7ff9acd747:160207a6ce16.
wiki,Church!,1709574798242.2526f82d8f8c8d101e column=info:regioninfo, timestamp=2024-03-04T17:53:27.617, value={ENCODED => 2526f82d8f8c8d101e2a77653bfbd768, NAME => 'wiki,Church!,172a77653bfbd768.                               09574798242.2526f82d8f8c8d101e2a77653bfbd768.', STARTKEY => 'Church!', ENDKEY => ''}
wiki,Church!,1709574798242.2526f82d8f8c8d101e column=info:server, timestamp=2024-03-04T17:53:27.617, value=3d7ff9acd747:160202a77653bfbd768.
```

```console
hbase:008:0> describe 'hbase:meta'
Table hbase:meta is ENABLED
hbase:meta, {TABLE_ATTRIBUTES => {IS_META => 'true', coprocessor$1 => '|org.apache.hadoop.hbase.coprocessor.MultiRowMutationEndpoint|536870911|', METADATA => {'hbase.store.file-tracker.impl' => 'DEFAULT'}}}
COLUMN FAMILIES DESCRIPTION
{NAME => 'info', INDEX_BLOCK_ENCODING => 'NONE', VERSIONS => '3', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'ROW_INDEX_V1', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'ROWCOL', IN_MEMORY => 'true', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '8192 B (8KB)'}

{NAME => 'rep_barrier', INDEX_BLOCK_ENCODING => 'NONE', VERSIONS => '2147483647', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'ROW_INDEX_V1', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'ROWCOL', IN_MEMORY => 'true', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '
65536 B (64KB)'}

{NAME => 'table', INDEX_BLOCK_ENCODING => 'NONE', VERSIONS => '3', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'ROW_INDEX_V1', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'ROWCOL', IN_MEMORY => 'true', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '8192 B (8KB)'}
```

```console
hbase:007:0> describe 'wiki'
Table wiki is ENABLED
wiki, {TABLE_ATTRIBUTES => {METADATA => {'hbase.store.file-tracker.impl' => 'DEFAULT'}}}
COLUMN FAMILIES DESCRIPTION
{NAME => 'revision', INDEX_BLOCK_ENCODING => 'NONE', VERSIONS => '2147483647', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'ROW', IN_MEMORY => 'false', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '65536 B (64KB)'}

{NAME => 'text', INDEX_BLOCK_ENCODING => 'NONE', VERSIONS => '2147483647', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'ROW', IN_MEMORY => 'false', COMPRESSION => 'GZ', BLOCKCACHE => 'true', BLOCKSIZE => '65536 B (64KB)'}
```


***EMR:***

```console
wiki,,1709577651152.c68cfc4dcf17ed4148cf7e07a column=info:regioninfo, timestamp=2024-03-04T18:40:55.150, value={ENCODED => c68cfc4dcf17ed4148cf7e07a25155d9, NAME => 'wiki,,170957725155d9.                                      651152.c68cfc4dcf17ed4148cf7e07a25155d9.', STARTKEY => '', ENDKEY => 'Chlorofm'}
wiki,,1709577651152.c68cfc4dcf17ed4148cf7e07a column=info:server, timestamp=2024-03-04T18:40:55.150, value=ip-172-31-34-162.eu-north-1.compute.internal:1602025155d9.
wiki,Chlorofm,1709577651152.6542ccf4b64787f26 column=info:regioninfo, timestamp=2024-03-04T18:40:55.127, value={ENCODED => 6542ccf4b64787f26257954e5a4ca1ff, NAME => 'wiki,Chlorofm257954e5a4ca1ff.                              ,1709577651152.6542ccf4b64787f26257954e5a4ca1ff.', STARTKEY => 'Chlorofm', ENDKEY => 'Church!'}
wiki,Chlorofm,1709577651152.6542ccf4b64787f26 column=info:server, timestamp=2024-03-04T18:40:55.127, value=ip-172-31-34-162.eu-north-1.compute.internal:16020257954e5a4ca1ff.
wiki,Church!,1709577656807.fe67ff8223705a9bf9 column=info:regioninfo, timestamp=2024-03-04T18:41:00.345, value={ENCODED => fe67ff8223705a9bf9e56bb8b44c9f0b, NAME => 'wiki,Church!,e56bb8b44c9f0b.                               1709577656807.fe67ff8223705a9bf9e56bb8b44c9f0b.', STARTKEY => 'Church!', ENDKEY => 'Molar n'}
wiki,Church!,1709577656807.fe67ff8223705a9bf9 column=info:server, timestamp=2024-03-04T18:41:00.345, value=ip-172-31-38-77.eu-north-1.compute.internal:16020e56bb8b44c9f0b.
wiki,Molar n,1709577656807.05a65ec5d25cc0239a column=info:regioninfo, timestamp=2024-03-04T18:41:00.279, value={ENCODED => 05a65ec5d25cc0239a05a93d8c6466b5, NAME => 'wiki,Molar n,05a93d8c6466b5.                               1709577656807.05a65ec5d25cc0239a05a93d8c6466b5.', STARTKEY => 'Molar n', ENDKEY => ''}
wiki,Molar n,1709577656807.05a65ec5d25cc0239a column=info:server, timestamp=2024-03-04T18:41:00.279, value=ip-172-31-38-77.eu-north-1.compute.internal:1602005a93d8c6466b5.
```

```console
hbase:009:0> describe 'hbase:meta'
Table hbase:meta is ENABLED
hbase:meta, {TABLE_ATTRIBUTES => {IS_META => 'true', coprocessor$1 => '|org.apache.hadoop.hbase.coprocessor.MultiRowMutationEndpoint|536870911|'}}
COLUMN FAMILIES DESCRIPTION
{NAME => 'info', BLOOMFILTER => 'NONE', IN_MEMORY => 'true', VERSIONS => '3', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', COMPRESSION => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', BLOCKCACHE => 'true', BLOCKSIZE => '8192', REPLICATION_SCOPE => '0'}

{NAME => 'rep_barrier', BLOOMFILTER => 'NONE', IN_MEMORY => 'true', VERSIONS => '2147483647', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', COMPRESSION => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', BLOCKCACHE => 'true', BLOCKSIZE => '65536', REPLICATION_SCOPE => '0'}

{NAME => 'table', BLOOMFILTER => 'NONE', IN_MEMORY => 'true', VERSIONS => '3', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', COMPRESSION => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', BLOCKCACHE => 'true', BLOCKSIZE => '8192', REPLICATION_SCOPE => '0'}
```

```console
hbase:010:0> describe 'wiki'
Table wiki is ENABLED
wiki
COLUMN FAMILIES DESCRIPTION
{NAME => 'revision', BLOOMFILTER => 'ROW', IN_MEMORY => 'false', VERSIONS => '2147483647', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', COMPRESSION => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', BLOCKCACHE => 'true', BLOCKSIZE => '65536', REPLICATION_SCOPE => '0'}

{NAME => 'text', BLOOMFILTER => 'ROW', IN_MEMORY => 'false', VERSIONS => '2147483647', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', COMPRESSION => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', BLOCKCACHE => 'true', BLOCKSIZE => '65536', REPLICATION_SCOPE => '0'}
```

***EMR - After resizing -> 1 (which took a couple of minutes):***

(All regions on the same server `p-172-31-38-77.eu-north-1.compute.internal`)

```console
hbase:019:0> scan 'hbase:meta', {COLUMNS => ['info:server', 'info:regioninfo']}
ROW                                         COLUMN+CELL
 :
 wiki,,1709577651152.c68cfc4dcf17ed4148cf7e column=info:regioninfo, timestamp=2024-03-04T18:59:37.294, value={ENCODED => c68cfc4dcf17ed4148cf7e07a25155d9, NAME => 'wiki,,
 07a25155d9.                                1709577651152.c68cfc4dcf17ed4148cf7e07a25155d9.', STARTKEY => '', ENDKEY => 'Chlorofm'}
 wiki,,1709577651152.c68cfc4dcf17ed4148cf7e column=info:server, timestamp=2024-03-04T18:59:37.294, value=ip-172-31-38-77.eu-north-1.compute.internal:16020
 07a25155d9.
 wiki,Chlorofm,1709577651152.6542ccf4b64787 column=info:regioninfo, timestamp=2024-03-04T18:59:37.275, value={ENCODED => 6542ccf4b64787f26257954e5a4ca1ff, NAME => 'wiki,C
 f26257954e5a4ca1ff.                        hlorofm,1709577651152.6542ccf4b64787f26257954e5a4ca1ff.', STARTKEY => 'Chlorofm', ENDKEY => 'Church!'}
 wiki,Chlorofm,1709577651152.6542ccf4b64787 column=info:server, timestamp=2024-03-04T18:59:37.275, value=ip-172-31-38-77.eu-north-1.compute.internal:16020
 f26257954e5a4ca1ff.
 wiki,Church!,1709577656807.fe67ff8223705a9 column=info:regioninfo, timestamp=2024-03-04T18:41:00.345, value={ENCODED => fe67ff8223705a9bf9e56bb8b44c9f0b, NAME => 'wiki,C
 bf9e56bb8b44c9f0b.                         hurch!,1709577656807.fe67ff8223705a9bf9e56bb8b44c9f0b.', STARTKEY => 'Church!', ENDKEY => 'Molar n'}
 wiki,Church!,1709577656807.fe67ff8223705a9 column=info:server, timestamp=2024-03-04T18:41:00.345, value=ip-172-31-38-77.eu-north-1.compute.internal:16020
 bf9e56bb8b44c9f0b.
 wiki,Molar n,1709577656807.05a65ec5d25cc02 column=info:regioninfo, timestamp=2024-03-04T18:41:00.279, value={ENCODED => 05a65ec5d25cc0239a05a93d8c6466b5, NAME => 'wiki,M
 39a05a93d8c6466b5.                         olar n,1709577656807.05a65ec5d25cc0239a05a93d8c6466b5.', STARTKEY => 'Molar n', ENDKEY => ''}
 wiki,Molar n,1709577656807.05a65ec5d25cc02 column=info:server, timestamp=2024-03-04T18:41:00.279, value=ip-172-31-38-77.eu-north-1.compute.internal:16020
 39a05a93d8c6466b5.
```

***EMR - After resizing -> 2 (which took a couple of minutes):***

```console
hbase:022:0> scan 'hbase:meta', {COLUMNS => ['info:server', 'info:regioninfo']}
ROW                                         COLUMN+CELL
 hbase:namespace,,1709575248754.3d891c42220 column=info:regioninfo, timestamp=2024-03-04T19:05:54.854, value={ENCODED => 3d891c42220a4ad39daa3b3b8f641c83, NAME => 'hbase:
 a4ad39daa3b3b8f641c83.                     namespace,,1709575248754.3d891c42220a4ad39daa3b3b8f641c83.', STARTKEY => '', ENDKEY => ''}
 hbase:namespace,,1709575248754.3d891c42220 column=info:server, timestamp=2024-03-04T19:05:54.854, value=ip-172-31-40-111.eu-north-1.compute.internal:16020
 a4ad39daa3b3b8f641c83.
 wiki,,1709577651152.c68cfc4dcf17ed4148cf7e column=info:regioninfo, timestamp=2024-03-04T19:05:55.461, value={ENCODED => c68cfc4dcf17ed4148cf7e07a25155d9, NAME => 'wiki,,
 07a25155d9.                                1709577651152.c68cfc4dcf17ed4148cf7e07a25155d9.', STARTKEY => '', ENDKEY => 'Chlorofm'}
 wiki,,1709577651152.c68cfc4dcf17ed4148cf7e column=info:server, timestamp=2024-03-04T19:05:55.461, value=ip-172-31-40-111.eu-north-1.compute.internal:16020
 07a25155d9.
 wiki,Chlorofm,1709577651152.6542ccf4b64787 column=info:regioninfo, timestamp=2024-03-04T19:05:56.099, value={ENCODED => 6542ccf4b64787f26257954e5a4ca1ff, NAME => 'wiki,C
 f26257954e5a4ca1ff.                        hlorofm,1709577651152.6542ccf4b64787f26257954e5a4ca1ff.', STARTKEY => 'Chlorofm', ENDKEY => 'Church!'}
 wiki,Chlorofm,1709577651152.6542ccf4b64787 column=info:server, timestamp=2024-03-04T19:05:56.099, value=ip-172-31-40-111.eu-north-1.compute.internal:16020
 f26257954e5a4ca1ff.
 wiki,Church!,1709577656807.fe67ff8223705a9 column=info:regioninfo, timestamp=2024-03-04T18:41:00.345, value={ENCODED => fe67ff8223705a9bf9e56bb8b44c9f0b, NAME => 'wiki,C
 bf9e56bb8b44c9f0b.                         hurch!,1709577656807.fe67ff8223705a9bf9e56bb8b44c9f0b.', STARTKEY => 'Church!', ENDKEY => 'Molar n'}
 wiki,Church!,1709577656807.fe67ff8223705a9 column=info:server, timestamp=2024-03-04T18:41:00.345, value=ip-172-31-38-77.eu-north-1.compute.internal:16020
 bf9e56bb8b44c9f0b.
 wiki,Molar n,1709577656807.05a65ec5d25cc02 column=info:regioninfo, timestamp=2024-03-04T18:41:00.279, value={ENCODED => 05a65ec5d25cc0239a05a93d8c6466b5, NAME => 'wiki,M
 39a05a93d8c6466b5.                         olar n,1709577656807.05a65ec5d25cc0239a05a93d8c6466b5.', STARTKEY => 'Molar n', ENDKEY => ''}
 wiki,Molar n,1709577656807.05a65ec5d25cc02 column=info:server, timestamp=2024-03-04T18:41:00.279, value=ip-172-31-38-77.eu-north-1.compute.internal:16020
 39a05a93d8c6466b5.
```

