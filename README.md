docker-compose example:
-----------

```yaml
services:
  frigate_telegram:
    container_name: frigate_telegram
    restart: unless-stopped
    image: ghcr.io/krisf/frigate_telegram:master
    environment:
      TELEGRAM_TOKEN: 7024604673:AAE2zAAAAAAAAAAAAAAAAAAAAAAAAAAA
      TELEGRAM_CHAT_ID: -1002226239999
      MQTT_HOST: 192.168.0.100
      MQTT_PORT: 1883
      MQTT_USER: myusername
      MQTT_PASS: mypassword
      FRIGATE_URL: "http://192.168.0.100:5000"
```