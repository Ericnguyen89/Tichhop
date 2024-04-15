import json
import socket
import time
import ssl
from paho.mqtt import client as mqtt_client

broker = 'mqtt.example.com'
port = 8883
topic = "test"
client_id = f'publish-{random.randint(0, 1000)}'
username = 'usb'
password = 'changeme'

def connect_mqtt():
    """
    Connect to the MQTT broker.
    """
    def on_connect(client, userdata, flags, rc):
        if rc == 0:
            print("Connected to MQTT Broker!")
        else:
            print(f"Failed to connect to MQTT Broker with return code {rc}")

    client = mqtt_client.Client(client_id)
    client.username_pw_set(username, password)
    client.on_connect = on_connect
    client.tls_set(ca_certs="/etc/ssl/certs/ca-certificates.crt")
    try:
        client.connect(broker, port)
    except Exception as e:
        print(f"Error connecting to MQTT broker: {e}")
    return client

def follow_log_file(file_path):
    """
    Generator function that yields new log lines as they are written to the log file.
    """
    with open(file_path, 'r') as file:
        file.seek(0,2)  # Go to the end of the file
        while True:
            line = file.readline()
            if not line:
                time.sleep(0.1)  # Sleep briefly to avoid busy waiting
                continue
            yield line

def re_filter_log(raw_log):
    """
    Re-filters log data to match the specified format.
    """
    filtered_log = {
        "agent": {
            "ip": raw_log.get("agent", {}).get("ip", ""),
            "name": raw_log.get("agent", {}).get("name", "")
        },
        "rule": {
            "description": raw_log.get("rule", {}).get("description", ""),
            "level": raw_log.get("rule", {}).get("level", 0)
        },
        "manager": {
            "name": "Workerblue"
        },
        "timestamp": raw_log.get("timestamp", ""),
        "data": {
            "srcip": raw_log.get("data", {}).get("src_ip", ""),
            "dstip": raw_log.get("data", {}).get("dest_ip", "")
        }
    }
    return filtered_log

def send_log_to_server(log_data, ip, port):
    """
    Sends log data to the specified server.
    """
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.connect((ip, port))
            sock.sendall(log_data.encode('utf-8'))
    except Exception as e:
        print(f"Error sending log data to server: {e}")

def mqtt_publish(client, topic, message, qos=1, retain=False):
    """
    Publishes a message to the MQTT broker with error handling and message persistence.
    """
    try:
        result = client.publish(topic, message, qos=qos, retain=retain)
        if result.rc != mqtt_client.MQTT_ERR_SUCCESS:
            print(f"Failed to publish message to MQTT broker with return code {result.rc}")
    except Exception as e:
        print(f"Error publishing message to MQTT broker: {e}")

if __name__ == "__main__":
    log_file_path = '/var/log/logstash/logstash1.json'
    server_ip = '192.168.70.88'
    server_port = 1882
    client = connect_mqtt()
    client.loop_start()

    for raw_log in follow_log_file(log_file_path):
        try:
            log_data = json.loads(raw_log)
            filtered_log = re_filter_log(log_data)
            send_log_to_server(json.dumps(filtered_log), server_ip, server_port)
            mqtt_publish(client, topic, json.dumps(filtered_log), qos=1, retain=False)
        except json.JSONDecodeError:
            print("Error decoding JSON from log file.")
