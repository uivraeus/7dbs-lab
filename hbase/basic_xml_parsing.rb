import 'javax.xml.stream.XMLStreamConstants'

factory = javax.xml.stream.XMLInputFactory.newInstance
reader = factory.createXMLStreamReader(java.lang.System.in)

while reader.has_next
  type = reader.next
  
  if type == XMLStreamConstants::START_ELEMENT
    tag = reader.local_name
    puts "START_ELEMENT:"
    puts tag
  elsif type == XMLStreamConstants::CHARACTERS
    text = reader.text
    puts "CHARACTERS:"
    puts text
  elsif type == XMLStreamConstants::END_ELEMENT
    puts "END_ELEMENT:"
    puts tag
  end
end

exit
