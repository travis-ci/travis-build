require 'spec_helper'

describe 'Travis::Shell::Ast', :include_node_helpers do
  describe 'Node' do
    it 'to_sexp returns a sexp (1)' do
      node = create_node(:cmd, 'foo', echo: true)
      sexp = [:cmd, 'foo', echo: true]
      expect(node.to_sexp).to eql(sexp)
    end

    it 'to_sexp returns a sexp (2)' do
      node = create_node(:file, ['./foo', 'content'], append: true)
      sexp = [:file, ['./foo', 'content'], append: true]
      expect(node.to_sexp).to eql(sexp)
    end

    it 'to_sexp returns a sexp (3)' do
      node = create_node(:echo, 'message', ansi: [:yellow])
      sexp = [:echo, 'message', ansi: [:yellow]]
      expect(node.to_sexp).to eql(sexp)
    end
  end

  describe 'Cmds' do
    let(:node) { create_node(:cmds) }

    before :each do
      node.nodes << create_node(:cmd, 'foo')
      node.nodes << create_node(:cmd, 'bar')
    end

    it 'to_sexp returns a sexp' do
      sexp = [:cmds, [[:cmd, 'foo'], [:cmd, 'bar']]]
      expect(node.to_sexp).to eql(sexp)
    end
  end

  describe 'Fold' do
    let(:node) { create_node(:fold, 'fold') }

    before :each do
      node.nodes << create_node(:cmd, 'foo')
      node.nodes << create_node(:cmd, 'bar')
    end

    it 'to_sexp returns a sexp' do
      sexp = [:fold, 'fold', [:cmds, [[:cmd, 'foo'], [:cmd, 'bar']]]]
      expect(node.to_sexp).to eql(sexp)
    end
  end

  describe 'If' do
    let(:node) { create_node(:if, '-f Gemfile') }

    describe 'if' do
      before :each do
        node.nodes << create_node(:cmd, 'foo')
        node.nodes << create_node(:cmd, 'bar')
      end

      it 'to_sexp returns a sexp' do
        sexp = [:if, '-f Gemfile',
          [:then, [:cmds, [[:cmd, 'foo'], [:cmd, 'bar']]]]
        ]
        expect(node.to_sexp).to eql(sexp)
      end
    end

    describe 'if with an else' do
      before :each do
        node.nodes << create_node(:cmd, 'foo')
        add_else(node, ['bar'])
      end

      it 'to_sexp returns a sexp' do
        sexp = [:if, '-f Gemfile',
          [:then, [:cmds, [[:cmd, 'foo']]]],
          [:else, [:cmds, [[:cmd, 'bar']]]]
        ]
        expect(node.to_sexp).to eql(sexp)
      end
    end

    describe 'if with an elif' do
      before :each do
        node.nodes << create_node(:cmd, 'foo')
        add_elif(node, '-f Gemfile.lock', ['bar'])
      end

      it 'to_sexp returns a sexp' do
        sexp = [:if, '-f Gemfile',
          [:then, [:cmds, [[:cmd, 'foo']]]],
          [:elif, '-f Gemfile.lock', [:cmds, [[:cmd, 'bar']]]]
        ]
        expect(node.to_sexp).to eql(sexp)
      end
    end

    describe 'if with two elif' do
      before :each do
        node.nodes << create_node(:cmd, 'foo')
        add_elif(node, '-f Gemfile.lock', ['bar'])
        add_elif(node, '-f Rakefile', ['baz'])
      end

      it 'to_sexp returns a sexp' do
        sexp = [:if, '-f Gemfile',
          [:then, [:cmds, [[:cmd, 'foo']]]],
          [:elif, '-f Gemfile.lock', [:cmds, [[:cmd, 'bar']]]],
          [:elif, '-f Rakefile', [:cmds, [[:cmd, 'baz']]]]
        ]
        expect(node.to_sexp).to eql(sexp)
      end
    end

    describe 'if with an elif and an else' do
      before :each do
        node.nodes << create_node(:cmd, 'foo')
        add_elif(node, '-f Gemfile.lock', ['bar'])
        add_else(node, ['baz'])
      end

      it 'to_sexp returns a sexp' do
        sexp = [:if, '-f Gemfile',
          [:then, [:cmds, [[:cmd, 'foo']]]],
          [:elif, '-f Gemfile.lock', [:cmds, [[:cmd, 'bar']]]],
          [:else, [:cmds, [[:cmd, 'baz']]]]
        ]
        expect(node.to_sexp).to eql(sexp)
      end
    end
  end
end
