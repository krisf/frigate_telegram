require 'mqtt'
require 'json'
require 'telegram/bot'
require 'httparty'
require 'tempfile'

token = ENV['TELEGRAM_TOKEN'] 
chat_id = ENV['TELEGRAM_CHAT_ID'].to_i

mqtt_host = ENV['MQTT_HOST']
mqtt_port = ENV['MQTT_PORT']
mqtt_user = ENV['MQTT_USER']
mqtt_pass = ENV['MQTT_PASS']

frigate_url = ENV['FRIGATE_URL']

id_list = []

def download_to_tmp(url)
  count = 0
  begin
    resp = HTTParty.get(url)
  rescue
    sleep 1
    count = count + 1
    exit if count == 4
    retry
  end


  file = Tempfile.new
  file.binmode
  file.write(resp.body)
  file.rewind
  puts file.path
  puts file.size
  file
end


Telegram::Bot::Client.run(token) do |bot|
  MQTT::Client.connect(host: mqtt_host, port: mqtt_port, username: mqtt_user, password: mqtt_pass) do |c|
    c.get('frigate/events') do |topic,message|
      a = JSON.parse message
      if a['type'] == 'update' && a['after']['has_clip'] == true && !id_list.include?(a['before']['id'])
        id_list << a['before']['id']
        formatted_message = "#{a['before']['camera'].capitalize} - #{a['before']['label'].capitalize} was detected."
        snapshot = "#{frigate_url}/api/events/#{a['before']['id']}/thumbnail.jpg"
        #bot.api.send_message(chat_id: chat_id, text: formatted_message)
        file = download_to_tmp(snapshot)
        if file.size > 100 && file.size < 10000000
          begin; bot.api.send_photo(chat_id: chat_id, photo: Faraday::UploadIO.new(file.path, 'image/jpeg'), caption: formatted_message, show_caption_above_media: true, disable_notification: true); rescue; puts "#{snapshot} failed.";end;
        end
        file.close
        file.unlink    # deletes the temp file
      elsif a['type'] == 'end' && a['after']['has_clip'] == true
        clip = "#{frigate_url}/api/events/#{a['before']['id']}/clip.mp4"
        file = download_to_tmp(clip)
        if file.size > 100 && file.size < 50000000
          begin; bot.api.send_video(chat_id: chat_id, video: Faraday::UploadIO.new(file.path, 'video/mp4'), caption: formatted_message, show_caption_above_media: true, supports_streaming: true, disable_notification: true) ; rescue; puts "#{clip} failed.";end;
        elsif file.size > 50000000
          bot.api.send_message(chat_id: chat_id, text: "#{formatted_message}: #{clip}")
        end
        file.close
        file.unlink    # deletes the temp file
      else
        puts "skipped message, not new"
      end
    end
  end
end