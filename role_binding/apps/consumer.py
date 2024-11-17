from confluent_kafka import Producer, Consumer


def say_hello(producer, key):
    value = f'Hello {key}!'
    producer.produce('hello_topic', value, key)

def read_config():
  # reads the client configuration from client.properties
  # and returns it as a key-value map
  config = {}
  with open("client.properties") as fh:
    for line in fh:
      line = line.strip()
      if len(line) != 0 and line[0] != "#":
        parameter, value = line.strip().split('=', 1)
        config[parameter] = value.strip()
  return config

def produce(topic, config):
  # creates a new producer instance
  producer = Producer(config)

  # produces a sample message
  key = "key"
  value = "value"
  producer.produce(topic, key=key, value=value)
  producer.flush() 
  print(f"Produced message to topic {topic}: key = {key} value = {value}")
  # send any outstanding or buffered messages to the Kafka broker
 

def consume(topic, config):
  # sets the consumer group ID and offset  
  config["group.id"] = "python-group-2"
  config["auto.offset.reset"] = "earliest"

  # creates a new consumer instance
  consumer = Consumer(config)

  # subscribes to the specified topic
  consumer.subscribe([topic])

  try:
    while True:
      # consumer polls the topic and prints any incoming messages
      msg = consumer.poll(1.0)
      if msg is not None and msg.error() is None:
        key = msg.key().decode("utf-8")
        value = msg.value().decode("utf-8")
        print(f"Consumed message from topic {topic}: key = {key} value = {value}")
  except KeyboardInterrupt:
    pass
  finally:
    # closes the consumer connection
    consumer.close()

def main():
  config = read_config()
  topic = "automated_topic_v3"
  produce(topic, config)
  consume(topic, config)


main()