module SpecHelpers
  CONST = {}

  def replace_consts
    replace_const 'Travis::Build::Script::TEMPLATES_PATH', 'spec/templates'
    # replace_const 'Travis::Build::LOGS', { build: 'build.log', state: 'state.log' }
    replace_const 'Travis::Build::LOGS', {}
    replace_const 'Travis::Build::HOME_DIR', '.'
    replace_const 'Travis::Build::BUILD_DIR', './tmp'
  end

  def replace_const(const, value)
    CONST[const] = eval(const).dup
    eval "#{const}.replace(#{value.inspect})"
  end

  def restore_consts
    CONST.each do |name, value|
      eval "#{name}.replace(#{value.inspect})"
    end
  end

  def executable(name)
    file(name, "builtin echo #{name} $@;")
    FileUtils.chmod('+x', "tmp/#{name}")
  end

  def file(name, content = '')
    path = "tmp/#{name}"
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w+') { |f| f.write(content) }
  end

  def directory(name)
    path = "tmp/#{name}"
    FileUtils.mkdir_p(path)
  end

  def gemfile(name)
    file(name)
    data['config']['gemfile'] = name
  end

  def store_example(name = nil)
    restore_consts
    name = [described_class.name.split('::').last.gsub(/([A-Z]+)/,'_\1').gsub(/^_/, '').downcase, name].compact.join('_').gsub(' ', '_')
    script = described_class.new(data, options).compile
    File.open("examples/build_#{name}.sh", 'w+') { |f| f.write(script) }
  end
end


