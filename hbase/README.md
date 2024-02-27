# HBase

## Notes from Day 1

* Multiple updates -> automatic history?
  * Had to specify `VERSIONS` explicitly during create (didn't get 3 as the default)
* Deleting qualifier columns -> mix of versions within the same column-family (!)
* Deprecated API!
  * Book uses release 1.2.1 (April 2016)
  * Second edition of the book is copyrighted 2018
  * Now (Feb 2024), the latest version is 2.5.7
  * HTable has been deprecated since HBase 1.0.0 (Feb 2014)
    (but still used in the book!)
* What's a "good" way of loading separate ruby script files into the shell
  * General strategy for scoping?
  * Strategy for exception handling
    (Sometimes thrown out of the entire hbase shell!) 

### Scratch pad

Single column _family_ `text`

```shell
create 'wiki', 'text'
```

> Convention (_our_) for this tale; single column within the `text` family, i.e.
> 
> * qualifier: ""
> * full name: "text:"

```shell
put 'wiki', 'Home', 'text:', 'Welcome to the wiki!'
get 'wiki', 'Home', 'text:'
scan 'wiki'
```

> My own experiments with versioning
>
> ```shell
> put 'wiki', 'ulf-lab', 'text:', 'Ulf lab 1'
> put 'wiki', 'ulf-lab', 'text:', 'Ulf lab 2'
> put 'wiki', 'ulf-lab', 'text:', 'Ulf lab 3'
> get 'wiki', 'ulf-lab', {COLUMN => 'text:', VERSIONS => 3}
> ```
>
> (not what I expected)
>
> ```shell
> create 'ulf', {NAME => 'text', VERSIONS => 3}
> put 'ulf', 'ulf-lab', 'text:', 'Ulf lab 1'
> put 'ulf', 'ulf-lab', 'text:', 'Ulf lab 2'
> put 'ulf', 'ulf-lab', 'text:', 'Ulf lab 3'
> get 'ulf', 'ulf-lab', {COLUMN => 'text:', VERSIONS => 3}
> ```
> 
> (better)

Alter schema:

```shell
disable 'wiki'
alter 'wiki', { NAME => 'text', VERSIONS => org.apache.hadoop.hbase.HConstants::ALL_VERSIONS }
alter 'wiki', { NAME => 'revision',VERSIONS => org.apache.hadoop.hbase.HConstants::ALL_VERSIONS }
enable 'wiki'
```

> ***Note: run this command from a regular shell - not `hbase shell`***
>
> ```shell
> hbase-bash "cat /workspace/lab/hbase/put_multiple_columns.rb | hbase shell -n"
> ```

***Deleting stuff...***

Given this:

```console
hbase:048:0> get 'wiki', 'About'
COLUMN                   CELL
 revision:author         timestamp=2024-02-24T13:31:53.450, value=second-editor
 revision:comment        timestamp=2024-02-24T13:31:53.450, value=the second edition
 text:                   timestamp=2024-02-24T13:31:53.450, value=Second version of the About page
 ```

Delete column

```shell
delete 'wiki', 'About', 'revision:comment'
```

Result (not what I expected!)

```console
hbase:050:0> get 'wiki', 'About'
COLUMN                   CELL
 revision:author         timestamp=2024-02-24T13:31:53.450, value=second-editor
 revision:comment        timestamp=2024-02-24T13:31:10.142, value=the first edition
 text:                   timestamp=2024-02-24T13:31:53.450, value=Second version of the About page
```

The `:comment` is from the first update (prev version) but `:author` (and `text:`) are for the second!

Delete row

```shell
deleteall 'wiki', 'About'
```

***`put_many` function***

Start the hbase shell with the `put_many` definition:

```shell
hbase-shell hbase-shell /workspace/lab/hbase/put_many.rb
```

Within the hbase shell:

```console
hbase:001:0> scan 'wiki'
ROW                              COLUMN+CELL
 Home                            column=revision:author, timestamp=2024-02-24T11:00:59.254, value=jimbo
 Home                            column=revision:comment, timestamp=2024-02-24T11:00:59.254, value=my first edit
 Home                            column=text:, timestamp=2024-02-24T11:00:59.254, value=Hello world
1 row(s)
Took 0.4302 seconds                                                                                                           
hbase:002:0> put_many 'wiki', 'My page', { "text:" => "My text" }
hbase:003:0> put_many 'wiki', 'My better page', { "text:" => "My text", "revision:author" => "ulf", "revision:comment" => "very nice" }
hbase:004:0> scan 'wiki'
ROW                              COLUMN+CELL
 Home                            column=revision:author, timestamp=2024-02-24T11:00:59.254, value=jimbo
 Home                            column=revision:comment, timestamp=2024-02-24T11:00:59.254, value=my first edit
 Home                            column=text:, timestamp=2024-02-24T11:00:59.254, value=Hello world
 My better page                  column=revision:author, timestamp=2024-02-24T14:09:38.298, value=ulf
 My better page                  column=revision:comment, timestamp=2024-02-24T14:09:38.298, value=very nice
 My better page                  column=text:, timestamp=2024-02-24T14:09:38.298, value=My text
 My page                         column=text:, timestamp=2024-02-24T14:08:46.504, value=My text
3 row(s)
```

## Notes from Day 2

* Bug in the book's code?
  * `ts` in `Put` must be in _ms_!

### Scratch pad

Install bzip2 inside the hbase container

```shell
hbase-bash 'apt update && apt install bzip2 -y' 
```

From `hbase shell`:

```shell
alter 'wiki', {NAME=>'text', COMPRESSION=>'GZ',BLOOMFILTER=>'ROW'}
``` 

From regular shell:

```shell
hbase-bash "curl -s https://dumps.wikimedia.org/enwiki/latest/enwiki-latest-pages-articles.xml.bz2 | bzcat | hbase shell /workspace/lab/hbase/import_from_wikipedia.rb"
```

My scripts stops at 20000 entries (pages):

```console
1 records inserted (AccessibleComputing with ts=1611414901000 / 2021-01-23T15:15:01Z)
2 records inserted (Anarchism with ts=1708183985000 / 2024-02-17T15:33:05Z)
:
20000 records inserted (Ten Key Values with ts=1492723550000 / 2017-04-20T21:25:50Z)
```

Via bash shell inside the container:

```console
root@3d7ff9acd747:~/tmp/hbase/data/default# du -h
219M    ./wiki/aa57f5496da5c20170d766cec5d69ee2/text
4.0K    ./wiki/aa57f5496da5c20170d766cec5d69ee2/recovered.edits
4.0K    ./wiki/aa57f5496da5c20170d766cec5d69ee2/.tmp/text
8.0K    ./wiki/aa57f5496da5c20170d766cec5d69ee2/.tmp
4.0K    ./wiki/aa57f5496da5c20170d766cec5d69ee2/revision
219M    ./wiki/aa57f5496da5c20170d766cec5d69ee2
8.0K    ./wiki/.tabledesc
219M    ./wiki
219M    .
```

Sub-dir `aa57f5496da5c20170d766cec5d69ee2` is our (single) region.

```console
root@3d7ff9acd747:~/tmp/hbase# du -h -d 1
767M    ./WALs
4.0K    ./corrupt
172K    ./MasterData
796K    ./archive
4.0K    ./.hbck
1.3M    ./oldWALs
8.0K    ./.tmp
219M    ./data
4.0K    ./staging
4.0K    ./mobdir
988M    .
```

Obviously a lot of WAL. Can be disabled for this kind of import job (which could be re-run in case of failure) -> Wipe everything and start over with `Durability::SKIP_WAL`...

Stop at 400000 entries (pages):

```console
1 records inserted (AccessibleComputing with ts=1611414901000 / 2021-01-23T15:15:01Z)
2 records inserted (Anarchism with ts=1708183985000 / 2024-02-17T15:33:05Z)
:
400000 records inserted (Interrogating with ts=1085091267000 / 2004-05-20T22:14:27Z)
```

```console
root@3d7ff9acd747:~/tmp/hbase# du -h -d 1 
84K     ./WALs
4.0K    ./corrupt
168K    ./MasterData
932K    ./archive
4.0K    ./.hbck
1.8M    ./oldWALs
8.0K    ./.tmp
2.0G    ./data
4.0K    ./staging
4.0K    ./mobdir
2.0G    .
```

No big WAL! But during the import the `archive/` directory held more than 5G (!?)

```console
root@3d7ff9acd747:~/tmp/hbase/data/default/wiki# du -h
348M    ./f969f3d2049e5e521e4fc8ac9b9ae0ef/text
4.0K    ./f969f3d2049e5e521e4fc8ac9b9ae0ef/recovered.edits
4.0K    ./f969f3d2049e5e521e4fc8ac9b9ae0ef/.tmp/text
4.0K    ./f969f3d2049e5e521e4fc8ac9b9ae0ef/.tmp/revision
12K     ./f969f3d2049e5e521e4fc8ac9b9ae0ef/.tmp
1.1M    ./f969f3d2049e5e521e4fc8ac9b9ae0ef/revision
349M    ./f969f3d2049e5e521e4fc8ac9b9ae0ef
8.0K    ./.tabledesc
1.6G    ./7b78036b830dc1812685e1a6367b66de/text
4.0K    ./7b78036b830dc1812685e1a6367b66de/recovered.edits
4.0K    ./7b78036b830dc1812685e1a6367b66de/.tmp/text
4.0K    ./7b78036b830dc1812685e1a6367b66de/.tmp/revision
12K     ./7b78036b830dc1812685e1a6367b66de/.tmp
40M     ./7b78036b830dc1812685e1a6367b66de/revision
1.6G    ./7b78036b830dc1812685e1a6367b66de
2.0G    .
```

Two regions. Initially only one (with different name). Split somewhere around 25000 pages.

Back to hbase shell

```shell
scan 'hbase:meta', {COLUMNS => ['info:server', 'info:regioninfo']}

describe 'wiki'
describe 'hbase:meta'
```

Cross references

```shell
create 'links', {NAME => 'to', VERSIONS => 1, BLOOMFILTER => 'ROWCOL'}, {NAME => 'from', VERSIONS => 1, BLOOMFILTER => 'ROWCOL' }
```



Summary of all create/configure commands; restart with fresh wiki (very useful during debugging)

```shell
disable 'wiki'
drop 'wiki'
create 'wiki', 'text'
put 'wiki', 'Home', 'text:', 'Welcome to the wiki!'
disable 'wiki'
alter 'wiki', { NAME => 'text', VERSIONS => org.apache.hadoop.hbase.HConstants::ALL_VERSIONS }
alter 'wiki', { NAME => 'revision',VERSIONS => org.apache.hadoop.hbase.HConstants::ALL_VERSIONS }
enable 'wiki'
alter 'wiki', {NAME=>'text', COMPRESSION=>'GZ',BLOOMFILTER=>'ROW'}
disable 'links'
drop 'links'
create 'links', {NAME => 'to', VERSIONS => 1, BLOOMFILTER => 'ROWCOL'}, {NAME => 'from', VERSIONS => 1, BLOOMFILTER => 'ROWCOL' }
```