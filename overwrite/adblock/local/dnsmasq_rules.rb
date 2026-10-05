#!/usr/bin/env ruby
# Local, explicitly installed component. Remote .conf files declare data sources only.
# Runtime dependencies are already required by OpenClash: Ruby, ruby-yaml and curl.
require 'yaml'

class DnsmasqRules
  SOURCES = {
    'custom-hosts' => ['hosts', 1],
    'github520' => ['hosts', 2],
    'anti-ad' => ['dnsmasq', 0],
    'adblockfilters-hosts' => ['hosts', 0],
    'adblockfilters-dnsmasq' => ['dnsmasq', 0]
  }.freeze
  CONF_NAME = '90-openclash-dnsmasq-rules.conf'.freeze
  HOSTS_NAME = '.openclash-dnsmasq-rules.hosts'.freeze
  MARKER = '# OpenClash dnsmasq-rules: managed file'.freeze
  HOOK_START = '# BEGIN OpenClash dnsmasq-rules'.freeze
  HOOK_END = '# END OpenClash dnsmasq-rules'.freeze
  CRON_MARKER = '# openclash-dnsmasq-rules'.freeze
  SCRIPT = '/etc/openclash/custom/dnsmasq_rules.rb'.freeze
  MAX_BYTES = 32 * 1024 * 1024
  UPDATE_INTERVAL = 8 * 3600
  RETRY_INTERVAL = 10 * 60
  PROTECTED_HOSTS = %w[localhost localhost.localdomain local broadcasthost ip6-localhost ip6-loopback
                       ip6-localnet ip6-mcastprefix ip6-allnodes ip6-allrouters ip6-allhosts].freeze

  def initialize(root: '')
    @root = root
    @cache = path('/etc/openclash/dnsmasq-rules')
    @work = path('/tmp/openclash-dnsmasq-rules')
    @state = {}
  end

  def path(name)
    "#{@root}#{name}"
  end

  def logical(name)
    @root.empty? ? name : name.delete_prefix(@root)
  end

  # All external commands receive an argv array; neither URLs nor UCI values enter a shell.
  def capture(*argv)
    output = IO.popen(argv, err: File::NULL, &:read)
    raise "command failed: #{argv.first}" unless $?.success?
    output
  end

  def execute(*argv)
    system(*argv, out: File::NULL, err: File::NULL)
  end

  def log(message)
    warn "dnsmasq-rules: #{message}"
    execute('logger', '-t', 'openclash-dnsmasq-rules', '--', message)
  end

  def secure_directory(dir)
    Dir.mkdir(dir, 0o700) unless File.exist?(dir) || File.symlink?(dir)
    stat = File.lstat(dir)
    raise "unsafe component directory: #{logical(dir)}" unless stat.directory? && stat.uid == Process.uid && (stat.mode & 0o077).zero?
  end

  def locked
    secure_directory(@work)
    lock_path = File.join(@work, 'lock')
    raise 'unsafe lock file' if File.symlink?(lock_path)
    File.open(lock_path, File::RDWR | File::CREAT, 0o600) do |lock|
      return unless lock.flock(File::LOCK_EX | File::LOCK_NB)
      secure_directory(@cache)
      state_file = File.join(@cache, 'state.yaml')
      @state = File.file?(state_file) ? YAML.safe_load(File.read(state_file), permitted_classes: [], aliases: false) : {}
      raise 'invalid saved state' unless @state.is_a?(Hash)
      @state['sources'] ||= {}
      begin
        yield
      ensure
        serialized = YAML.dump(@state)
        atomic_write(state_file, serialized, 0o600) unless File.file?(state_file) && File.read(state_file) == serialized
        Dir.glob(File.join(@work, 'stage.*')).each { |file| File.unlink(file) if File.file?(file) }
      end
    end
  end

  def atomic_write(file, content, mode = 0o644)
    raise "refuse symlink: #{logical(file)}" if File.symlink?(file)
    temporary = File.join(File.dirname(file), ".#{File.basename(file)}.tmp.#{$$}")
    File.open(temporary, File::WRONLY | File::CREAT | File::EXCL, mode) do |io|
      io.write(content)
      io.flush
      io.fsync
    end
    File.rename(temporary, file)
  ensure
    File.unlink(temporary) if temporary && File.exist?(temporary)
  end

  # Parse UCI's quoting without eval or a dependency on ruby-shellwords.
  def self.words(line)
    tokens = []
    word = +''
    quote = nil
    escaped = false
    started = false
    line.each_char do |character|
      if escaped
        word << character
        escaped = false
      elsif quote == "'"
        character == "'" ? quote = nil : word << character
      elsif character == '\\'
        escaped = true
        started = true
      elsif quote == '"'
        character == '"' ? quote = nil : word << character
      elsif character == "'" || character == '"'
        quote = character
        started = true
      elsif character.match?(/\s/)
        tokens << word if started
        word = +''
        started = false
      else
        word << character
        started = true
      end
    end
    raise 'invalid UCI quoting' if quote || escaped
    tokens << word if started
    tokens
  end

  def settings
    sections = []
    capture('uci', '-q', 'export', 'openclash').each_line do |line|
      fields = self.class.words(line.strip)
      case fields.first
      when 'config'
        sections << {'type' => fields[1], 'name' => fields[2], 'options' => {}, 'lists' => {}}
      when 'option'
        sections.last['options'][fields[1]] = fields[2] if sections.any?
      when 'list'
        (sections.last['lists'][fields[1]] ||= []) << fields[2] if sections.any?
      end
    end
    # uci_get_config reads the named section openclash.config; its type is "openclash".
    base = sections.find { |section| section['name'] == 'config' }
    raise 'OpenClash configuration is missing' unless base
    overlay = sections.find { |section| section['type'] == 'overwrite' }
    effective = base['options'].merge(overlay ? overlay['options'] : {})
    [sections, effective, base['options']['enable'] == '1']
  end

  def active_sources
    sections, effective, enabled = settings
    return [] unless enabled
    sources = {}
    sections.select { |section| section['type'] == 'config_overwrite' }.each do |section|
      options = section['options']
      next unless options['enable'] == '1'
      next unless (section['lists']['config'] || []).any? { |item| item == 'all' || item == effective['config_path'] }
      name = options['name'].to_s
      next if name.empty? || name.include?('/') || name.include?('\\') || %w[. ..].include?(name)
      file = path("/etc/openclash/overwrite/#{name}")
      next unless File.file?(file) && File.size(file) <= 256 * 1024
      text = File.read(file)
      ids = text.scan(/^# dnsmasq-rules-source: (\S+)\s*$/).flatten
      next if ids.empty?
      raise "invalid source declaration in #{name}" unless ids.length == 1 && SOURCES.key?(ids.first)
      urls = text.scan(/^# dnsmasq-rules-url: (\S+)\s*$/).flatten
      raise "invalid source URL declaration in #{name}" unless urls.length == 1
      parameters = options.fetch('param', '').split(';').to_h { |item| key, value = item.split('=', 2); [key.to_s.strip, value.to_s.strip] }
      url = urls.first.gsub(/\$\{(EN_KEY\d+)\}|\$(EN_KEY\d+)/) { parameters.fetch(Regexp.last_match(1) || Regexp.last_match(2), '') }
      raise "#{ids.first}: provide a valid HTTPS source URL" unless url.match?(%r{\Ahttps://[^\s/?#@]+(?:/[^\s#]*)?\z})
      previous = sources[ids.first]
      raise "#{ids.first}: multiple enabled copies use different URLs" if previous && previous['url'] != url
      sources[ids.first] = {'id' => ids.first, 'url' => url}
    end
    raise 'use Dnsmasq Redirect; another overwrite selected a different DNS mode' if sources.any? && effective['enable_redirect_dns'] != '1'
    sources.values.sort_by { |source| source['id'] }
  end

  def self.domain(value)
    name = value.downcase.delete_suffix('.').delete_prefix('.')
    raise "invalid domain: #{value}" unless name.bytesize.between?(1, 253) && name.split('.', -1).all? { |label| label.match?(/\A[a-z0-9_](?:[a-z0-9_-]{0,61}[a-z0-9_])?\z/) }
    name
  end

  def self.protected?(name)
    PROTECTED_HOSTS.include?(name) || name.end_with?('.localhost', '.local')
  end

  def self.ip_family(ip)
    if ip.include?(':')
      candidate = ip.downcase
      if candidate.include?('.')
        tail = candidate.split(':').last
        return nil unless ip_family(tail) == 4
        candidate = candidate.delete_suffix(tail) + '0:0'
      end
      return nil unless candidate.match?(/\A[0-9a-f:]+\z/) && candidate.scan('::').length <= 1
      return nil if (candidate.start_with?(':') && !candidate.start_with?('::')) || (candidate.end_with?(':') && !candidate.end_with?('::'))
      groups = candidate.split(':', -1)
      return nil unless groups.reject(&:empty?).all? { |group| group.length <= 4 }
      compressed = candidate.include?('::')
      return nil if !compressed && (groups.length != 8 || groups.any?(&:empty?))
      return nil if compressed && (groups.reject(&:empty?).length >= 8 || candidate.include?(':::'))
      return 6
    end
    octets = ip.split('.', -1)
    octets.length == 4 && octets.all? { |octet| octet.match?(/\A(?:0|[1-9][0-9]{0,2})\z/) && octet.to_i <= 255 } ? 4 : nil
  end

  def self.blocking_ip?(ip)
    return %w[0.0.0.0 127.0.0.1].include?(ip) unless ip.include?(':')
    value = ip.downcase
    if value.include?('.')
      tail = value.split(':').last
      bytes = tail.split('.').map(&:to_i)
      value = value.delete_suffix(tail) + [(bytes[0] << 8) | bytes[1], (bytes[2] << 8) | bytes[3]].map { |part| part.to_s(16) }.join(':')
    end
    left, right = value.split('::', 2)
    groups = left.split(':').map { |part| part.to_i(16) }
    if right
      suffix = right.split(':').map { |part| part.to_i(16) }
      groups += Array.new(8 - groups.length - suffix.length, 0) + suffix
    end
    groups.all?(&:zero?) || groups == [0, 0, 0, 0, 0, 0, 0, 1] ||
      (groups.first(6) == [0, 0, 0, 0, 0, 65_535] && [[0, 0], [32_512, 1]].include?(groups.last(2)))
  end

  # Cache only normalized records; foreign dnsmasq directives and malformed hosts fail the entire download.
  def self.normalize(input, output, id)
    format, priority = SOURCES.fetch(id)
    raise 'rule file exceeds 32 MiB' if File.size(input) > MAX_BYTES
    count = 0
    File.open(output, 'w', 0o600) do |destination|
      File.foreach(input, encoding: 'UTF-8') do |line|
        raise 'invalid UTF-8 rule file' unless line.valid_encoding?
        line = line.delete_prefix("\uFEFF").split('#', 2).first.to_s.strip
        next if line.empty?
        if format == 'hosts'
          ip, *names = line.split
          raise 'invalid hosts record' if names.empty?
          names = names.map { |value| domain(value) }.reject { |name| protected?(name) }
          next if names.empty?
          family = ip_family(ip.to_s)
          raise 'invalid hosts record' unless family
          names.each do |name|
            blocked = blocking_ip?(ip)
            raise 'adblockfilters hosts contains a non-blocking mapping' if id == 'adblockfilters-hosts' && !blocked
            raise 'GitHub520 contains a blocking mapping' if id == 'github520' && blocked
            destination.puts([name, blocked ? 'B' : 'H', priority, ip.downcase].join("\t"))
            count += 1
          end
        else
          match = line.match(%r{\A(?:local|server|address)=/([^\s]+)/\z})
          raise 'unsupported dnsmasq directive; only domain blocking is accepted' unless match
          match[1].split('/').each do |value|
            name = domain(value)
            next if protected?(name)
            destination.puts([name, 'D', priority, ''].join("\t"))
            count += 1
          end
        end
      end
    end
    raise 'rule file has no usable records' if count.zero?
    count
  end

  def source_cache(source, refresh, force)
    id = source['id']
    data = File.join(@cache, "#{id}.rules")
    info = (@state['sources'][id] ||= {})
    now = Time.now.to_i
    same_url = info['url'] == source['url'] && File.file?(data)
    due = now - info.fetch('checked', 0) >= UPDATE_INTERVAL
    retry_due = now - info.fetch('attempt', 0) >= RETRY_INTERVAL
    if refresh && (force || ((due || !same_url) && retry_due))
      info['attempt'] = now
      raw = File.join(@work, "stage.#{id}.download")
      normalized = File.join(@work, "stage.#{id}.rules")
      begin
        ok = execute('curl', '--fail', '--silent', '--show-error', '--location', '--proto', '=https', '--proto-redir', '=https',
                     '--connect-timeout', '10', '--max-time', '30', '--max-filesize', MAX_BYTES.to_s, '--url', source['url'], '--output', raw)
        raise 'download failed' unless ok && File.file?(raw)
        count = self.class.normalize(raw, normalized, id)
        atomic_write(data, File.binread(normalized), 0o600) unless same_url && same_file?(data, normalized)
        info.merge!('url' => source['url'], 'checked' => now, 'records' => count)
        same_url = true
        log("#{id}: validated #{count} records")
      rescue StandardError => error
        log("#{id}: #{error.message}; #{same_url ? 'keep validated cache' : 'source is not loaded'}")
      end
    end
    same_url ? data : nil
  end

  def dnsmasq_context
    first = capture('uci', '-q', 'show', 'dhcp.@dnsmasq[0]').lines.first.to_s
    instance = first[/\Adhcp\.([A-Za-z0-9_]+)=/, 1]
    raise 'cannot identify the first dnsmasq instance' unless instance
    configuration = [path("/tmp/etc/dnsmasq.conf.#{instance}"), path("/var/etc/dnsmasq.conf.#{instance}")].find { |file| File.file?(file) }
    raise 'dnsmasq must be running before rules can be applied' unless configuration
    lines = File.readlines(configuration)
    directory = lines.filter_map { |line| line[/\Aconf-dir=(.+)/, 1]&.split(',')&.first }
    raise 'dnsmasq must have one configuration directory' unless directory.length == 1
    dir = directory.first
    raise 'unsafe dnsmasq directory' unless dir.start_with?('/') && !dir.split('/').include?('..') && dir.match?(%r{\A/[A-Za-z0-9_./-]+\z}) && !%w[/ /tmp /etc /var].include?(dir)
    raise 'dnsmasq configuration directory is missing' unless File.directory?(path(dir))
    pidfile = lines.filter_map { |line| line[/\Apid-file=(.+)/, 1] }.first || "/var/run/dnsmasq/dnsmasq.#{instance}.pid"
    {'instance' => instance, 'directory' => dir, 'configuration' => logical(configuration), 'pidfile' => pidfile}
  end

  def self.suffix_blocked?(name, blocked)
    candidate = name
    loop do
      return true if blocked.key?(candidate)
      position = candidate.index('.')
      return false unless position
      candidate = candidate[(position + 1)..]
    end
  end

  def build(caches, directory)
    blocks = {}
    combined = File.join(@work, 'stage.combined')
    File.open(combined, 'w', 0o600) do |destination|
      caches.each do |file|
        File.foreach(file) do |line|
          fields = line.chomp.split("\t", -1)
          fields[1] == 'D' ? blocks[fields[0]] = true : destination.write(line)
        end
      end
    end
    # Compact suffix blocks; exact hosts blocks remain exact.
    blocks.delete_if { |name, _| name.include?('.') && self.class.suffix_blocked?(name.split('.', 2).last, blocks) }
    hosts_file = File.join(@work, 'stage.hosts')
    host_count = 0
    suppressed = 0
    File.open(hosts_file, 'w', 0o644) do |destination|
      destination.puts(MARKER)
      flush = lambda do |name, records|
        next unless name
        if self.class.suffix_blocked?(name, blocks)
          suppressed += 1
        elsif records.any? { |record| record[0] == 'B' }
          destination.puts("0.0.0.0 #{name}", ":: #{name}")
          host_count += 1
          suppressed += 1 if records.any? { |record| record[0] == 'H' }
        else
          priority = records.map { |record| record[1].to_i }.min
          mappings = records.select { |record| record[1].to_i == priority }.map(&:last).uniq.sort
          mappings.group_by { |ip| self.class.ip_family(ip) }.each_value do |ips|
            destination.puts("#{ips.first} #{name}")
          end
          host_count += 1
          suppressed += 1 if records.map(&:last).uniq.length > mappings.group_by { |ip| self.class.ip_family(ip) }.length
        end
      end
      previous = nil
      records = []
      IO.popen([{'LC_ALL' => 'C'}, 'sort', combined], err: File::NULL) do |sorted|
        sorted.each_line do |line|
          name, kind, priority, ip = line.chomp.split("\t", -1)
          if name != previous
            flush.call(previous, records)
            previous = name
            records = []
          end
          records << [kind, priority, ip] unless records.include?([kind, priority, ip])
        end
        flush.call(previous, records)
      end
      raise 'cannot sort hosts records' unless $?.success?
    end
    configuration = "#{MARKER}\naddn-hosts=#{directory}/#{HOSTS_NAME}\n"
    blocks.keys.sort.each { |name| configuration << "address=/#{name}/\n" }
    conf_file = File.join(@work, 'stage.conf')
    File.write(conf_file, configuration)
    raise 'generated configuration failed dnsmasq validation' unless execute('dnsmasq', '--test', "--conf-file=#{conf_file}")
    [conf_file, hosts_file, {'suffix_blocks' => blocks.length, 'hosts' => host_count, 'resolved_conflicts' => suppressed}]
  end

  def same_file?(left, right)
    return false unless File.file?(left) && File.size(left) == File.size(right)
    File.open(left, 'rb') do |a|
      File.open(right, 'rb') do |b|
        loop do
          chunk = a.read(64 * 1024)
          return true unless chunk
          return false unless chunk == b.read(64 * 1024)
        end
      end
    end
  end

  def owned_file?(file)
    File.file?(file) && !File.symlink?(file) && File.open(file, &:readline).strip == MARKER
  rescue EOFError
    false
  end

  def signal_dnsmasq(context)
    pid = dnsmasq_pid(context)
    return false unless pid
    Process.kill('HUP', pid)
    true
  rescue Errno::ESRCH
    false
  end

  def dnsmasq_pid(context)
    config = context['configuration']
    return nil unless config
    # ujail writes a namespace PID (often 1). Find the host PID and exclude its wrapper.
    Dir.glob(path('/proc/[0-9]*/comm')).each do |comm|
      pid = File.basename(File.dirname(comm)).to_i
      next unless pid > 1
      begin
        next unless File.read(comm).strip == 'dnsmasq'
        arguments = File.binread(File.join(File.dirname(comm), 'cmdline')).split("\0")
        next unless File.basename(arguments.first.to_s) == 'dnsmasq'
        candidates = arguments.each_cons(2).filter_map { |key, value| value if %w[-C --conf-file].include?(key) }
        candidates += arguments.filter_map { |argument| argument.delete_prefix('--conf-file=') if argument.start_with?('--conf-file=') }
        # OpenWrt aliases /var to /tmp; compare files, not the spelling of their paths.
        return pid if candidates.any? { |candidate| File.identical?(path(candidate), path(config)) }
      rescue Errno::ENOENT, Errno::ESRCH, Errno::EACCES
        next
      end
    end
    nil
  end

  def running?(context)
    !dnsmasq_pid(context).nil?
  end

  def restart_dnsmasq(context)
    return false unless execute('/etc/init.d/dnsmasq', 'restart', context['instance'])
    300.times do
      return true if running?(context)
      sleep 0.1
    end
    false
  end

  def commit(context, configuration, hosts)
    dir = path(context['directory'])
    conf = File.join(dir, CONF_NAME)
    host = File.join(dir, HOSTS_NAME)
    [conf, host].each { |file| raise "existing file is not owned by this component: #{logical(file)}" if (File.exist?(file) || File.symlink?(file)) && !owned_file?(file) }
    conf_changed = configuration.nil? ? File.exist?(conf) : !same_file?(conf, configuration)
    hosts_changed = hosts.nil? ? File.exist?(host) : !same_file?(host, hosts)
    return false unless conf_changed || hosts_changed
    old_conf = File.file?(conf) ? File.binread(conf) : nil
    old_hosts = File.file?(host) ? File.binread(host) : nil
    begin
      if configuration
        atomic_write(host, File.binread(hosts))
        atomic_write(conf, File.binread(configuration)) if conf_changed
      else
        File.unlink(conf) if File.exist?(conf)
        File.unlink(host) if File.exist?(host)
      end
      ok = conf_changed ? restart_dnsmasq(context) : signal_dnsmasq(context)
      raise 'dnsmasq did not accept the reload' unless ok
    rescue StandardError
      old_hosts ? atomic_write(host, old_hosts) : File.unlink(host) if old_hosts || File.exist?(host)
      old_conf ? atomic_write(conf, old_conf) : File.unlink(conf) if old_conf || File.exist?(conf)
      restart_dnsmasq(context)
      raise
    end
    true
  end

  def sync(refresh: false, force: false)
    locked do
      sources = active_sources
      context = dnsmasq_context
      caches = sources.filter_map { |source| source_cache(source, refresh, force) }
      old_context = @state['context']
      fingerprint = caches.map { |file| stat = File.stat(file); [File.basename(file), stat.ino, stat.size, stat.mtime.to_f] }
      outputs = output_signatures(context)
      unchanged = @state['fingerprint'] == fingerprint && @state['context'] == context && @state['outputs'] == outputs &&
                  (caches.empty? ? outputs.all?(&:nil?) : outputs.none?(&:nil?))
      unless unchanged
        if caches.empty?
          commit(context, nil, nil)
          @state['counts'] = {'suffix_blocks' => 0, 'hosts' => 0, 'resolved_conflicts' => 0}
        else
          configuration, hosts, counts = build(caches, context['directory'])
          commit(context, configuration, hosts)
          @state['counts'] = counts
        end
        if old_context && old_context['directory'] != context['directory'] && File.directory?(path(old_context['directory']))
          commit(old_context, nil, nil)
        end
        @state['fingerprint'] = fingerprint
        @state['context'] = context
        @state['outputs'] = output_signatures(context)
        log("applied #{caches.length} sources: #{@state['counts']}")
      end
      @state['active'] = sources.map { |source| source['id'] }
      @state['loaded'] = caches.map { |file| File.basename(file, '.rules') }
    end
  end

  def output_signatures(context)
    [CONF_NAME, HOSTS_NAME].map do |name|
      file = File.join(path(context['directory']), name)
      if File.exist?(file) || File.symlink?(file)
        raise "existing file is not owned by this component: #{logical(file)}" unless owned_file?(file)
        stat = File.stat(file)
        [stat.ino, stat.size, stat.mtime.to_f]
      end
    end
  end

  def cleanup
    locked do
      context = @state['context'] || dnsmasq_context
      commit(context, nil, nil)
      @state.delete('context')
      @state.delete('fingerprint')
      @state.delete('outputs')
      @state['active'] = []
      @state['loaded'] = []
      @state['counts'] = {}
    end
  end

  def install
    raise "install the script at #{SCRIPT} first" unless installed_script?
    locked do
      hook = path('/etc/openclash/custom/openclash_custom_overwrite.sh')
      raise 'OpenClash local overwrite hook is missing' unless File.file?(hook)
      text = File.read(hook)
      text = without_hook(text)
      # Place the call immediately after the shebang, before existing exit/return statements.
      lines = text.lines
      position = lines.first.to_s.start_with?('#!') ? 1 : 0
      lines.insert(position, "#{HOOK_START}\nruby #{SCRIPT} apply\n#{HOOK_END}\n")
      cron = path('/etc/crontabs/root')
      original = File.file?(cron) ? File.read(cron) : ''
      rows = original.lines.reject { |line| line.rstrip.end_with?(CRON_MARKER) }
      rows << "\n" unless rows.empty? || rows.last.end_with?("\n")
      rows << "*/5 * * * * ruby #{SCRIPT} sync >/dev/null 2>&1 #{CRON_MARKER}\n"
      write_integration({hook => lines.join, cron => rows.join}, cron)
      log('installed; enable modules, restart OpenClash once, then run update')
    end
  end

  def write_integration(changes, cron)
    backups = changes.keys.to_h do |file|
      raise "unsafe integration file: #{logical(file)}" if File.symlink?(file) || (File.exist?(file) && !File.file?(file))
      [file, [File.file?(file) ? File.binread(file) : nil, File.file?(file) ? File.stat(file).mode & 0o777 : 0o600]]
    end
    begin
      changes.each { |file, content| atomic_write(file, content, backups[file][1]) }
      raise 'cannot reload the root crontab' if changes.key?(cron) && !execute('crontab', cron)
    rescue StandardError
      backups.each do |file, (content, mode)|
        content ? atomic_write(file, content, mode) : File.unlink(file) if content || File.exist?(file)
      end
      log('cannot reload the restored root crontab') if changes.key?(cron) && !execute('crontab', cron)
      raise
    end
  end

  def installed_script?
    File.expand_path(__FILE__) == path(SCRIPT)
  end

  def without_hook(text)
    inside = false
    lines = []
    text.each_line do |line|
      if line.strip == HOOK_START
        raise 'duplicate component hook marker' if inside
        inside = true
      elsif line.strip == HOOK_END
        raise 'unmatched component hook marker' unless inside
        inside = false
      elsif !inside
        lines << line
      end
    end
    raise 'incomplete component hook marker' if inside
    lines.join
  end

  def uninstall
    locked do
      hook = path('/etc/openclash/custom/openclash_custom_overwrite.sh')
      cron = path('/etc/crontabs/root')
      changes = {}
      changes[hook] = without_hook(File.read(hook)) if File.file?(hook)
      changes[cron] = File.readlines(cron).reject { |line| line.rstrip.end_with?(CRON_MARKER) }.join if File.file?(cron)
      context = @state['context'] || dnsmasq_context
      commit(context, nil, nil)
      write_integration(changes, cron)
      @state.delete('context')
      @state.delete('fingerprint')
      @state.delete('outputs')
      @state['active'] = []
      @state['loaded'] = []
      @state['counts'] = {}
    end
    log('uninstalled integration; script and validated cache retained for explicit removal')
  end

  def status
    file = File.join(@cache, 'state.yaml')
    return puts('Not installed or no rules have been applied.') unless File.file?(file)
    data = YAML.safe_load(File.read(file), permitted_classes: [], aliases: false)
    sources = data.fetch('sources', {}).transform_values { |info| info.select { |key, _| %w[checked records attempt].include?(key) } }
    puts YAML.dump(data.select { |key, _| %w[active loaded counts context].include?(key) }.merge('sources' => sources))
  end
end

if $PROGRAM_NAME == __FILE__
  abort 'Run this local component as root on the OpenWrt router.' unless Process.uid.zero?
  component = DnsmasqRules.new
  begin
    case ARGV.first
    when 'install' then component.install
    when 'apply' then component.sync
    when 'sync' then component.sync(refresh: true)
    when 'update' then component.sync(refresh: true, force: true)
    when 'cleanup' then component.cleanup
    when 'uninstall' then component.uninstall
    when 'status' then component.status
    else abort 'Usage: dnsmasq_rules.rb install|apply|sync|update|cleanup|uninstall|status'
    end
  rescue StandardError => error
    component.log(error.message)
    exit 1
  end
end
