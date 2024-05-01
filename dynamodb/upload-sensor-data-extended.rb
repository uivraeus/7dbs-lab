require 'aws-sdk'
require 'random-walk'
require 'time'

STREAM_NAME = 'temperature-sensor-data'

# Make sure that both a sensor ID and number of iterations are entered
if ARGV.length != 2
  abort("Must specify a sensor ID as the first arg and N as the second")
end

@sensor_id = ARGV[0]
@iterator_limit = ARGV[1].to_i

# The Kinesis client object. Supply a different region if necessary
@kinesis_client = Aws::Kinesis::Client.new(region: 'eu-north-1')

# Arrays used to generate random walk values
@temp_walk_array = RandomWalk.generate(6000..10000, @iterator_limit, 1)
@humidity_walk_array = RandomWalk.generate(2000..10000, @iterator_limit, 1)

# The iterator starts at 0
@iterator = 0

def write_temp_reading_to_kinesis
  # Generate a random current temperature/humidity from the walk arrays
  current_temp = @temp_walk_array[@iterator] / 100.0
  current_humidity = @humidity_walk_array[@iterator] / 100.0

  # The JSON payload for the reading
  data = {
    :sensor_id    => @sensor_id,
    :current_time => Time.now.to_i,
    :temperature  => current_temp,
    :humidity     => current_humidity
  }

  # The record to write to Kinesis
  kinesis_record = {
    :stream_name   => STREAM_NAME,
    :data          => data.to_json,
    # We'll use just a single partition key here
    :partition_key => 'sensor-data',
  }

  # Write the record to Kinesis
  @kinesis_client.put_record(kinesis_record)

  puts "Sensor #{@sensor_id} sent a temperature=#{current_temp} and humidity=#{current_humidity}"

  @iterator += 1

  # Exit if script has iterated N times
  if @iterator == @iterator_limit
    puts "The sensor has gone offline"
    exit(0)
  end
end

while true
  write_temp_reading_to_kinesis
  # Pause 2 seconds before supplying another reading
  sleep 2
end
