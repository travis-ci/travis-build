require 'spec_helper'

describe Travis::Shell::Generator::Bash, :include_node_helpers do
  let(:code) { Travis::Shell::Generator::Bash.new(@sexp).generate }

  describe :script do
    it 'generates each cmd' do
      @sexp = [:script, [[:cmd, 'foo'], [:cmd, 'bar']]]
      expect(code).to eql("foo\nbar")
    end

    it 'raises an exception if the generated code is tainted (leaking secure env vars)' do
      @sexp = [:script, [[:export, ['foo', 'bar'.tap { |value| value.taint }]]]]
      expect { code }.to raise_error(Travis::Shell::Generator::TaintedOutput)
    end
  end

  describe :cmd do
    describe 'without options' do
      it 'does not prepend travis_cmd' do
        @sexp = [:cmd, 'foo']
        expect(code).to eql('foo')
      end

      it 'does not shellescape the command' do
        @sexp = [:cmd, 'foo bar']
        expect(code).to eql('foo bar')
      end
    end

    describe 'with options' do
      it 'prepends travis_cmd' do
        @sexp = [:cmd, 'foo', echo: true]
        expect(code).to eql('travis_cmd foo --echo')
      end

      it 'shellescapes the command' do
        @sexp = [:cmd, 'foo bar', echo: true]
        expect(code).to eql('travis_cmd foo\\ bar --echo')
      end

      it 'adds options' do
        @sexp = [:cmd, 'foo', echo: 'bar']
        expect(code).to eql('travis_cmd foo --echo --display bar')
      end
    end
  end

  describe :cd do
    it 'generates a cd command' do
      @sexp = [:cd, './to/here', echo: true]
      expect(code).to eql('travis_cmd cd\\ ./to/here --echo')
    end

    it 'generates a pushd command if :stack was given' do
      @sexp = [:cd, './to/here', stack: true]
      expect(code).to eql('travis_cmd pushd\\ ./to/here\\ \\&\\>\\ /dev/null')
    end

    it 'uses - as a path if path is :back' do
      @sexp = [:cd, :back]
      expect(code).to eql('cd -')
    end

    it 'generates a popd command if path is :back, and :stack was given' do
      @sexp = [:cd, :back, stack: true]
      expect(code).to eql('travis_cmd popd\\ \\&\\>\\ /dev/null')
    end
  end

  describe :chmod do
    it 'generates a chmod command' do
      @sexp = [:chmod, [600, './foo'], echo: true]
      expect(code).to eql("travis_cmd chmod\\ 600\\ ./foo --echo")
    end

    it 'chmods recursively if :recursive was given' do
      @sexp = [:chmod, [600, './foo'], recursive: true]
      expect(code).to eql('chmod -R 600 ./foo')
    end
  end

  describe :chown do
    it 'generates a chown command' do
      @sexp = [:chown, ['travis', './foo'], echo: true]
      expect(code).to eql("travis_cmd chown\\ travis\\ ./foo --echo")
    end

    it 'chowns recursively if :recursive was given' do
      @sexp = [:chown, ['travis', './foo'], recursive: true]
      expect(code).to eql('chown -R travis ./foo')
    end
  end

  describe :echo do
    it 'generates a echo command' do
      @sexp = [:echo, 'Hello.']
      expect(code).to eql("echo -e \"Hello.\"")
    end

    it 'escapes a message' do
      @sexp = [:echo, 'Hello there.']
      expect(code).to eql("echo -e \"Hello there.\"")
    end

    it 'adds ansi codes' do
      @sexp = [:echo, 'Hello.', ansi: [:green]]
      expect(code).to eql("echo -e \"\\033[32;1mHello.\\033[0m\"")
    end

    it 'generates multiple commands when given an array' do
      @sexp = [:echo, ['Hello there.', 'Goodbye!']]
      expect(code).to eql("echo -e \"Hello there.\"\necho -e \"Goodbye!\"")
    end

    it 'generates a plain echo command when given an empty string' do
      @sexp = [:echo, ['']]
      expect(code).to eql('echo')
    end

    it 'generates the expected echo command when given a newline char' do
      @sexp = [:echo, ["\n"]]
      expect(code).to eql('echo')
    end
  end

  describe :newline do
    it 'generates an echo command' do
      @sexp = [:newline]
      expect(code).to eql('echo')
    end
  end

  describe :export do
    it 'generates an export command' do
      @sexp = [:export, ['FOO', 'foo'], echo: true]
      expect(code).to eql("travis_cmd export\\ FOO\\=foo --echo")
    end

    it 'adds --display FOO=[secure] if the given value is tainted' do
      @sexp = [:export, ['FOO', 'foo'], echo: true, secure: true]
      expect(code).to eql("travis_cmd export\\ FOO\\=foo --echo --display export\\ FOO\\=\\[secure\\] --secure")
    end
  end

  describe :file do
    it 'generates command to store content to a file' do
      @sexp = [:file, ['foo', 'bar']]
      expect(code).to match(/^echo bar > foo/)
    end

    it 'appends to the file if :append is given' do
      @sexp = [:file, ['foo', 'bar'], append: true]
      expect(code).to match(/^echo bar >> foo/)
    end

    it 'base64 decodes the content if :decode is given' do
      @sexp = [:file, ['./foo', 'Zm9vCg=='], decode: true]
      expect(code).to match(/^echo Zm9vCg\\=\\= | base64 --decode > foo/)
    end
  end

  describe :rm do
    it 'generates an rm command' do
      @sexp = [:rm, ['./foo']]
      expect(code).to eql('rm ./foo')
    end

    it 'removes recursively if :recursive was given' do
      @sexp = [:rm, ['./foo'], recursive: true]
      expect(code).to eql('rm -r ./foo') # TODO
    end

    it 'forces removal if :recursive was given' do
      @sexp = [:rm, ['./foo'], force: true]
      expect(code).to eql('rm -f ./foo') # TODO
    end

    it 'handles multiple options correctly' do
      @sexp = [:rm, ['./foo'], force: true, recursive: true]
      expect(code).to eql('rm -rf ./foo') # TODO
    end
  end

  describe 'mkdir' do
    it 'generates a mkdir command' do
      @sexp = [:mkdir, ['./foo']]
      expect(code).to eql('mkdir ./foo')
    end

    it 'adds -p if :recursive is given' do
      @sexp = [:mkdir, ['./foo'], recursive: true]
      expect(code).to eql('mkdir -p ./foo') # TODO
    end
  end

  describe 'mv' do
    it 'generates a mv command' do
      @sexp = [:mv, ['./foo', './bar']]
      expect(code).to eql('mv ./foo ./bar')
    end
  end

  describe 'cp' do
    it 'generates a cp command' do
      @sexp = [:cp, ['./foo', './bar']]
      expect(code).to eql('cp ./foo ./bar')
    end

    it 'echoes if :echo is given' do
      @sexp = [:cp, ['./foo', './bar'], echo: true]
      expect(code).to eql('travis_cmd cp\\ ./foo\\ ./bar --echo')
    end

    it 'adds -r if :recursive is given' do
      @sexp = [:cp, ['./foo', './bar'], recursive: true]
      expect(code).to eql('cp -r ./foo ./bar') # TODO
    end
  end

  describe :fold do
    it 'generates a fold' do
      @sexp = [:fold, 'git', [:cmds, [[:cmd, 'foo'], [:cmd, 'bar']]]]
      expect(code).to eql("travis_fold start git\n  foo\n  bar\ntravis_fold end git")
    end
  end

  describe :trace do
    it 'generates a trace' do
      @sexp = [:trace, 'foo', [[:cmd, 'foo']]]
      expect(code).to match(/^travis_trace_span \\{[^\}]+\\}\nfoo\ntravis_trace_span \\{[^\}]+\\}$/)
    end

    it 'with multiple traces' do
      @sexp = [:cmds, [
        [:trace, 'foo', [[:cmd, 'foo']]],
        [:trace, 'bar', [[:cmd, 'bar']]],
      ]]
      expect(code).to match(/^travis_trace_span \\{[^\}]+\\}\n  foo\n  travis_trace_span \\{[^\}]+\\}\n  travis_trace_span \\{[^\}]+\\}\n  bar\n  travis_trace_span \\{[^\}]+\\}$/)
    end

    it 'with nested traces' do
      @sexp = [:trace, 'root', [[:cmds, [
        [:trace, 'foo', [[:cmd, 'foo']]],
      ]]]]
      expect(code).to match(/^travis_trace_span \\{[^\}]+\\}\n  travis_trace_span \\{[^\}]+\\}\n  foo\n  travis_trace_span \\{[^\}]+\\}\ntravis_trace_span \\{[^\}]+\\}$/)
    end
  end

  describe :if do
    describe 'given bash conditions' do
      it 'generates an if statement' do
        @sexp = [:if, '-f Gemfile', [:cmds, [[:cmd, 'foo']]]]
        expect(code).to eql("if [[ -f Gemfile ]]; then\n  foo\nfi")
      end

      it 'with an elif branch' do
        @sexp = [:if, '-f Gemfile', [:cmds, [[:cmd, 'foo']]], [:elif, '-f Gemfile.lock', [:cmds, [[:cmd, 'bar']]]]]
        expect(code).to eql("if [[ -f Gemfile ]]; then\n  foo\nelif [[ -f Gemfile.lock ]]; then\n  bar\nfi")
      end
    end

    describe 'given raw sh conditions' do
      it 'generates an if statement' do
        @sexp = [:if, 'grep FOO .bar 2> /dev/null', [:cmds, [[:cmd, 'foo']]], raw: true]
        expect(code).to eql("if grep FOO .bar 2> /dev/null; then\n  foo\nfi")
      end

      it 'with an elif branch' do
        @sexp = [:if, '-f Gemfile', [:cmds, [[:cmd, 'foo']]], [:elif, 'grep FOO .bar 2> /dev/null', [:cmds, [[:cmd, 'bar']]], raw: true]]
        expect(code).to eql("if [[ -f Gemfile ]]; then\n  foo\nelif grep FOO .bar 2> /dev/null; then\n  bar\nfi")
      end
    end

    it 'with an else branch' do
      @sexp = [:if, '-f Gemfile', [:cmds, [[:cmd, 'foo']]], [:else, [:cmds, [[:cmd, 'bar']]]]]
      expect(code).to eql("if [[ -f Gemfile ]]; then\n  foo\nelse\n  bar\nfi")
    end
  end

  describe :nesting do
    it 'generates a fold with an if statement' do
      @sexp = [:fold, 'git', [:cmds, [[:if, '-f Gemfile', [:cmds, [[:cmd, 'foo']]]]]]]
      expect(code).to eql("travis_fold start git\n  if [[ -f Gemfile ]]; then\n    foo\n  fi\ntravis_fold end git")
    end
  end
end
