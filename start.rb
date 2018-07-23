#!/usr/bin/env ruby
require 'erb'
require 'socksify/http'
require 'logger'

$logger = Logger.new(STDOUT, ENV['DEBUG'] ? Logger::DEBUG : Logger::INFO)

module Service
  class Base
    attr_reader :port

    def initialize(port)
      @port = port
    end

    def service_name
      self.class.name.downcase.split('::').last
    end

    def start
      ensure_directories
      $logger.info "starting #{service_name} on port #{port}"
    end

    def ensure_directories
      %w{lib run log}.each do |dir|
        path = "/var/#{dir}/#{service_name}"
        Dir.mkdir(path) unless Dir.exists?(path)
      end
    end

    def data_directory
      "/var/lib/#{service_name}"
    end

    def pid_file
      "/var/run/#{service_name}/#{port}.pid"
    end

    def executable
      self.class.which(service_name)
    end

    def stop
      $logger.info "stopping #{service_name} on port #{port}"
      if File.exists?(pid_file)
        pid = File.read(pid_file).strip
        begin
          self.class.kill(pid.to_i)
        rescue => e
          $logger.warn "couldn't kill #{service_name} on port #{port}: #{e.message}"
        end
      else
        $logger.info "#{service_name} on port #{port} was not running"
      end
    end

    def self.kill(pid, signal='SIGINT')
      Process.kill(signal, pid)
    end

    def self.fire_and_forget(*args)
      $logger.debug "running: #{args.join(' ')}"
      pid = Process.fork
      if pid.nil? then
        # In child
        exec args.join(" ")
      else
        # In parent
        Process.detach(pid)
      end
    end

    def self.which(executable)
      path = `which #{executable}`.strip
      if path == ""
        return nil
      else
        return path
      end
    end
  end


  class Tor < Base
    attr_reader :new_circuit_period
    attr_reader :max_circuit_dirtiness
    attr_reader :circuit_build_timeout

    def initialize(port)
      @port = port
      @new_circuit_period = ENV['new_circuit_period'] || 120
      @max_circuit_dirtiness = ENV['max_circuit_dirtiness'] || 600
      @circuit_build_timeout = ENV['circuit_build_timeout'] || 60
    end

    def data_directory
      "#{super}/#{port}"
    end

    def start
      super
      self.class.fire_and_forget(executable,
                                 "--SocksPort #{port}",
                                 "--NewCircuitPeriod #{new_circuit_period}",
                                 "--MaxCircuitDirtiness #{max_circuit_dirtiness}",
                                 "--CircuitBuildTimeout #{circuit_build_timeout}",
                                 "--DataDirectory #{data_directory}",
                                 "--PidFile #{pid_file}",
                                 "--Log \"warn syslog\"",
                                 '--RunAsDaemon 1',
                                 "| logger -t 'tor' 2>&1")
    end
  end

  class Proxy
    attr_reader :id
    attr_reader :tor

    def initialize(id)
      @id = id
      @tor = Tor.new(tor_port)
    end

    def start
      $logger.info "starting proxy id #{id}"
      @tor.start
    end

    def stop
      $logger.info "stopping proxy id #{id}"
      @tor.stop
    end

    def restart
      stop
      sleep 5
      start
    end

    def tor_port
      10000 + id
    end

    alias_method :port, :tor_port

    def test_url
      ENV['test_url'] || 'http://google.com'
    end

    def test_status
      ENV['test_status'] || '302'
    end

    def working?
      uri = URI.parse(test_url)
      Net::HTTP.SOCKSProxy('127.0.0.1', port).start(uri.host, uri.port) do |http|
        http.get(uri.path).code==test_status
      end
    rescue
      false
    end
  end

  class Haproxy < Base
    attr_reader :backends
    attr_reader :stats
    attr_reader :login
    attr_reader :pass

    def initialize()
      @config_erb_path = "/usr/local/etc/haproxy.cfg.erb"
      @config_path = "/usr/local/etc/haproxy.cfg"
      @backends = []
      @stats = ENV['haproxy_stats'] || 2090
      @login = ENV['haproxy_login'] || 'admin'
      @pass = ENV['haproxy_pass'] || 'admin'
      @port = ENV['haproxy_port'] || 5566
    end

    def start
      super
      compile_config
      self.class.fire_and_forget(executable,
                                 "-f #{@config_path}",
                                 "| logger 2>&1")
    end

    def soft_reload
      self.class.fire_and_forget(executable,
                                 "-f #{@config_path}",
                                 "-p #{pid_file}",
                                 "-sf #{File.read(pid_file)}",
                                 "| logger 2>&1")
    end

    def add_backend(backend)
      @backends << {:name => 'tor', :addr => '127.0.0.1', :port => backend.port}
    end

    private
    def compile_config
      File.write(@config_path, ERB.new(File.read(@config_erb_path)).result(binding))
    end
  end

  class Privoxy < Base
    attr_reader :haproxy
    attr_reader :permit
    attr_reader :deny

    def initialize()
      @config_erb_path = "/usr/local/etc/privoxy.cfg.erb"
      @config_path = "/usr/local/etc/privoxy.cfg"
      @port = ENV['privoxy_port'] || 8118
      @haproxy = ENV['haproxy_port'] || 5566
      @permit = ENV['privoxy_permit'] || ""
      @pdeny = ENV['privoxy_deny'] || ""
    end

    def start
      super
      compile_config
      self.class.fire_and_forget(executable, "--no-daemon", "#{@config_path}", "| logger 2>&1")
    end

    private
    def compile_config
      File.write(@config_path, ERB.new(File.read(@config_erb_path)).result(binding))
    end
  end
end


haproxy = Service::Haproxy.new
proxies = []

tor_instances = ENV['tors'] || 20
tor_instances.to_i.times.each do |id|
  proxy = Service::Proxy.new(id)
  haproxy.add_backend(proxy)
  proxy.start
  proxies << proxy
end

haproxy.start

if ENV['privoxy']
  privoxy = Service::Privoxy.new
  privoxy.start
end

sleep 60

loop do
  $logger.info "testing proxies"
  proxies.each do |proxy|
    $logger.info "testing proxy #{proxy.id} (port #{proxy.port})"
    proxy.restart unless proxy.working?
    $logger.info "sleeping for #{tor_instances} seconds"
    sleep Integer(tor_instances)
  end

  $logger.info "sleeping for 60 seconds"
  sleep 60
end
