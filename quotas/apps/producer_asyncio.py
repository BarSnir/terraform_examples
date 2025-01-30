import asyncio
from concurrent.futures import ThreadPoolExecutor
from confluent_kafka import Producer
from datetime import datetime
import string, random, json

NUM_OF_RECORDS = 10000
RECORD_WEIGHT_MEGABYTES = 3
TOPIC = "quotas_demo_topic_v3"
producer = ''

# Function to produce messages (runs synchronously)
def produce_message(key, value):
    def delivery_report(err, msg):
        print(f"{get_timestamp()}")
        if err is not None:  
            print(f"Delivery failed for record {key}: {err}")
        else:
            print(f"Record {key} successfully produced to {msg.topic()} [{msg.partition()}]")

    # Asynchronous delivery callback is handled by librdkafka
    producer.produce(TOPIC, key=key, value=value, callback=delivery_report)
    producer.poll()

def produce(messages, key, value):

    NUMBER_OF_MESSAGE_FOR_BATCH = 100

    def delivery_report(err, msg):
        print(f"{get_timestamp()}")
        if err is not None:  
            print(f"Delivery failed for record {key}: {err}")
        else:
            print(f"Record {key} successfully produced to {msg.topic()} [{msg.partition()}]")
    iteration = 0
    batch = messages[iteration:NUMBER_OF_MESSAGE_FOR_BATCH]
    for x in batch:
      
      if len(x) == 0:
         producer.flush()
         exit()

      producer.produce(TOPIC, key=x['key'], value=x['value'], callback=delivery_report)
      iteration += NUMBER_OF_MESSAGE_FOR_BATCH
    producer.poll()

# Async wrapper for the produce_message function
async def async_produce_message(executor, key, value):
    loop = asyncio.get_event_loop()
    await loop.run_in_executor(executor, produce_message, key, value)


def get_messages():
    # Generate sample messages
    size_in_bytes = RECORD_WEIGHT_MEGABYTES * 1024 * 1024
    character = "A"  # Using 'A' as the repeated character
    large_string = character * int(size_in_bytes)
    messages = [(id_generator(), large_string) for _ in range(NUM_OF_RECORDS)]
    return messages

def id_generator(size=6, chars=string.ascii_uppercase + string.digits):
    return ''.join(random.choice(chars) for _ in range(size))

# Main async producer task
async def main():
    messages = get_messages()

    # Use a thread pool executor to offload blocking calls
    with ThreadPoolExecutor() as executor:
        tasks = [async_produce_message(executor, key, value) for key, value in messages]
        await asyncio.gather(*tasks)

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

def stats_cb(stats_json_str):
    stats_json = json.loads(stats_json_str)
    with open(f'result_{get_timestamp()}.json', 'w') as fp:
        json.dump(stats_json, fp, indent=4)

def get_timestamp():
  current_timestamp = datetime.now()
  return current_timestamp.strftime("%Y-%m-%d %H:%M:%S")

# Run the async event loop
if __name__ == '__main__':
    config = read_config()
    config['stats_cb'] = stats_cb
    config['statistics.interval.ms'] = int(30000)
    producer = Producer(config)
    asyncio.run(main())