# https://hbase.apache.org/2.5/apidocs/org/apache/hadoop/hbase/client/ConnectionFactory.html#createConnection--
# https://hbase.apache.org/2.3/devapidocs/org/apache/hadoop/hbase/client/BufferedMutator.html
# https://hbase.apache.org/2.5/apidocs/org/apache/hadoop/hbase/client/Connection.html#getBufferedMutator-org.apache.hadoop.hbase.TableName-
# https://hbase.apache.org/2.5/apidocs/org/apache/hadoop/hbase/TableName.html#valueOf-byte:A-
# https://hbase.apache.org/2.5/apidocs/org/apache/hadoop/hbase/client/BufferedMutator.html#mutate-java.util.List-
# https://hbase.apache.org/2.5/apidocs/org/apache/hadoop/hbase/client/Put.html#addColumn-byte:A-byte:A-byte:A-


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
mutator = connection.getBufferedMutator(TableName.valueOf("foods"));
mutator.disableWriteBufferPeriodicFlush()

while reader.has_next
  type = reader.next
  
  if type == XMLStreamConstants::START_ELEMENT
    #puts "START_ELEMENT: #{reader.local_name}"
    
    case reader.local_name
    when 'Food_Display_Row'
      document = {}
    else
      buffer = []
    end

  elsif type == XMLStreamConstants::CHARACTERS
    #puts "CHARACTERS: #{reader.text}"
    buffer << reader.text unless buffer.nil?
  
  elsif type == XMLStreamConstants::END_ELEMENT
    #puts "END_ELEMENT: #{reader.local_name}"
    case reader.local_name
    when 'Food_Display_Row'
      # if document['Display_Name'] == "Kix cereal"
      #   puts "-> #{document}"
      #   puts "---"
      # end
      key = document['Display_Name'].to_java_bytes
      p = Put.new(key)
      document.each do | fact, value |
        if fact != 'Display_Name'
          #puts "#{fact} : #{value}"
          p.addColumn(*jbytes("facts", fact, value)).setDurability(Durability::SKIP_WAL)
        end
      end
      mutator.mutate(p)

      count += 1
      mutator.flush() if count <= 5 || count % 10 == 0
      if count <= 5 || count % 100 == 0
        puts "#{count} records inserted (#{document['Display_Name']} / #{document['Food_Code']})"
      end
    else
      document[reader.local_name] = buffer.join
    end    
  end
end

mutator.flush()
connection.close()
exit
