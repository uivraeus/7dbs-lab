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
  * other issues marked with comments in my rb-files
* Compression options?
  * Now also "Snappy"
  * Brief comparison in this [article](https://www.linkedin.com/pulse/importance-compression-hbase-performance-tuning-part-deshpande)
    * GZ slower but better compression -> use for cold data
  * (I only tested with GZ)
  * This [documentation](https://devdoc.net/bigdata/hbase-0.98.7-hadoop1/book/regions.arch.html#Compaction) explains "StoreFiles" and compaction aspects.
* Bloom filters
  * Tuning considerations explained in this [article](https://www.linkedin.com/pulse/bloom-filters-hbase-kuldeep-deshpande)
    * Few records updated at a time or in batches -> BF helps read-perf (rows in separate StoreFiles)
    * Total storage volume increase a lot when BF are maintained
  * Why `ROW` for `wiki` but `ROWCOL` for links?
    * This [documentation](https://devdoc.net/bigdata/hbase-0.98.7-hadoop1/book/perf.schema.html#bloom.filters.when) explains the trade-off
    * "large number of column-level Puts" -> `ROWCOL` (same row many/every StoreFile) - This is definitely the case for `links`!
* Best practice for working with numerical values?
* [shell docs](https://hbase.apache.org/book.html#shell)
  * which also includes descriptions of the [conceptual](https://hbase.apache.org/book.html#conceptual.view) and [physical](https://hbase.apache.org/book.html#physical.view) data model.
* The [Learning HBase](https://subscription.packtpub.com/book/data/9781783985944/pref06) book helps understanding the relation between HBase and other parts of the Hadoop ecosystem. (Maybe a bit outdated?), e.g.
  * [HBase layout on top of Hadoop](https://subscription.packtpub.com/book/data/9781783985944/1/ch01lvl1sec08/hbase-layout-on-top-of-hadoop)
  * [HBase in the Hadoop ecosystem](https://subscription.packtpub.com/book/data/9781783985944/1/ch01lvl1sec11/hbase-in-the-hadoop-ecosystem)
  * [Getting started with HBase](https://subscription.packtpub.com/book/data/9781783985944/1/ch01lvl1sec14/getting-started-with-hbase), describes the roles of all components.
* [Regions documentation](https://hbase.apache.org/book.html#regions.arch) explains the details around storage.

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

Running script to detect and store all from/to links

```shell
hbase-bash "cat /workspace/lab/hbase/generate_wiki_links.rb | hbase shell -n"
```

```console
1 pages processed (! (disambiguation))
2 pages processed (!!!)

200000 pages processed (List of Nintendo Entertainment System games)
200500 pages processed (List of Test cricket records)
Unhandled Java exception: java.lang.IllegalArgumentException: Row length is 0
java.lang.IllegalArgumentException: Row length is 0
                  checkRow at org/apache/hadoop/hbase/client/Mutation.java:702
                    <init> at org/apache/hadoop/hbase/client/Put.java:94
                    <init> at org/apache/hadoop/hbase/client/Put.java:59
                    <init> at org/apache/hadoop/hbase/client/Put.java:50
               newInstance at java/lang/reflect/Constructor.java:423
         newInstanceDirect at org/jruby/javasupport/JavaConstructor.java:253
               newInstance at org/jruby/RubyClass.java:939
 :
 :
```

Some debugging -> `target`=`" "` got stripped to `""` ... maybe the regex pattern is wrong? Don't care, just add guard for this and rerun.

> ***Side note***
>
> During imports the `archive` directory gets quite big. Even when the script has ended its size is quite large:
>
> ```console
> root@3d7ff9acd747:~/tmp/hbase# du -h -d 1
> 40K     ./WALs
> 4.0K    ./corrupt
> 144K    ./MasterData
> 4.9G    ./archive
> 4.0K    ./.hbck
> 1.9M    ./oldWALs
> 8.0K    ./.tmp
> 4.8G    ./data
> 4.0K    ./staging
> 4.0K    ./mobdir
> 9.6G    .
> ```
>
> After a while, the `archive` directory has been (partly) emptied:
>
> ```console
> root@3d7ff9acd747:~/tmp/hbase# du -h -d 1
> 40K     ./WALs
> 4.0K    ./corrupt
> 144K    ./MasterData
> 792M    ./archive
> 4.0K    ./.hbck
> 1.9M    ./oldWALs
> 8.0K    ./.tmp
> 4.8G    ./data
> 4.0K    ./staging
> 4.0K    ./mobdir
> 5.6G    .
> ```

Examine result of links-creation

```shell
scan 'links', STARTROW => 'A Plea for Captain John Brown', ENDROW => 'A Scandal in Bohemia'
```

```console
 :
A Saucerful of Secrets                             column=to:vibraphone, timestamp=...
A Saucerful of Secrets                             column=to:xylophone, timestamp=...
A Saucerful of Secrets (instrumental)              column=from:A Saucerful of Secrets, timestamp=...
A Saucerful of Secrets (instrumental)              column=from:Concertgebouw, Amsterdam, timestamp=...
A Saucerful of Secrets (instrumental)              column=from:Ummagumma, timestamp=...
A Saucerful of Secrets (instrumental)              column=to:A Momentary Lapse of Reason Tour, timestamp=...
A Saucerful of Secrets (instrumental)              column=to:A Saucerful of Secrets, timestamp=...
A Saucerful of Secrets (instrumental)              column=to:ABC-CLIO, timestamp=...
A Saucerful of Secrets (instrumental)              column=to:Abbey Road Studios, timestamp=...
 :
```

```shell
get 'links', 'A Saucerful of Secrets'
```

```shell
count 'links', INTERVAL => 100000, CACHE => 10000
```

```console
 :
Current count: 4600000, row: international standards
Current count: 4700000, row: public penance
Current count: 4800000, row: white-supremacists
4822925 row(s)
Took 28.2686 seconds
=> 4822925
```

```shell
count 'links', INTERVAL => 100000, CACHE => 50000
```

```console
 :
Took 26.4212 seconds
=> 4822925
```

(A _lot_ slower with CACHE => 10)

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

### Homework

Downloaded Food_Display_Table.xml from "https://data.world/fns/mypyramid-food-raw-data" (after registering an account)

Create table `foods` with Display Name as the row key (and single column family `facts`).

* Use BF with `ROWCOL`
  * Probably wrong decision... better w/o BF? Many column-level Puts but all rows have all columns (not sparse)
    * Need to understand the _StoreFile_ concept better!
  * According to [some docs](https://devdoc.net/bigdata/hbase-0.98.7-hadoop1/book/perf.schema.html#bloom.filters.when) _"Bloom filters work best when the size of each data entry is at least a few kilobytes in size"_ - which is not the case here
* Compression? Each facts is very short/compact... worth it?
  * Trying without
* Versions?
  * Use 1, not expecting the need for a history

```shell
create 'foods', {NAME => 'facts', VERSIONS => 1, BLOOMFILTER => 'ROWCOL'}
```

```shell
hbase-bash 'cat /workspace/lab/hbase/Food_Display_Table.xml | hbase shell /workspace/lab/hbase/import_food_data.rb'
```

> After debug iterations: Reset table
>
> ```shell
> truncate 'foods'
> ```

The dataset is a bit ambiguous as there are multiple entries with same Display_Name and Food_Code, but with different values for the same "fact keys", e.g. "Kix cereal". Maybe `Portion_Display_Name` should have been part of the row key as well. Right now only the last update of similar rows remains.

```console
-> {"Food_Code"=>"57303100", "Display_Name"=>"Kix cereal", "Portion_Default"=>"1.00000", "Portion_Amount"=>"1.00000", "Portion_Display_Name"=>"cup", "Factor"=>"1.00000", "Increment"=>".25000", "Multiplier"=>".25000", "Grains"=>".67804", "Whole_Grains"=>".23782", "Vegetables"=>".00000", "Orange_Vegetables"=>".00000", "Drkgreen_Vegetables"=>".00000", "Starchy_vegetables"=>".00000", "Other_Vegetables"=>".00000", "Fruits"=>".00000", "Milk"=>".00000", "Meats"=>".00000", "Soy"=>".00000", "Drybeans_Peas"=>".00000", "Oils"=>".00000", "Solid_Fats"=>".00000", "Added_Sugars"=>"8.93255", "Alcohol"=>".00000", "Calories"=>"82.94000", "Saturated_Fats"=>".11000"}
---
-> {"Food_Code"=>"57303100", "Display_Name"=>"Kix cereal", "Portion_Default"=>"2.00000", "Portion_Amount"=>"1.00000", "Portion_Display_Name"=>"single serving box", "Factor"=>"1.00000", "Increment"=>".50000", "Multiplier"=>".50000", "Grains"=>".55476", "Whole_Grains"=>".19458", "Vegetables"=>".00000", "Orange_Vegetables"=>".00000", "Drkgreen_Vegetables"=>".00000", "Starchy_vegetables"=>".00000", "Other_Vegetables"=>".00000", "Fruits"=>".00000", "Milk"=>".00000", "Meats"=>".00000", "Soy"=>".00000", "Drybeans_Peas"=>".00000", "Oils"=>".00000", "Solid_Fats"=>".00000", "Added_Sugars"=>"7.30845", "Alcohol"=>".00000", "Calories"=>"67.86000", "Saturated_Fats"=>".09000"}
---
```

```console
hbase:004:0> get 'foods', 'Kix cereal'
COLUMN                    CELL
 facts:Added_Sugars       timestamp=2024-03-01T05:38:20.176, value=7.30845
 facts:Alcohol            timestamp=2024-03-01T05:38:20.176, value=.00000
 facts:Calories           timestamp=2024-03-01T05:38:20.176, value=67.86000
 facts:Drkgreen_Vegetable timestamp=2024-03-01T05:38:20.176, value=.00000
 s
 facts:Drybeans_Peas      timestamp=2024-03-01T05:38:20.176, value=.00000
 facts:Factor             timestamp=2024-03-01T05:38:20.176, value=1.00000
 facts:Food_Code          timestamp=2024-03-01T05:38:20.176, value=57303100
 facts:Fruits             timestamp=2024-03-01T05:38:20.176, value=.00000
 facts:Grains             timestamp=2024-03-01T05:38:20.176, value=.55476
 facts:Increment          timestamp=2024-03-01T05:38:20.176, value=.50000
 facts:Meats              timestamp=2024-03-01T05:38:20.176, value=.00000
 facts:Milk               timestamp=2024-03-01T05:38:20.176, value=.00000
 facts:Multiplier         timestamp=2024-03-01T05:38:20.176, value=.50000
 facts:Oils               timestamp=2024-03-01T05:38:20.176, value=.00000
 facts:Orange_Vegetables  timestamp=2024-03-01T05:38:20.176, value=.00000
 facts:Other_Vegetables   timestamp=2024-03-01T05:38:20.176, value=.00000
 facts:Portion_Amount     timestamp=2024-03-01T05:38:20.176, value=1.00000
 facts:Portion_Default    timestamp=2024-03-01T05:38:20.176, value=2.00000
 facts:Portion_Display_Na timestamp=2024-03-01T05:38:20.176, value=single serving box
 me
 facts:Saturated_Fats     timestamp=2024-03-01T05:38:20.176, value=.09000
 facts:Solid_Fats         timestamp=2024-03-01T05:38:20.176, value=.00000
 facts:Soy                timestamp=2024-03-01T05:38:20.176, value=.00000
 facts:Starchy_vegetables timestamp=2024-03-01T05:38:20.176, value=.00000
 facts:Vegetables         timestamp=2024-03-01T05:38:20.176, value=.00000
 facts:Whole_Grains       timestamp=2024-03-01T05:38:20.176, value=.19458
1 row(s)
```

Queries / specific column / intervals


```shell
get 'foods', 'Kix cereal', { COLUMN => 'facts:Saturated_Fats' }
get 'foods', 'Kix cereal', COLUMN => 'facts:Saturated_Fats'

scan 'foods', { COLUMN => 'facts:Saturated_Fats' }
scan 'foods', COLUMN => 'facts:Saturated_Fats'

scan 'foods', { COLUMN => 'facts:Saturated_Fats', STARTROW => 'W', ENDROW => 'X' }
scan 'foods', COLUMN => 'facts:Saturated_Fats', STARTROW => 'W', ENDROW => 'X'

scan 'foods', {FILTER => "RowFilter(=, 'regexstring:cereal')", COLUMN => 'facts:Saturated_Fats'}
scan 'foods', {FILTER => "RowFilter = (=, 'substring:cereal')", COLUMN => 'facts:Saturated_Fats'}

scan 'foods', {FILTER => "RowFilter = (!=, 'substring:cereal')", COLUMN => 'facts:Saturated_Fats'}


import org.apache.hadoop.hbase.filter.CompareFilter
import org.apache.hadoop.hbase.filter.SingleColumnValueFilter
import org.apache.hadoop.hbase.util.Bytes
scan 'foods', {FILTER => SingleColumnValueFilter.new(Bytes.toBytes('facts'), Bytes.toBytes('Saturated_Fats'), CompareFilter::CompareOp.valueOf('EQUAL'), Bytes.toBytes('.00000')), COLUMN => 'facts:Saturated_Fats' }

scan 'foods', { FILTER => "SingleColumnValueFilter = ('facts','Saturated_Fats',=,'binary:.00000')", COLUMN => 'facts:Saturated_Fats' }
scan 'foods', FILTER => "SingleColumnValueFilter = ('facts','Saturated_Fats',=,'binary:.00000')", COLUMN => 'facts:Saturated_Fats'

scan 'foods', FILTER => "RowFilter = (=, 'substring:Fruit') AND SingleColumnValueFilter = ('facts','Saturated_Fats',=,'binary:.00000')", COLUMNS => ['facts:Fruits','facts:Saturated_Fats']

scan 'foods', FILTER => "SingleColumnValueFilter = ('facts','Fruits',>,'binary:.50000')", COLUMN => 'facts:Fruits'
scan 'foods', FILTER => "SingleColumnValueFilter = ('facts','Fruits',<,'binary:.50000')", COLUMN => 'facts:Fruits'

count 'foods', FILTER => "SingleColumnValueFilter = ('facts','Fruits',>,'binary:.50000')", COLUMN => 'facts:Fruits'
count 'foods', FILTER => "SingleColumnValueFilter = ('facts','Fruits',<=,'binary:.50000')", COLUMN => 'facts:Fruits'
count 'foods'

```

! `>`, `<=` and `<` above worked... why/how?

Tricky! - this is not how you do it...
(attempt to output just Fruits-column but filter on another - won't work -> SingleColumnValueFilter has no effect)

```shell
scan 'foods', FILTER => "RowFilter = (=, 'substring:Fruit') AND SingleColumnValueFilter = ('facts','Saturated_Fats',=,'binary:.00000')", COLUMNS => ['facts:Fruits']
```


### Extra experiments

```shell
create 'ulf', {NAME => 'cf-a', VERSIONS => 3}, {NAME => 'cf-b', VERSIONS => 2}
put 'ulf', 'row-x', 'cf-a:', 'update-row-x--cf-a-1'
put 'ulf', 'row-x', 'cf-a:q-a', 'update-row-x--cf-a-q-a-1'
put 'ulf', 'row-x', 'cf-a:q-b', 'update-row-x--cf-a-q-b-1'
put 'ulf', 'row-x', 'cf-a:q-a', 'update-row-x--cf-a-q-a-2'
put 'ulf', 'row-x', 'cf-a:', 'update-row-x--cf-a-2'

put 'ulf', 'row-y', 'cf-a:q-a', 'update-row-y--cf-a-q-a-1'

put 'ulf', 'row-z', 'cf-a:q-b', 'update-row-z--cf-a-q-b-1'
```

```console
hbase:025:0> scan 'ulf', COLUMN=>'cf-a:q-b'
ROW          COLUMN+CELL
 row-x       column=cf-a:q-b, timestamp=2024-03-02T05:48:03.168, value=update-row-x--cf-a-q-b-1
 row-z       column=cf-a:q-b, timestamp=2024-03-02T05:48:03.341, value=update-row-z--cf-a-q-b-1
2 row(s)

hbase:026:0> scan 'ulf', COLUMN=>'cf-a:q-a'
ROW          COLUMN+CELL
 row-x       column=cf-a:q-a, timestamp=2024-03-02T05:48:03.206, value=update-row-x--cf-a-q-a-2
 row-y       column=cf-a:q-a, timestamp=2024-03-02T05:48:03.291, value=update-row-y--cf-a-q-a-1
2 row(s)

hbase:027:0> scan 'ulf', COLUMN=>'cf-a:q-a', VERSIONS=>2
ROW          COLUMN+CELL
 row-x       column=cf-a:q-a, timestamp=2024-03-02T05:48:03.206, value=update-row-x--cf-a-q-a-2
 row-x       column=cf-a:q-a, timestamp=2024-03-02T05:48:03.135, value=update-row-x--cf-a-q-a-1
 row-y       column=cf-a:q-a, timestamp=2024-03-02T05:48:03.291, value=update-row-y--cf-a-q-a-1
2 row(s)
```
