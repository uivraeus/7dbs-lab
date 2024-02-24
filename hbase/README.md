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
