# HTable is deprecated (>9 years ago !?) and Table doesn't have flush-control
# Also, a lot has changed wrt Put as well
# -> Use BufferedMutator instead
#    (very different compared to the book)
#
# https://hbase.apache.org/2.5/apidocs/org/apache/hadoop/hbase/client/ConnectionFactory.html#createConnection--
# https://hbase.apache.org/2.3/devapidocs/org/apache/hadoop/hbase/client/BufferedMutator.html
# https://hbase.apache.org/2.5/apidocs/org/apache/hadoop/hbase/client/Connection.html#getBufferedMutator-org.apache.hadoop.hbase.TableName-
# https://hbase.apache.org/2.5/apidocs/org/apache/hadoop/hbase/TableName.html#valueOf-byte:A-
# https://hbase.apache.org/2.5/apidocs/org/apache/hadoop/hbase/client/BufferedMutator.html#mutate-java.util.List-
# https://hbase.apache.org/2.5/apidocs/org/apache/hadoop/hbase/client/Put.html#addColumn-byte:A-byte:A-byte:A-
# https://hbase.apache.org/2.5/apidocs/org/apache/hadoop/hbase/client/ResultScanner.html
# https://hbase.apache.org/2.5/apidocs/org/apache/hadoop/hbase/client/Result.html

import 'org.apache.hadoop.hbase.client.ConnectionFactory'
import 'org.apache.hadoop.hbase.client.Put'
import 'org.apache.hadoop.hbase.client.Scan'
import 'org.apache.hadoop.hbase.client.Durability'
import 'org.apache.hadoop.hbase.util.Bytes'

def jbytes(*args)
  args.map {|arg| arg.to_s.to_java_bytes}
end

connection = ConnectionFactory.createConnection()
wiki_table = connection.getTable(TableName.valueOf("wiki"));
links_mutator = connection.getBufferedMutator(TableName.valueOf("links"));
links_mutator.disableWriteBufferPeriodicFlush()

scanner = wiki_table.getScanner(Scan.new)

linkpattern = /\[\[([^\[\]\|\:\#][^\[\]\|:]*)(?:\|([^\[\]\|]+))?\]\]/
count = 0

while (result = scanner.next())
  title = Bytes.toString(result.getRow())
  text = Bytes.toString(result.getValue(*jbytes('text', '')))
  #puts "found title=#{title}, |text|=#{text.length}"
  if text
    put_to = nil
    text.scan(linkpattern) do |target, label|
      #puts "-> target=#{target}, label=#{label}"
      unless put_to
        put_to = Put.new(*jbytes(title))
      end

      target.strip!
      #target.capitalize! # why? it just makes from/to miss eachother?
      
      # My own guard based on debugging (got target: " " -> {strip} -> "")
      if target.length > 0

        label = '' unless label
        label.strip!

        put_to.addColumn(*jbytes("to", target, label)).setDurability(Durability::SKIP_WAL)

        put_from = Put.new(*jbytes(target))
        put_from.addColumn(*jbytes("from", title, label)).setDurability(Durability::SKIP_WAL)
        links_mutator.mutate(put_from)
      end
    end
    links_mutator.mutate(put_to) if put_to
    links_mutator.flush()
  end

  count += 1
  puts "#{count} pages processed (#{title})" if count <=20 || count % 500 == 0
end

links_mutator.flush()
connection.close()
exit

