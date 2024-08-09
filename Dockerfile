FROM ruby:3.3-bullseye
RUN gem install mqtt telegram-bot-ruby
COPY frigate.rb /frigate.rb
CMD ["ruby", "/frigate.rb"]
