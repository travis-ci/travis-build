module Travis
  module Build
    module Repository
      class Github
        include Git, Module.new {
          attr_reader :slug

          def initialize(slug)
            @slug = slug
          end

          def config_url(commit)
            "http://raw.github.com/#{slug}/#{commit}/.travis.yml"
          end

          def source_url
            "git://github.com/#{slug}.git"
          end

          def target_dir
            slug
          end
        }
      end
    end
  end
end
