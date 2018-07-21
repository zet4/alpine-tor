alpine-tor
==================

```
               Docker Container
               -------------------------------------
               (Optional)           <-> Tor Proxy 1
Client <---->   Privoxy <-> HAproxy <-> Tor Proxy 2
                                    <-> Tor Proxy n
```

Parents
-------
 * [rdsubhas/docker-tor-privoxy-alpine](https://github.com/rdsubhas/docker-tor-privoxy-alpine)
 * [Negashev/docker-haproxy-tor](https://github.com/Negashev/docker-haproxy-tor)
   * [marcelmaatkamp/docker-alpine-tor](https://github.com/marcelmaatkamp/docker-alpine-tor)
   * [mattes/rotating-proxy](https://github.com/mattes/rotating-proxy)

__Why:__ Lots of IP addresses. One single endpoint for your client.
Load-balancing by HAproxy.

Optionaly adds support for [Privoxy](https://www.privoxy.org/) using
`-e privoxy=1`, useful for http (default `8118`, changable via
`-e privoxy_port=<port>`) proxy forward and ad removal.

Environment Variables
-----
 * `tors` - Integer, number of tor instances to run. (Default: 20)
 * `new_circuit_period` - Integer, NewCircuitPeriod parameter value in seconds.
   (Default: 2 minutes)
 * `max_circuit_dirtiness` - Integer, MaxCircuitDirtiness parameter value in
   seconds. (Default: 10 minutes)
 * `circuit_build_timeout` - Integer, CircuitBuildTimeout parameter value in
   seconds. (Default: 60 seconds)
 * `privoxy` - Boolean, whatever to run insance of privoxy in front of haproxy.
 * `privoxy_port` - Integer, port for privoxy. (Default: 8118)
 * `privoxy_permit` - Space-separated list of source addresses for permit-access option. (Default: Unset)
 * `privoxy_deny` - Space-separated list of source addresses for deny-access option. (Default: Unset)
 * `haproxy_port` - Integer, port for haproxy. (Default: 5566)
 * `haproxy_stats` - Integer, port for haproxy monitor. (Default: 2090)
 * `haproxy_login` and `haproxy_pass` - BasicAuth config for haproxy monitor.
   (Default: `admin` in both variables)
 * `test_url` - URL for health check throught Tor proxy.
   (Default: http://google.com)
 * `test_status` - Integer, HTTP status code for `test_url` in working case.
   (Default: 302)

Usage
-----

```bash
# build docker container
docker build -t zeta0/alpine-tor:latest .

# ... or pull docker container
docker pull zeta0/alpine-tor:latest

# start docker container
docker run -d -p 5566:5566 -p 2090:2090 -e tors=25 zeta0/alpine-tor

# start docker with privoxy enabled and exposed
docker run -d -p 8118:8118 -p 2090:2090 -e tors=25 -e privoxy=1 zeta0/alpine-tor

# test with ...
curl --socks5 localhost:5566 http://httpbin.org/ip

# or if privoxy enabled ...
curl --proxy localhost:8118 http://httpbin.org/ip

# or to run chromium with your new found proxy
chromium --proxy-server="http://localhost:8118" \
    --host-resolver-rules="MAP * 0.0.0.0 , EXCLUDE localhost"

# monitor
# auth login:admin
# auth pass:admin
http://localhost:2090 or http://admin:admin@localhost:2090

# start docket container with new auth
docker run -d -p 5566:5566 -p 2090:2090 -e haproxy_login=MySecureLogin \
    -e haproxy_pass=MySecurePassword zeta0/alpine-tor
```

Further Readings
----------------

 * [Tor Manual](https://www.torproject.org/docs/tor-manual.html.en)
 * [Tor Control](https://www.thesprawl.org/research/tor-control-protocol/)
 * [HAProxy Manual](http://cbonte.github.io/haproxy-dconv/index.html)
 * [Privoxy Manual](https://www.privoxy.org/user-manual/)
