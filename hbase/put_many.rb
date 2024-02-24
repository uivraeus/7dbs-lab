import 'org.apache.hadoop.hbase.client.ConnectionFactory'
import 'org.apache.hadoop.hbase.client.Put'

def jbytes(*args)
  args.map {|arg| arg.to_s.to_java_bytes}
end

def put_many(table_name, row, column_values)
  connection = ConnectionFactory.createConnection()
  table = connection.getTable(TableName.valueOf(table_name));
  
  p = Put.new(*jbytes(row))
  
  column_values.each do |column_fullname, value|
    family = column_fullname.split(/:/, 2)[0]
    qualifier = column_fullname.split(/:/, 2)[1]
    p.addColumn(*jbytes(family, qualifier, value))
  end

  table.put(p)
  
  connection.close()  
end

