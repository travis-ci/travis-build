require 'spec_helper'

describe Travis::Shell::Generator::Bash, :include_node_helpers do
  let(:code) { Travis::Shell::Generator::Bash.new(@sexp).generate }

  describe :script do
    it 'generates each cmd' do
      @sexp = [:script, [[:cmd, 'foo'], [:cmd, 'bar']]]
      expect(code).to eql("travis_cmd foo\ntravis_cmd bar")
    end
  end

  describe :cmd do
    it 'prepends travis_cmd' do
      @sexp = [:cmd, 'foo']
      expect(code).to eql('travis_cmd foo')
    end

    it 'shellescapes the command' do
      @sexp = [:cmd, 'foo bar']
      expect(code).to eql('travis_cmd foo\\ bar')
    end

    it 'adds options' do
      @sexp = [:cmd, 'foo', echo: 'bar']
      expect(code).to eql('travis_cmd foo --echo --display bar')
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
      expect(code).to eql('travis_cmd cd\\ -')
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
      expect(code).to eql('travis_cmd chmod\\ -R\\ 600\\ ./foo')
    end
  end

  describe :chown do
    it 'generates a chown command' do
      @sexp = [:chown, ['travis', './foo'], echo: true]
      expect(code).to eql("travis_cmd chown\\ travis\\ ./foo --echo")
    end

    it 'chowns recursively if :recursive was given' do
      @sexp = [:chown, ['travis', './foo'], recursive: true]
      expect(code).to eql('travis_cmd chown\\ -R\\ travis\\ ./foo')
    end
  end

  describe :echo do
    it 'generates a echo command' do
      @sexp = [:echo, 'Hello.']
      expect(code).to eql("travis_cmd echo\\ -e\\ \\\"Hello.\\\"")
    end

    it 'escapes a message' do
      @sexp = [:echo, 'Hello there.']
      expect(code).to eql("travis_cmd echo\\ -e\\ \\\"Hello\\ there.\\\"")
    end

    it 'adds ansi codes' do
      @sexp = [:echo, 'Hello.', ansi: [:green]]
      expect(code).to eql("travis_cmd echo\\ -e\\ \\\"\\\\033\\[33\\;1mHello.\\\\033\\[0m\\\"")
    end
  end

  describe :newline do
    it 'generates an echo command' do
      @sexp = [:newline]
      expect(code).to eql('travis_cmd echo')
    end
  end

  describe :set do
    it 'sets a variable' do
      @sexp = [:set, ['FOO', 'foo'], echo: true]
      expect(code).to eql("travis_cmd FOO\\=foo --echo")
    end

    it 'adds --display FOO=[secure] if :secure is given' do
      @sexp = [:set, ['FOO', 'foo'], echo: true, secure: true]
      expect(code).to eql("travis_cmd FOO\\=foo --echo --display FOO\\=\\[secure\\]")
    end
  end

  describe :export do
    it 'generates an export command' do
      @sexp = [:export, ['FOO', 'foo'], echo: true]
      expect(code).to eql("travis_cmd export\\ FOO\\=foo --echo")
    end

    it 'adds --display FOO=[secure] if :secure is given' do
      @sexp = [:export, ['FOO', 'foo'], echo: true, secure: true]
      expect(code).to eql("travis_cmd export\\ FOO\\=foo --echo --display FOO\\=\\[secure\\]")
    end
  end

  describe :file do
    it 'generates command to store content to a file' do
      @sexp = [:file, ['./foo', 'bar']]
      expect(code).to eql('travis_cmd echo\\ bar\\ \\>\\ ./foo')
    end

    it 'escapes the content' do
      @sexp = [:file, ['./foo', 'foo bar']]
      expect(code).to eql('travis_cmd echo\\ foo\\\\\\ bar\\ \\>\\ ./foo')
    end

    it 'appends to the file if :append is given' do
      @sexp = [:file, ['./foo', 'bar'], append: true]
      expect(code).to eql('travis_cmd echo\\ bar\\ \\>\\>\\ ./foo')
    end

    it 'base64 decodes the content if :decode is given' do
      @sexp = [:file, ['./foo', 'Zm9vCg=='], decode: true]
      expect(code).to eql('travis_cmd echo\\ Zm9vCg\\\\\\=\\\\\\=\\ \\|\\ base64\\ --decode\\ \\>\\ ./foo')
    end
  end

  describe :rm do
    it 'generates an rm command' do
      @sexp = [:rm, ['./foo']]
      expect(code).to eql('travis_cmd rm\\ ./foo')
    end

    it 'removes recursively if :recursive was given' do
      @sexp = [:rm, ['./foo'], recursive: true]
      expect(code).to eql('travis_cmd rm\\ -r\\ ./foo')
    end

    it 'forces removal if :recursive was given' do
      @sexp = [:rm, ['./foo'], force: true]
      expect(code).to eql('travis_cmd rm\\ -f\\ ./foo')
    end

    it 'handles multiple options correctly' do
      @sexp = [:rm, ['./foo'], force: true, recursive: true]
      expect(code).to eql('travis_cmd rm\\ -rf\\ ./foo')
    end
  end

  describe 'mkdir' do
    it 'generates a mkdir command' do
      @sexp = [:mkdir, ['./foo']]
      expect(code).to eql('travis_cmd mkdir\\ ./foo')
    end

    it 'adds -p if :recursive is given' do
      @sexp = [:mkdir, ['./foo'], recursive: true]
      expect(code).to eql('travis_cmd mkdir\\ -p\\ ./foo')
    end
  end

  describe 'mv' do
    it 'generates a mv command' do
      @sexp = [:mv, ['./foo', './bar']]
      expect(code).to eql('travis_cmd mv\\ ./foo\\ ./bar')
    end
  end

  describe 'cp' do
    it 'generates a cp command' do
      @sexp = [:cp, ['./foo', './bar']]
      expect(code).to eql('travis_cmd cp\\ ./foo\\ ./bar')
    end

    it 'adds -r if :recursive is given' do
      @sexp = [:cp, ['./foo', './bar'], recursive: true]
      expect(code).to eql('travis_cmd cp\\ -r\\ ./foo\\ ./bar')
    end
  end

  describe :fold do
    it 'generates a fold' do
      @sexp = [:fold, 'git', [:cmds, [[:cmd, 'foo'], [:cmd, 'bar']]]]
      expect(code).to eql("travis_fold start git\n  travis_cmd foo\n  travis_cmd bar\ntravis_fold end git")
    end
  end

  describe :if do
    it 'generates an if statement' do
      @sexp = [:if, '-f Gemfile', [:cmds, [[:cmd, 'foo']]]]
      expect(code).to eql("if [[ -f Gemfile ]]; then\n  travis_cmd foo\nfi")
    end

    it 'with an elif branch' do
      @sexp = [:if, '-f Gemfile', [:cmds, [[:cmd, 'foo']]], [:elif, '-f Gemfile.lock', [:cmds, [[:cmd, 'bar']]]]]
      expect(code).to eql("if [[ -f Gemfile ]]; then\n  travis_cmd foo\nelif [[ -f Gemfile.lock ]]; then\n  travis_cmd bar\nfi")
    end

    it 'with an else branch' do
      @sexp = [:if, '-f Gemfile', [:cmds, [[:cmd, 'foo']]], [:else, [:cmds, [[:cmd, 'bar']]]]]
      expect(code).to eql("if [[ -f Gemfile ]]; then\n  travis_cmd foo\nelse\n  travis_cmd bar\nfi")
    end
  end

  describe :nesting do
    it 'generates a fold with an if statement' do
      @sexp = [:fold, 'git', [:cmds, [[:if, '-f Gemfile', [:cmds, [[:cmd, 'foo']]]]]]]
      expect(code).to eql("travis_fold start git\n  if [[ -f Gemfile ]]; then\n    travis_cmd foo\n  fi\ntravis_fold end git")
    end
  end
end
