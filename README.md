docker-haproxy-tor
==================

```
               Docker Container
               -------------------------------------
                       <-> Tor Proxy 1
Client <---->  HAproxy <-> Tor Proxy 2
                       <-> Tor Proxy n
```

Parents
-------

 * [marcelmaatkamp/docker-alpine-tor](https://github.com/marcelmaatkamp/docker-alpine-tor)
 * [mattes/rotating-proxy](https://github.com/mattes/rotating-proxy)

__Why:__ Lots of IP addresses. One single endpoint for your client.
Load-balancing by HAproxy.

Usage
-----

```bash
# build docker container
docker build -t negash/docker-haproxy-tor:latest .

# ... or pull docker container
docker pull negash/docker-haproxy-tor:latest

# start docker container
docker run -d -p 5566:5566 -p 2090:2090 -e tors=25 negash/docker-haproxy-tor

# test with ...
curl --socks5 192.168.99.100:5566 http://echoip.com

# monitor 
# auth login:admin
# auth pass:admin
http://192.168.99.100:2090

# start docket container with new auth
docker run -d -p 5566:5566 -p 2090:2090 -e login=MySecureLogin -e pass=MySecurePassword negash/docker-haproxy-tor

```



Further Readings
----------------

 * [Tor Manual](https://www.torproject.org/docs/tor-manual.html.en)
 * [Tor Control](https://www.thesprawl.org/research/tor-control-protocol/)
 * [HAProxy Manual](http://cbonte.github.io/haproxy-dconv/index.html)
