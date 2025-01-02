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
  for x in range(6):
    key = "key"
    value = get_large_value()
    producer.produce(topic, key=key, value=value)
    producer.flush() 
    print(f"Produced message to topic {topic}: key = {key} value = {value}, iteration {x}")

def get_large_value():
  size_in_bytes = 1 * 1024 * 1024  # 1.5 MB in bytes
  character = "A"  # Using 'A' as the repeated character
  large_string = character * int(size_in_bytes)
  return large_string

def main():
  config = read_config()
  topic = "quotas_demo_topic_v1"
  produce(topic, config)


main()