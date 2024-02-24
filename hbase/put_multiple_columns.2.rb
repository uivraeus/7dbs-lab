import 'org.apache.hadoop.hbase.client.ConnectionFactory'
import 'org.apache.hadoop.hbase.client.Put'

def jbytes(*args)
  args.map {|arg| arg.to_s.to_java_bytes}
end

connection = ConnectionFactory.createConnection()
table = connection.getTable(TableName.valueOf("wiki"));

p = Put.new(*jbytes("About"))

p.addColumn(*jbytes("text", "", "Second version of the About page"))
p.addColumn(*jbytes("revision", "author", "second-editor"))
p.addColumn(*jbytes("revision", "comment", "the second edition"))

table.put(p)

connection.close()
