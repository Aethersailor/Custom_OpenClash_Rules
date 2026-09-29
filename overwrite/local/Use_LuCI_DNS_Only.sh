#!/bin/sh

# OpenClash local custom-overwrite hook.
# Install this file under /etc/openclash/custom/ and call it from
# openclash_custom_overwrite.sh with the current CONFIG_FILE as its only argument.

LOG_FILE="${LOG_FILE:-/tmp/openclash.log}"
CONFIG_FILE="$1"

if [ -z "$CONFIG_FILE" ] || [ ! -f "$CONFIG_FILE" ]; then
  printf '%s\n' "Use LuCI DNS Only refused: config file is missing" >> "$LOG_FILE"
  exit 1
fi

export CONFIG_FILE

ruby -ryaml -rYAML -I "/usr/share/openclash" -E UTF-8 <<'RUBY' >> "$LOG_FILE" 2>&1
begin
  config_path = ENV.fetch('CONFIG_FILE')

  uci_get = lambda do |key, default_value|
    value = %x{uci -q get openclash.@overwrite[0].#{key} 2>/dev/null || uci -q get openclash.config.#{key} 2>/dev/null}.strip
    value.empty? ? default_value : value
  end

  load_yaml = lambda do |path|
    YAML.load_file(path)
  rescue StandardError
    nil
  end

  list_from = lambda do |path, key|
    data = load_yaml.call(path)
    data.is_a?(Hash) && data[key].is_a?(Array) ? data[key].map(&:to_s).reject(&:empty?).uniq : []
  end

  redirect_dns = uci_get.call('enable_redirect_dns', '1') == '1'
  clean_list = lambda do |items|
    values = items.to_a.map(&:to_s).reject(&:empty?)
    redirect_dns ? values.reject { |item| item.match?(/^system($|:\/\/)/) }.uniq : values.uniq
  end

  clean_policy = lambda do |policy|
    result = policy.is_a?(Hash) ? policy.transform_values { |value| value.is_a?(Array) ? value.dup : value } : {}
    if redirect_dns
      result.keys.each do |key|
        value = result[key]
        if value.is_a?(Array)
          value = value.map(&:to_s).reject { |item| item.match?(/^system($|:\/\/)/) }.uniq
          value.empty? ? result.delete(key) : result[key] = value
        elsif value.to_s.match?(/^system($|:\/\/)/)
          result.delete(key)
        end
      end
    end
    result
  end

  value = YAML.load_file(config_path)
  raise 'config root must be a mapping' unless value.is_a?(Hash)

  current_dns = value['dns'].is_a?(Hash) ? value['dns'] : {}
  nameservers = clean_list.call(list_from.call('/tmp/yaml_config.namedns.yaml', 'nameserver'))
  fallback = clean_list.call(list_from.call('/tmp/yaml_config.falldns.yaml', 'fallback'))
  default_nameservers = clean_list.call(list_from.call('/tmp/yaml_config.defaultdns.yaml', 'default-nameserver'))
  proxy_nameservers = clean_list.call(list_from.call('/tmp/yaml_config.proxynamedns.yaml', 'proxy-server-nameserver'))
  direct_nameservers = clean_list.call(list_from.call('/tmp/yaml_config.directnamedns.yaml', 'direct-nameserver'))

  if uci_get.call('append_default_dns', '0') == '1'
    domain_server = /^dhcp:\/\/|^system($|:\/\/)|([0-9a-zA-Z-]{1,}\.)+([a-zA-Z]{2,})/
    derived_defaults = (nameservers | fallback).reject { |server| server.match?(domain_server) }
    default_nameservers = (default_nameservers + derived_defaults).uniq
  end

  name_policy_data = load_yaml.call('/etc/openclash/custom/openclash_custom_domain_dns_policy.list')
  name_policy = uci_get.call('custom_name_policy', '0') == '1' ? clean_policy.call(name_policy_data) : {}
  proxy_policy_data = load_yaml.call('/etc/openclash/custom/openclash_custom_proxy_server_dns_policy.list')
  proxy_policy = uci_get.call('custom_proxy_server_policy', '0') == '1' ? clean_policy.call(proxy_policy_data) : {}

  local_exclude = ((Dir.children('/sys/class/net') rescue []) + [
    'h3=', 'skip-cert-verify=', 'ecs=', 'ecs-override=', 'disable-ipv6=',
    'disable-ipv4=', 'disable-qtype-', 'disable-reuse=', 'utun', 'tailscale0',
    'docker0', 'tun163', 'br-lan', 'mihomo'
  ]).uniq.map { |item| Regexp.escape(item) }.join('|')
  proxied_server = /^[^#&]+#(?:(?:#{local_exclude})[^&]*&)*(?:(?!(?:#{local_exclude}))[^&]+)/

  errors = []
  errors << 'Custom DNS Setting is disabled' unless uci_get.call('enable_custom_dns', '0') == '1'
  errors << 'LuCI nameserver is empty' if nameservers.empty?

  fake_mode = current_dns['enhanced-mode'].to_s == 'fake-ip'
  fake_range = uci_get.call('fakeip_range', '0')
  errors << 'Fake-IP Range must be set explicitly in LuCI' if fake_mode && (fake_range.empty? || fake_range == '0')

  china_bypass = uci_get.call('china_ip_route', '0') != '0' || uci_get.call('china_ip6_route', '0') != '0'
  custom_fake_filter = uci_get.call('custom_fakeip_filter', '0') == '1'
  errors << 'China bypass in Fake-IP mode requires Custom Fake-IP-Filter' if fake_mode && china_bypass && !custom_fake_filter

  routed_nameservers = !nameservers.empty? && nameservers.all? { |server| server.match?(proxied_server) }
  proxy_required = current_dns['respect-rules'] == true || routed_nameservers || !proxy_policy.empty?
  errors << 'proxy-server-nameserver must be set explicitly in LuCI' if proxy_required && proxy_nameservers.empty?
  errors << 'proxy-server-nameserver needs at least one ungrouped server' if !proxy_nameservers.empty? && proxy_nameservers.all? { |server| server.match?(proxied_server) }

  unless errors.empty?
    YAML.LOG_ERROR('Use LuCI DNS Only refused: %s' % [errors.join('; ')])
    exit 1
  end

  rebuilt = {}
  ['enable', 'ipv6', 'enhanced-mode', 'listen', 'respect-rules'].each do |key|
    rebuilt[key] = current_dns[key] if current_dns.key?(key)
  end
  rebuilt['nameserver'] = nameservers
  rebuilt['fallback'] = fallback unless fallback.empty?
  rebuilt['default-nameserver'] = default_nameservers unless default_nameservers.empty?
  rebuilt['proxy-server-nameserver'] = proxy_nameservers unless proxy_nameservers.empty?
  rebuilt['direct-nameserver'] = direct_nameservers unless direct_nameservers.empty?
  rebuilt['nameserver-policy'] = name_policy unless name_policy.empty?
  rebuilt['proxy-server-nameserver-policy'] = proxy_policy unless proxy_policy.empty?

  if uci_get.call('custom_fallback_filter', '0') == '1' && !fallback.empty?
    fallback_filter_data = load_yaml.call('/etc/openclash/custom/openclash_custom_fallback_filter.yaml')
    fallback_filter = fallback_filter_data.is_a?(Hash) ? fallback_filter_data['fallback-filter'] : nil
    rebuilt['fallback-filter'] = fallback_filter if fallback_filter.is_a?(Hash)
  end

  if fake_mode
    rebuilt['fake-ip-range'] = fake_range
    fake_range6 = uci_get.call('fakeip_range6', '0')
    rebuilt['fake-ip-range6'] = fake_range6 if rebuilt['ipv6'] == true && !fake_range6.empty? && fake_range6 != '0'

    if custom_fake_filter
      rebuilt['fake-ip-filter-mode'] = uci_get.call('custom_fakeip_filter_mode', 'blacklist')
      filter_files = [
        '/etc/openclash/custom/openclash_custom_fake_filter.list',
        '/tmp/yaml_openclash_fake_filter_include'
      ]
      filters = filter_files.flat_map do |path|
        File.exist?(path) ? File.readlines(path).map { |line| line.gsub(/#.*$/, '').strip }.reject(&:empty?) : []
      end
      rebuilt['fake-ip-filter'] = filters.uniq unless filters.empty?
    end

    if china_bypass
      filter_mode = rebuilt['fake-ip-filter-mode']
      filters = rebuilt['fake-ip-filter'].to_a
      if filter_mode == 'blacklist' || filter_mode.nil?
        filters << 'rule-set:oc-cn-domain'
      elsif filter_mode == 'whitelist'
        filters.reject! { |filter| filter =~ /(geosite:?|rule-set:?).*(@cn|:cn|,cn|:china)/i }
      elsif filter_mode == 'rule'
        filters.unshift('RULE-SET,oc-cn-domain,real-ip')
      end
      rebuilt['fake-ip-filter'] = filters.uniq unless filters.empty?
    end
  end

  hosts = {}
  if uci_get.call('custom_host', '0') == '1'
    hosts_data = load_yaml.call('/etc/openclash/custom/openclash_custom_hosts.list')
    custom_hosts = hosts_data.is_a?(Hash) && hosts_data['hosts'].is_a?(Hash) ? hosts_data['hosts'] : hosts_data
    hosts.merge!(custom_hosts) if custom_hosts.is_a?(Hash)
  end
  {
    'openwrt.lan' => 'lan',
    'immortalwrt.lan' => 'lan',
    'lede.lan' => 'lan',
    'router.lan' => 'lan'
  }.each { |key, host_value| hosts[key] ||= host_value }
  system_hostname = %x{uci -q get system.@system[0].hostname 2>/dev/null}.strip
  dnsmasq_domain = %x{uci -q get dhcp.@dnsmasq[0].domain 2>/dev/null}.strip
  hosts[system_hostname + '.lan'] ||= 'lan' unless system_hostname.empty?
  hosts[system_hostname + '.' + dnsmasq_domain] ||= 'lan' unless system_hostname.empty? || dnsmasq_domain.empty?

  value['dns'] = rebuilt
  value['hosts'] = hosts
  rebuilt['use-hosts'] = true

  temporary_path = config_path + '.use-luci-dns-only.' + Process.pid.to_s + '.tmp'
  temporary_file = File.open(temporary_path, File::WRONLY | File::CREAT | File::EXCL, 0o600)
  temporary_file.write(YAML.dump(value))
  temporary_file.flush
  temporary_file.fsync
  File.chmod(File.stat(config_path).mode & 0o777, temporary_path)
  temporary_file.close
  File.rename(temporary_path, config_path)
  YAML.LOG_TIP('Use LuCI DNS Only rebuilt DNS from OpenClash settings: nameserver=%d, fallback=%d' % [nameservers.length, fallback.length])
rescue SystemExit
  raise
rescue StandardError => e
  YAML.LOG_ERROR('Use LuCI DNS Only failed: %s' % [e.message])
  exit 1
ensure
  temporary_file.close if defined?(temporary_file) && temporary_file && !temporary_file.closed?
  if defined?(temporary_path) && temporary_path && File.exist?(temporary_path)
    File.delete(temporary_path)
  end
end
RUBY
