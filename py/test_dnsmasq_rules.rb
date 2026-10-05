# Offline tests: all files are under a disposable directory; UCI, downloads and services are mocked.
require 'tmpdir'
require 'fileutils'
require 'stringio'
require_relative '../overwrite/adblock/local/dnsmasq_rules'

class FixtureRules < DnsmasqRules
  attr_accessor :sections, :downloads, :fail_download, :fail_restarts, :fail_validation, :fail_cron, :enabled, :dns_mode
  attr_reader :calls, :signals, :messages

  def initialize(root:)
    super
    @sections = []
    @downloads = {}
    @calls = []
    @messages = []
    @signals = 0
    @fail_restarts = 0
    @enabled = true
    @dns_mode = '1'
  end

  def capture(*argv)
    if argv == ['uci', '-q', 'export', 'openclash']
      "config openclash 'config'\noption enable '#{@enabled ? 1 : 0}'\noption config_path '/etc/openclash/config/test.yaml'\noption enable_redirect_dns '#{@dns_mode}'\n" + @sections.join
    elsif argv == ['uci', '-q', 'show', 'dhcp.@dnsmasq[0]']
      "dhcp.cfg0=dnsmasq\n"
    else
      raise "unexpected command: #{argv.inspect}"
    end
  end

  def execute(*argv)
    @calls << argv
    case argv.first
    when 'curl'
      return false if @fail_download
      url = argv[argv.index('--url') + 1]
      content = @downloads.fetch(url)
      File.write(argv[argv.index('--output') + 1], content)
      true
    when 'dnsmasq' then !@fail_validation
    when '/etc/init.d/dnsmasq'
      if @fail_restarts.positive?
        @fail_restarts -= 1
        false
      else
        true
      end
    when 'crontab'
      if @fail_cron.to_i.positive?
        @fail_cron -= 1
        false
      else
        true
      end
    when 'logger' then true
    else raise "unexpected command: #{argv.inspect}"
    end
  end

  def signal_dnsmasq(_context)
    @signals += 1
    true
  end

  def running?(_context)
    true
  end

  def installed_script?
    true
  end

  def log(message)
    @messages << message
  end

  def select(ids, matching: 'all', custom_url: 'https://fixture.test/custom')
    files = {
      'custom-hosts' => 'Custom_Hosts.conf', 'github520' => 'GitHub520_Hosts.conf', 'anti-ad' => 'Anti_AD_Dnsmasq.conf',
      'adblockfilters-hosts' => 'Adblockfilters_Hosts.conf', 'adblockfilters-dnsmasq' => 'Adblockfilters_Dnsmasq.conf'
    }
    @sections = ids.map do |id|
      "config config_overwrite\noption name '#{files.fetch(id)}'\noption enable '1'\nlist config '#{matching}'\noption param 'EN_KEY1=#{custom_url}'\n"
    end
  end

  def output(name)
    target = path("/tmp/dnsmasq.cfg0.d/#{name}")
    File.file?(target) ? File.read(target) : nil
  end
end

def check(condition, label)
  raise label unless condition
end

def refuses(label)
  begin
    yield
  rescue StandardError
    return
  end
  raise "accepted unsafe input: #{label}"
end

def fixture
  Dir.mktmpdir('codex-dnsmasq-rules-test-') do |root|
    %w[/etc/openclash/custom /etc/openclash/overwrite /etc/crontabs /tmp/etc /tmp/dnsmasq.cfg0.d].each { |dir| FileUtils.mkdir_p("#{root}#{dir}") }
    File.write("#{root}/tmp/etc/dnsmasq.conf.cfg0", "conf-dir=/tmp/dnsmasq.cfg0.d\n")
    File.write("#{root}/etc/openclash/custom/openclash_custom_overwrite.sh", "#!/bin/sh\n# Existing user script\nexit 0\n")
    File.write("#{root}/etc/crontabs/root", "13 2 * * * /usr/bin/existing-job # keep\n")
    Dir.glob(File.expand_path('../overwrite/adblock/*.conf', __dir__)).each { |file| FileUtils.cp(file, "#{root}/etc/openclash/overwrite/") }
    component = FixtureRules.new(root: root)
    component.downloads = {
      'https://fixture.test/custom' => "127.0.0.1 localhost\n0.0.0.0 githubassets.com\n192.0.2.10 github.com\n192.0.2.11 github.com\n192.0.2.12 dual.example\n2001:db8::12 dual.example\n192.0.2.13 ads.example\n",
      'https://raw.hellogithub.com/hosts' => "192.0.2.50 github.com\n192.0.2.51 githubassets.com\n192.0.2.52 child.parent.blocked\n",
      'https://anti-ad.net/anti-ad-for-dnsmasq.conf' => "address=/ads.example/\naddress=/parent.blocked/\naddress=/child.parent.blocked/\n",
      'https://gcore.jsdelivr.net/gh/217heidai/adblockfilters@main/rules/adblockhosts.txt' => "127.0.0.1 localhost\n::1 ip6-localhost\nfe80::1%lo0 localhost\n0.0.0.0 ads.example\n0.0.0.0 hosts-only.example\n",
      'https://gcore.jsdelivr.net/gh/217heidai/adblockfilters@main/rules/adblockdnsmasq.txt' => "local=/ads.example/\nlocal=/dns-only.example/\n"
    }
    yield component, root
  end
end

check(DnsmasqRules.words("option param 'EN_KEY1=https://example.test/?a=b&c=d'") == ['option', 'param', 'EN_KEY1=https://example.test/?a=b&c=d'], 'UCI URL parsing')
check(DnsmasqRules.words("option value 'can'\\''t'") == ['option', 'value', "can't"], 'UCI apostrophe escaping')
%w[:: ::1 2001:db8::12 0:0:0:0:0:0:0:1 ::ffff:192.0.2.1].each { |ip| check(DnsmasqRules.ip_family(ip) == 6, "valid IPv6 #{ip}") }
%w[1::2: :1::2 1:::2 ::: : 1:2:3:4:5:6:7:8:9 ::ffff:999.0.0.1].each { |ip| check(DnsmasqRules.ip_family(ip).nil?, "invalid IPv6 #{ip}") }
%w[0.0.0.0 127.0.0.1 :: ::1 0:0:0:0:0:0:0:1 0000:0:0:0:0:0:0:0 ::ffff:0.0.0.0 ::ffff:127.0.0.1].each do |ip|
  check(DnsmasqRules.blocking_ip?(ip), "recognize blocking IP #{ip}")
end
%w[192.0.2.1 2001:db8::1 ::ffff:192.0.2.1].each { |ip| check(!DnsmasqRules.blocking_ip?(ip), "retain real IP #{ip}") }

fixture do |component, root|
  context = component.dnsmasq_context
  check(context['pidfile'] == '/var/run/dnsmasq/dnsmasq.cfg0.pid', 'OpenWrt procd PID file fallback')
  FileUtils.mkdir_p(root + '/var/run/dnsmasq')
  FileUtils.mkdir_p(root + '/proc/12345')
  File.write(root + context['pidfile'], '12345')
  File.write(root + '/proc/12345/comm', "dnsmasq\n")
  File.binwrite(root + '/proc/12345/cmdline', "/usr/sbin/dnsmasq\0-C\0#{context['configuration']}\0-k\0")
  check(component.dnsmasq_pid(context) == 12345, 'identify target process by configuration path')
  File.binwrite(root + '/proc/12345/cmdline', "/usr/sbin/dnsmasq\0-C\0/var/etc/dnsmasq.conf.other\0")
  check(component.dnsmasq_pid(context).nil?, 'refuse another dnsmasq instance even with a stale PID file')
  File.write(root + '/proc/12345/comm', "ruby\n")
  check(component.dnsmasq_pid(context).nil?, 'refuse another executable')
  ids = DnsmasqRules::SOURCES.keys
  # Every subset of the five modules, including both adblockfilters formats and all modules together.
  (0...(1 << ids.length)).each do |mask|
    selected = ids.each_with_index.filter_map { |id, index| id if (mask & (1 << index)).positive? }
    component.select(selected)
    component.sync(refresh: true, force: true)
    conf = component.output(DnsmasqRules::CONF_NAME)
    hosts = component.output(DnsmasqRules::HOSTS_NAME)
    if selected.empty?
      check(conf.nil? && hosts.nil?, 'disabling all modules removes managed files')
      next
    end
    check(conf.start_with?(DnsmasqRules::MARKER) && hosts.start_with?(DnsmasqRules::MARKER), 'owned outputs')
    check(!hosts.include?('localhost'), 'preserve local system names')
    check(conf.lines.grep(/^address=/).uniq.length == conf.lines.grep(/^address=/).length, 'deduplicate dnsmasq rules')
    records = hosts.lines.reject { |line| line.start_with?('#') }.map(&:split)
    grouped = records.group_by { |ip, name| [name, DnsmasqRules.ip_family(ip)] }
    check(grouped.values.all? { |rows| rows.length == 1 }, 'one mapping per name and address family')
    if selected.include?('custom-hosts') && selected.include?('github520')
      check(hosts.include?("192.0.2.10 github.com\n") && !hosts.include?('192.0.2.50'), 'custom mapping has priority over GitHub520')
      check(hosts.include?("0.0.0.0 githubassets.com\n") && !hosts.include?('192.0.2.51'), 'block has priority over GitHub520')
    end
    if selected.include?('anti-ad')
      check(!hosts.include?('child.parent.blocked'), 'suffix block prevents child hosts override')
      check(!conf.include?('address=/child.parent.blocked/'), 'compact child suffix block')
    end
    if (selected & %w[anti-ad adblockfilters-dnsmasq]).any?
      check(!hosts.include?(' ads.example'), 'hosts cannot override dnsmasq blocking')
    elsif selected.include?('adblockfilters-hosts')
      check(hosts.include?("0.0.0.0 ads.example\n") && !hosts.include?('192.0.2.13'), 'hosts blocking overrides custom real mapping')
    end
    component.sync
    before = File.stat("#{root}/etc/openclash/dnsmasq-rules/state.yaml")
    service_calls = component.calls.count { |call| call.first == '/etc/init.d/dnsmasq' }
    signals = component.signals
    component.sync
    after = File.stat("#{root}/etc/openclash/dnsmasq-rules/state.yaml")
    check(before.ino == after.ino && before.mtime == after.mtime, 'unchanged polling does not write flash')
    check(service_calls == component.calls.count { |call| call.first == '/etc/init.d/dnsmasq' } && signals == component.signals, 'unchanged polling does not reload services')
  end

  component.select(['custom-hosts'])
  component.sync(refresh: true, force: true)
  old_conf = component.output(DnsmasqRules::CONF_NAME)
  component.downloads['https://fixture.test/custom'] = "192.0.2.20 changed.example\n"
  signals = component.signals
  restarts = component.calls.count { |call| call.first == '/etc/init.d/dnsmasq' }
  component.sync(refresh: true, force: true)
  check(component.signals == signals + 1, 'hosts update uses SIGHUP')
  check(component.calls.count { |call| call.first == '/etc/init.d/dnsmasq' } == restarts, 'hosts update does not restart dnsmasq')
  check(old_conf == component.output(DnsmasqRules::CONF_NAME), 'hosts update keeps loader unchanged')
  File.unlink("#{root}/tmp/dnsmasq.cfg0.d/#{DnsmasqRules::CONF_NAME}")
  component.sync
  check(old_conf == component.output(DnsmasqRules::CONF_NAME), 'restore a loader removed by a service or firmware update')

  saved_stdout = $stdout
  begin
    $stdout = StringIO.new
    component.status
    check(!$stdout.string.include?('https://') && !$stdout.string.include?('url:'), 'status hides source URL tokens')
  ensure
    $stdout = saved_stdout
  end

  saved = component.output(DnsmasqRules::HOSTS_NAME)
  component.fail_download = true
  component.sync(refresh: true, force: true)
  check(saved == component.output(DnsmasqRules::HOSTS_NAME), 'download failure retains validated rules')
  component.fail_download = false
  component.downloads['https://fixture.test/custom'] = '<html>HTTP 200 error page</html>'
  component.sync(refresh: true, force: true)
  check(saved == component.output(DnsmasqRules::HOSTS_NAME), 'HTML response retains validated rules')

  component.select(['anti-ad'])
  component.sync(refresh: true, force: true)
  old_conf = component.output(DnsmasqRules::CONF_NAME)
  component.downloads['https://anti-ad.net/anti-ad-for-dnsmasq.conf'] = "address=/new.example/\n"
  component.fail_restarts = 1
  refuses('service restart failure') { component.sync(refresh: true, force: true) }
  check(old_conf == component.output(DnsmasqRules::CONF_NAME), 'restart failure restores previous configuration')
  component.sync
  check(component.output(DnsmasqRules::CONF_NAME).include?('address=/new.example/'), 'retry applies validated new rules')
  saved_conf = component.output(DnsmasqRules::CONF_NAME)
  component.downloads['https://anti-ad.net/anti-ad-for-dnsmasq.conf'] = "address=/validation.example/\n"
  component.fail_validation = true
  refuses('dnsmasq syntax validation failure') { component.sync(refresh: true, force: true) }
  check(saved_conf == component.output(DnsmasqRules::CONF_NAME), 'failed syntax validation leaves running rules intact')
  component.fail_validation = false

  component.select(['anti-ad'], matching: '/etc/openclash/config/other.yaml')
  component.sync
  check(component.output(DnsmasqRules::CONF_NAME).nil?, 'configuration mismatch removes rules')
  component.select(['anti-ad'])
  component.sync
  component.enabled = false
  component.sync
  check(component.output(DnsmasqRules::CONF_NAME).nil?, 'OpenClash disabled removes rules')
  component.enabled = true
  component.select(['custom-hosts'])
  component.sections += component.sections.map(&:dup)
  before_downloads = component.calls.count { |call| call.first == 'curl' }
  component.sync(refresh: true, force: true)
  check(component.calls.count { |call| call.first == 'curl' } == before_downloads + 1, 'duplicate module uses one source download')
  component.sections.last.sub!('https://fixture.test/custom', 'https://fixture.test/other')
  refuses('conflicting source URLs') { component.sync }
  component.select(['anti-ad'])
  component.dns_mode = '2'
  refuses('DNS mode conflict') { component.sync }
  component.dns_mode = '1'

  hook = "#{root}/etc/openclash/custom/openclash_custom_overwrite.sh"
  cron = "#{root}/etc/crontabs/root"
  original_hook = File.read(hook)
  original_cron = File.read(cron)
  component.fail_cron = 1
  refuses('crontab reload failure') { component.install }
  check(File.read(hook) == original_hook && File.read(cron) == original_cron, 'failed installation restores hook and cron')
  component.install
  first_hook, first_cron = File.read(hook), File.read(cron)
  component.install
  check(File.read(hook) == first_hook && File.read(cron) == first_cron, 'idempotent integration install')
  check(first_hook.index(DnsmasqRules::HOOK_START) < first_hook.index('exit 0'), 'hook runs before existing exit')
  component.sync
  component.fail_restarts = 1
  refuses('uninstall service failure') { component.uninstall }
  check(File.read(hook) == first_hook && File.read(cron) == first_cron, 'failed cleanup retains integration for a retry')
  component.uninstall
  check(File.read(hook) == original_hook && File.read(cron) == original_cron, 'uninstall preserves user hook and unrelated cron')
  check(component.output(DnsmasqRules::CONF_NAME).nil? && component.output(DnsmasqRules::HOSTS_NAME).nil?, 'uninstall removes managed rules')
  check(File.file?("#{root}/etc/openclash/dnsmasq-rules/anti-ad.rules"), 'retain cache for explicit removal')
end

fixture do |component, root|
  component.select(['custom-hosts'])
  input = "#{root}/rules.input"
  output = "#{root}/rules.output"
  ["conf-file=/etc/private\n", "server=/ads.example/192.0.2.1\n", "address=/#/\n", "local=/bad domain/\n"].each do |payload|
    File.write(input, payload)
    refuses(payload) { DnsmasqRules.normalize(input, output, 'anti-ad') }
  end
  ["999.0.0.1 ads.example\n", "0.0.0.0 *.example\n", "0.0.0.0\n", "\xff\n".b].each do |payload|
    File.binwrite(input, payload)
    refuses('malformed hosts') { DnsmasqRules.normalize(input, output, 'custom-hosts') }
  end
  component.sync(refresh: true, force: true)
  component.select(['custom-hosts'], custom_url: 'https://fixture.test/missing')
  component.fail_download = true
  component.sync(refresh: true, force: true)
  check(component.output(DnsmasqRules::CONF_NAME).nil?, 'URL change does not load the old URL cache')
  state = YAML.safe_load(File.read(root + '/etc/openclash/dnsmasq-rules/state.yaml'))
  check(state['active'] == ['custom-hosts'] && state['loaded'].empty?, 'status distinguishes enabled and loaded sources')
  component.select(['custom-hosts'], custom_url: 'http://fixture.test/unsafe')
  refuses('HTTP URL') { component.sync }

  conf = "#{root}/tmp/dnsmasq.cfg0.d/#{DnsmasqRules::CONF_NAME}"
  component.select([])
  File.write(conf, '# user-owned file')
  refuses('foreign file') { component.sync }
  check(File.read(conf) == '# user-owned file', 'foreign file remains untouched')
  File.unlink(conf)
  other = "#{root}/foreign-file"
  File.write(other, 'preserve me')
  File.symlink(other, conf)
  refuses('symlink target') { component.sync }
  check(File.read(other) == 'preserve me', 'symlink target remains untouched')
end

puts 'PASS: all 32 module combinations; validation, precedence, caching, reload, rollback, matching and integration cleanup'
