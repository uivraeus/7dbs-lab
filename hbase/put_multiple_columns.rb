# HTable is deprecated (>9 years ago !?) -> Use Table instead
# A lot has changed wrt Put as well
# -> very different compared to the book
#
# https://hbase.apache.org/2.5/apidocs/org/apache/hadoop/hbase/client/ConnectionFactory.html#createConnection--
# https://hbase.apache.org/2.5/apidocs/org/apache/hadoop/hbase/client/Connection.html#getTable-org.apache.hadoop.hbase.TableName-
# https://hbase.apache.org/2.5/apidocs/org/apache/hadoop/hbase/TableName.html#valueOf-byte:A-
# https://hbase.apache.org/2.5/apidocs/org/apache/hadoop/hbase/client/Put.html#addColumn-byte:A-byte:A-byte:A-


import 'org.apache.hadoop.hbase.client.ConnectionFactory'
import 'org.apache.hadoop.hbase.client.Put'

def jbytes(*args)
  args.map {|arg| arg.to_s.to_java_bytes}
end

connection = ConnectionFactory.createConnection()
table = connection.getTable(TableName.valueOf("wiki"));

p = Put.new(*jbytes("Home"))

p.addColumn(*jbytes("text", "", "Hello world"))
p.addColumn(*jbytes("revision", "author", "jimbo"))
p.addColumn(*jbytes("revision", "comment", "my first edit"))

table.put(p)

connection.close()
