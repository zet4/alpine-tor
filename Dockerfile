FROM alpine:edge

RUN apk add 'tor' --no-cache \
  --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
  --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
  --allow-untrusted haproxy ruby privoxy

RUN apk --update add --virtual build-dependencies ruby-bundler ruby-dev  \
  && apk add ruby-nokogiri --update-cache --repository http://dl-4.alpinelinux.org/alpine/v3.3/main/ \
  && gem install --no-document socksify \
  && apk del build-dependencies \
  && rm -rf /var/cache/apk/*


ADD haproxy.cfg.erb /usr/local/etc/haproxy.cfg.erb
ADD privoxy.cfg.erb /usr/local/etc/privoxy.cfg.erb

ADD start.rb /usr/local/bin/start.rb
RUN chmod +x /usr/local/bin/start.rb

EXPOSE 2090 8118 5566

CMD ruby /usr/local/bin/start.rb
