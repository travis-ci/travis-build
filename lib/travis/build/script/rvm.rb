module Travis
  module Build
    class Script
      module RVM
        def export
          super
          set 'TRAVIS_RUBY_VERSION', config[:rvm], echo: false
        end

        def setup
          super
          cmd "rvm get latest-minor"
          cmd "rvm use #{ruby_version} --install --binary --fuzzy"
        end

        def announce
          super
          cmd 'ruby --version'
          cmd 'rvm --version'
        end

        private

        def ruby_version
          config[:rvm].to_s.
            gsub(/-(1[89]|2[01])mode$/, '-d\1').
            gsub(/^rbx$/, 'rbx-weekly-d18').
            gsub(/^rbx-d(\d{2})$/, 'rbx-weekly-d\1')
        end
      end
    end
  end
end
