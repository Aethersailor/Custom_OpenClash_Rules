# Exercise the shipped expressions without downloads or router configuration changes.
# OPENCLASH_YAML_HELPER can point to the installed helper for real validator checks.
require 'yaml'
require ENV['OPENCLASH_YAML_HELPER'] if ENV['OPENCLASH_YAML_HELPER']

ROOT = File.expand_path('..', __dir__)
CODE_ARGUMENTS = {'ruby_edit' => [1, 2], 'ruby_map_edit' => [1, 3]}.freeze

module YAML
  def self.LOG_WARN(message)
    raise message
  end

  def self.LOG_ERROR(message)
    raise message
  end

  def self.LOG_TIP(_message); end
end

def assert_equal(expected, actual, label)
  raise "#{label}: expected #{expected.inspect}, got #{actual.inspect}" unless expected == actual
end

def commands(file)
  section = nil
  File.readlines(file, encoding: 'UTF-8').filter_map do |line|
    line = line.strip
    if line.match?(/^\[[A-Za-z0-9_-]+\]$/)
      section = line
      nil
    elsif section == '[Overwrite]' && !line.empty? && !line.start_with?('#', ';')
      line
    end
  end
end

def parse(line)
  helper = line.split.first
  args = line[helper.length..-1].scan(/"([^"]*)"|'([^']*)'/).map { |double, single| double || single }
  [helper, args]
end

# Ruby <= 3 uses LIT for numbers/regexps; Ruby 4 uses INTEGER/FLOAT/REGX.
# Check both shapes so CI on an older Ruby still detects the portability failure.
def portable?(source)
  stack = [RubyVM::AbstractSyntaxTree.parse(source)]
  until stack.empty?
    node = stack.pop
    next unless node.is_a?(RubyVM::AbstractSyntaxTree::Node)
    return false if [:INTEGER, :FLOAT, :REGX].include?(node.type)
    return false if node.type == :LIT && (node.children.first.is_a?(Numeric) || node.children.first.is_a?(Regexp))
    stack.concat(node.children)
  end
  true
end

assert_equal(false, portable?("items.drop(3)"), 'integer regression')
assert_equal(false, portable?("url.split(/[?#]/, 2)"), 'regexp regression')
assert_equal(true, portable?("items.drop('3'.to_i)"), 'portable integer')
assert_equal(true, portable?("url.split('?').first.to_s.split('#').first.to_s"), 'portable split')

modules = Dir.glob(File.join(ROOT, 'overwrite', '**', '*.conf')).reject do |file|
  file.include?('/archived/') || file.include?('/OpenClash_Overwrite/')
end
assert_equal(24, modules.length, 'module inventory')
modules.each do |file|
  commands(file).each do |line|
    helper, args = parse(line)
    CODE_ARGUMENTS.fetch(helper).each do |index|
      assert_equal(true, portable?(args.fetch(index)), "#{File.basename(file)} Ruby 4 portability")
    end
    if ENV['OPENCLASH_YAML_HELPER']
      parsed = YAML.overwrite_parse_line(line)
      raise "OpenClash rejected #{file}" if parsed.nil? || YAML.overwrite_unsafe?(*parsed)
    end
  end
end

def apply(name, value)
  line = commands(File.join(ROOT, 'overwrite', name)).first
  helper, args = parse(line)
  assert_equal('ruby_edit', helper, name)
  if ENV['OPENCLASH_YAML_HELPER']
    ENV['CONFIG_FILE'] = '/tmp/cocr-test.yaml'
    YAML.overwrite_apply_line(value, name, line)
  else
    context = Module.new
    context.const_set(:Value, value)
    context.module_eval("Value#{args[1]} = #{args[2]}")
  end
  value
end

providers = {
  'ip' => {'behavior' => ' IPCIDR '},
  'domain' => {'behavior' => 'domain'},
  'classical' => {'behavior' => 'classical'},
  'invalid' => 'invalid'
}
rules = [
  'IP-CIDR,192.0.2.0/24,DIRECT',
  'IP-CIDR6,2001:db8::/32,DIRECT',
  'GEOIP,CN,DIRECT',
  'RULE-SET,ip,DIRECT',
  'IP-CIDR,198.51.100.0/24,DIRECT,no-resolve',
  'IP-CIDR,203.0.113.0/24,DIRECT,src',
  'GEOIP,CN,DIRECT,SRC',
  'RULE-SET,domain,DIRECT', 'RULE-SET,classical,DIRECT',
  'RULE-SET,missing,DIRECT', 'RULE-SET,invalid,DIRECT',
  'AND,((NETWORK,UDP),(DST-PORT,443)),REJECT',
  'SRC-IP-CIDR,192.0.2.0/24,DIRECT', 'IP-CIDR,broken',
  'GEOIP,US,DIRECT,extra', 'MATCH,DIRECT', nil
]
expected = rules.each_with_index.map do |rule, index|
  [0, 1, 2, 3, 14].include?(index) ? rule.split(',').insert(3, 'no-resolve').join(',') : rule
end
config = {'rules' => rules.dup, 'rule-providers' => providers, 'sub-rules' => {'nested' => rules.dup, 'invalid' => nil}}
apply('Add_No_Resolve.conf', config)
assert_equal(expected, config['rules'], 'no-resolve rules')
assert_equal(expected, config['sub-rules']['nested'], 'no-resolve sub-rules')
assert_equal(nil, config['sub-rules']['invalid'], 'invalid sub-rules unchanged')
assert_equal(providers, config['rule-providers'], 'providers unchanged')
assert_equal(config, apply('Add_No_Resolve.conf', Marshal.load(Marshal.dump(config))), 'no-resolve idempotence')
assert_equal({'rules' => nil}, apply('Add_No_Resolve.conf', {'rules' => nil}), 'missing rules')
assert_equal(['GEOIP,CN,DIRECT,no-resolve'], apply('Add_No_Resolve.conf', {'rules' => ['GEOIP,CN,DIRECT']})['rules'], 'missing providers')

formats = {
  'remote' => {'url' => 'https://example.com/IP.MRS?token=a#b', 'path' => './ip.yaml', 'format' => 'yaml', 'behavior' => 'ipcidr'},
  'file' => {'type' => 'file', 'path' => './RULES.YML', 'url' => 'https://example.com/rules.mrs', 'format' => 'mrs'},
  'fallback' => {'url' => 'https://example.com/download?file=rules.mrs', 'path' => './rules.yaml'},
  'fragment' => {'url' => 'https://example.com/rules.yaml#fragment?query'},
  'unknown' => {'url' => 'https://example.com/rules.txt', 'format' => 'text'},
  'empty' => {'url' => '', 'path' => nil}, 'invalid' => 'unchanged'
}
original = Marshal.load(Marshal.dump(formats))
config = apply('Rule_Provider_Format_Fix.conf', {'rule-providers' => formats})
{'remote' => 'mrs', 'file' => 'yaml', 'fallback' => 'yaml', 'fragment' => 'yaml', 'unknown' => 'text'}.each do |key, format|
  assert_equal(format, config['rule-providers'][key]['format'], "format #{key}")
end
formats.each_key do |key|
  current = config['rule-providers'][key]
  assert_equal(original[key].reject { |field, _| field == 'format' }, current.reject { |field, _| field == 'format' }, "preserve #{key}") if current.is_a?(Hash)
end
assert_equal(original['invalid'], config['rule-providers']['invalid'], 'invalid provider')
assert_equal(config, apply('Rule_Provider_Format_Fix.conf', Marshal.load(Marshal.dump(config))), 'format idempotence')
assert_equal({'rule-providers' => nil}, apply('Rule_Provider_Format_Fix.conf', {'rule-providers' => nil}), 'missing providers')

config = {
  'rules' => ['GEOIP,CN,DIRECT', 'FINAL,DIRECT'],
  'sub-rules' => {'nested' => ['RULE-SET,ip,DIRECT']}, 'rule-providers' => providers,
  'dns' => {'nameserver' => ['system', 'system://', 'https://1.1.1.1/dns-query'], 'default-nameserver' => ['1.1.1.1']},
  'proxy-groups' => [{'name' => 'Existing', 'type' => 'select', 'proxies' => ['DIRECT']}]
}
apply('Prevent_DNS_Leak.conf', config)
assert_equal(['GEOIP,CN,DIRECT,no-resolve', 'MATCH,COCR-DNS-Leak-Guard'], config['rules'], 'guard rules')
assert_equal(['RULE-SET,ip,DIRECT,no-resolve'], config['sub-rules']['nested'], 'guard sub-rules')
assert_equal(['https://1.1.1.1/dns-query'], config['dns']['nameserver'], 'remove system DNS')
assert_equal(['1.1.1.1'], config['dns']['proxy-server-nameserver'], 'bootstrap DNS')
assert_equal(true, config['dns']['respect-rules'], 'respect rules')
assert_equal(false, config['dns']['prefer-h3'], 'disable HTTP/3 preference')
assert_equal('Existing', config['proxy-groups'].first['name'], 'preserve existing group')
assert_equal('REJECT', config['proxy-groups'].last['empty-fallback'], 'empty guard fallback')
assert_equal(config, apply('Prevent_DNS_Leak.conf', Marshal.load(Marshal.dump(config))), 'guard idempotence')
config['rules'] = []
assert_equal(['MATCH,COCR-DNS-Leak-Guard'], apply('Prevent_DNS_Leak.conf', config)['rules'], 'append missing match')

puts "PASS: #{modules.length} modules; Ruby #{RUBY_VERSION}; rule, provider and DNS guard regressions"
