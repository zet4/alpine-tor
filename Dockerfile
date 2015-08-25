FROM alpine

RUN apk add tor --update-cache --repository http://dl-4.alpinelinux.org/alpine/edge/testing/ --allow-untrusted haproxy ruby

RUN apk --update add --virtual build-dependencies ruby-bundler ruby-dev ruby-nokogiri \
  && gem install socksify \
  && apk del build-dependencies \
  && rm -rf /var/cache/apk/*


ADD haproxy.cfg.erb /usr/local/etc/haproxy.cfg.erb

ADD start.rb /usr/local/bin/start.rb
RUN chmod +x /usr/local/bin/start.rb

CMD ruby /usr/local/bin/start.rb