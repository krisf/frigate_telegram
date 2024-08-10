require 'mqtt'
require 'json'
require 'telegram/bot'

token = ENV['TELEGRAM_TOKEN']
chat_id = ENV['TELEGRAM_CHAT_ID'].to_i

mqtt_host = ENV['MQTT_HOST']
mqtt_port = ENV['MQTT_PORT'].to_i
mqtt_user = ENV['MQTT_USER']
mqtt_pass = ENV['MQTT_PASS']

frigate_url = ENV['FRIGATE_URL']

id_list = []


Telegram::Bot::Client.run(token) do |bot|
  MQTT::Client.connect(host: mqtt_host, port: mqtt_port, username: mqtt_user, password: mqtt_pass) do |c|
    c.get('frigate/events') do |topic,message|
      a = JSON.parse message
      if a['type'] == 'update' && a['has_clip'] == true && !id_list.include?(a['before']['id'])
        id_list << a['before']['id']
        formatted_message = "#{a['before']['camera'].capitalize} - #{a['before']['label'].capitalize} was detected."
        snapshot = "#{frigate_url}/api/events/#{a['before']['id']}/thumbnail.jpg"
        bot.api.send_message(chat_id: chat_id, text: formatted_message)
        bot.api.send_photo(chat_id: chat_id, photo: snapshot, caption: formatted_message, show_caption_above_media: true, disable_notification: true)
        end
      elsif a['type'] == 'end' && a['has_clip'] == true
        clip = "#{frigate_url}/api/events/#{a['before']['id']}/clip.mp4"
        bot.api.send_video(chat_id: chat_id, video: clip, caption: formatted_message, show_caption_above_media: true, supports_streaming: true, disable_notification: true)
      else
        puts "skipped message, not new"
      end
    end
  end
end