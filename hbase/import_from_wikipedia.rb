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

require 'time'

import 'javax.xml.stream.XMLStreamConstants'
import 'org.apache.hadoop.hbase.client.ConnectionFactory'
import 'org.apache.hadoop.hbase.client.Put'
import 'org.apache.hadoop.hbase.client.Durability'

def jbytes(*args)
  args.map {|arg| arg.to_s.to_java_bytes}
end

factory = javax.xml.stream.XMLInputFactory.newInstance
reader = factory.createXMLStreamReader(java.lang.System.in)

document = nil
buffer = nil
count = 0

connection = ConnectionFactory.createConnection()
mutator = connection.getBufferedMutator(TableName.valueOf("wiki"));
mutator.disableWriteBufferPeriodicFlush()

# I've added a max/cap here (not in the book)
while reader.has_next && count < 400000
  type = reader.next
  
  if type == XMLStreamConstants::START_ELEMENT
    case reader.local_name
    when 'page' then document = {}
    when /title|timestamp|username|comment|text/ then buffer = []
    end

  elsif type == XMLStreamConstants::CHARACTERS
    buffer << reader.text unless buffer.nil?
  
  elsif type == XMLStreamConstants::END_ELEMENT
    case reader.local_name
    when /title|timestamp|username|comment|text/
      document[reader.local_name] = buffer.join
    when 'revision'
      key = document['title'].to_java_bytes
      # Milliseconds! (not in the book !?)
      ts = 1000 * (Time.parse document['timestamp']).to_i
      
      # My own addition of WAL-skipping (save a lot of space in my volume)
      p = Put.new(key, ts)
      p.addColumn(*jbytes("text", "", document['text'])).setDurability(Durability::SKIP_WAL)
      p.addColumn(*jbytes("revision", "author", document['username'])).setDurability(Durability::SKIP_WAL)
      p.addColumn(*jbytes("revision", "comment", document['comment'])).setDurability(Durability::SKIP_WAL)
      mutator.mutate(p)

      count += 1

      # Slightly adjusted print/flush-logic comapared to the book (easer debug)
      mutator.flush() if count <= 20 || count % 10 == 0
      if count <= 20 || count % 500 == 0
        puts "#{count} records inserted (#{document['title']} with ts=#{ts} / #{document['timestamp']})"
      end

    end
  end
end

mutator.flush()
connection.close()
exit
