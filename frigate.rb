require 'mqtt'
require 'json'
require 'telegram/bot'

token = ENV['TELEGRAM_TOKEN']
chat_id = ENV['TELEGRAM_CHAT_ID']

mqtt_host = ENV['MQTT_HOST']
mqtt_port = ENV['MQTT_PORT'].to_i
mqtt_user = ENV['MQTT_USER']
mqtt_pass = ENV['MQTT_PASS']

frigate_url = ENV['FRIGATE_URL']


Telegram::Bot::Client.run(token) do |bot|
  MQTT::Client.connect(host: mqtt_host, port: mqtt_port, username: mqtt_user, password: mqtt_pass) do |c|
    c.get('frigate/events') do |topic,message|
      a = JSON.parse message
      if a['type'] == 'new'
        formatted_message = "#{a['before']['camera'].capitalize} - #{a['before']['label'].capitalize} was detected."
        snapshot = "#{frigate_url}/api/events/#{a['before']['id']}/thumbnail.jpg"
        bot.api.send_message(chat_id: chat_id, text: formatted_message)
        timeout_reached = 0.1
        until `curl --write-out %{http_code} --silent -I --output /dev/null #{snapshot}` === "200" or timeout_reached > 10 do
          sleep 0.1
          timeout_reached = timeout_reached + 0.1
        end
        bot.api.send_photo(chat_id: chat_id, photo: snapshot, caption: formatted_message, show_caption_above_media: true, disable_notification: true)
      elsif a['type'] == 'end'
        clip = "#{frigate_url}/api/events/#{a['before']['id']}/clip.mp4"
        timeout_reached = 0.1
        until `curl --write-out %{http_code} --silent -I --output /dev/null #{clip}` === "200" or timeout_reached > 10 do
          sleep 0.1
          timeout_reached = timeout_reached + 0.1
        end
        bot.api.send_video(chat_id: chat_id, video: clip, caption: formatted_message, show_caption_above_media: true, supports_streaming: true, disable_notification: true)
      else
        puts "skipped message, not new"
      end
    end
  end
end