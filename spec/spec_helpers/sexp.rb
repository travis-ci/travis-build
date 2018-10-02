require 'fileutils'

module SpecHelpers
  module Sexp
    INTEGRATION_MAGIC_COMMENT = "\n\n# TRAVIS-BUILD INTEGRATION EXAMPLE MAGIC COMMENT\n"

    def sexp_fold(fold, sexp)
      [:fold, fold, [:cmds, [sexp]]]
    end

    def sexp_includes?(sexp, part)
      if sexp_matches?(sexp, part) || sexp.include?(part)
        true
      elsif sexp.is_a?(Array)
        case sexp.first
        when Array
          sexp.detect { |sexp| sexp_includes?(sexp, part) }
        when :script, :cmds, :then, :else
          sexp_includes?(sexp[1], part)
        when :fold
          sexp_includes?(sexp[2], part)
        when :if, :elif
          sexp_includes?(sexp[2..-1], part)
        end
      else
        false
      end
    end

    def sexp_find(sexp, *parts)
      parts.inject(sexp) { |sexp, part| sexp_filter(sexp, part).first } || []
    end

    def sexp_filter(sexp, part, result = [])
      return result unless sexp.is_a?(Array)
      result << sexp if sexp_matches?(sexp[0, part.length], part)
      sexp.each { |sexp| sexp_filter(sexp, part, result) }
      result || []
    end

    def sexp_matches?(sexp, part)
      return false unless sexp[0] == part[0]
      return false unless sexp[2] == part[2] || [:any_options, :*].include?(part[2])
      lft, rgt = sexp[1], part[1]
      lft.is_a?(String) && rgt.is_a?(Regexp) ? lft =~ rgt : sexp == part
    end

    def store_example(name: nil, integration: false)
      if described_class < Travis::Build::Script
        code = script.compile
      else
        code = Travis::Shell.generate(subject)
      end

      SpecHelpers.top.join('examples').mkpath

      bash_script_path(name: name, integration: integration).open('w+') do |f|
        code += INTEGRATION_MAGIC_COMMENT if integration
        f.write(code)
      end
    end

    def bash_script_path(name: nil, integration: false)
      const_name = described_class
        .name
        .split('::')
        .last
        .gsub(/([A-Z]+)/, '_\1')
        .gsub(/^_/, '')
        .downcase

      name_suffix = [
        const_name,
        name,
        integration ? 'integration' : nil
      ].compact
        .join('-')
        .gsub(' ', '_')

      type = :addon
      type = :build if described_class < Travis::Build::Script

      SpecHelpers.top.join("examples/#{type}-#{name_suffix}.bash.txt")
    end
  end
end
