CHRUBY_VERSION="0.3.8+travisci"
RUBIES=(~/.rvm/rubies/*)

function chruby_log()
{
	if [[ -t 1 ]]; then
		echo -e "\x1b[1m\x1b[32m>>>\x1b[0m \x1b[1m$1\x1b[0m"
	else
		echo ">>> $1"
	fi
}

function chruby_warn()
{
	if [[ -t 1 ]]; then
		echo -e "\x1b[1m\x1b[33m***\x1b[0m \x1b[1m$1\x1b[0m" >&2
	else
		echo "*** $1" >&2
	fi
}

function chruby_error()
{
	if [[ -t 1 ]]; then
		echo -e "\x1b[1m\x1b[31m!!!\x1b[0m \x1b[1m$1\x1b[0m" >&2
	else
		echo "!!! $1" >&2
	fi
}



function chruby_reset()
{
	[[ -z "$RUBY_ROOT" ]] && return

	PATH=":$PATH:"; PATH="${PATH//:$RUBY_ROOT\/bin:/:}"

	if (( $UID != 0 )); then
		[[ -n "$GEM_HOME" ]] && PATH="${PATH//:$GEM_HOME\/bin:/:}"
		[[ -n "$GEM_ROOT" ]] && PATH="${PATH//:$GEM_ROOT\/bin:/:}"

		GEM_PATH=":$GEM_PATH:"
		[[ -n "$GEM_HOME" ]] && GEM_PATH="${GEM_PATH//:$GEM_HOME:/:}"
		[[ -n "$GEM_ROOT" ]] && GEM_PATH="${GEM_PATH//:$GEM_ROOT:/:}"
		GEM_PATH="${GEM_PATH#:}"; GEM_PATH="${GEM_PATH%:}"
		unset GEM_ROOT GEM_HOME
		[[ -z "$GEM_PATH" ]] && unset GEM_PATH
	fi

	PATH="${PATH#:}"; PATH="${PATH%:}"
	unset RUBY_ROOT RUBY_ENGINE RUBY_VERSION RUBYOPT
	hash -r
}

function chruby_use()
{
	if [[ ! -x "$1/bin/ruby" ]]; then
		echo "chruby: $1/bin/ruby not executable" >&2
		return 1
	fi

	[[ -n "$RUBY_ROOT" ]] && chruby_reset

	export RUBY_ROOT="$1"
	export RUBYOPT="$2"
	export PATH="$RUBY_ROOT/bin:$PATH"

	eval "$("$RUBY_ROOT/bin/ruby" - <<EOF
puts "export RUBY_ENGINE=#{defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'};"
puts "export RUBY_VERSION=#{RUBY_VERSION};"
begin; require 'rubygems'; puts "export GEM_ROOT=#{Gem.default_dir.inspect};"; rescue LoadError; end
EOF
)"
	# "

	if (( $UID != 0 )); then
		export GEM_HOME="$HOME/.gem/$RUBY_ENGINE/$RUBY_VERSION"
		export GEM_PATH="$GEM_HOME${GEM_ROOT:+:$GEM_ROOT}${GEM_PATH:+:$GEM_PATH}"
		export PATH="$GEM_HOME/bin${GEM_ROOT:+:$GEM_ROOT/bin}:$PATH"
	fi
}

function chruby()
{
	if [[ "$1" == "--version" ]]; then
		echo "chruby: $CHRUBY_VERSION"
		return 0
	fi

	local dir match opts version
	version="$1"

	if [[ "$version" =~ -d19$ ]]; then
		opts="--1.9"
		version="${version%%-d19}"
	elif [[ "$version" =~ -19mode$ ]]; then
		opts="--1.9"
		version="${version%%-19mode}"
	elif [[ "$version" =~ -d18 ]]; then
		opts="--1.8"
		version="${version%%-d18}"
	elif [[ "$version" =~ -18mode ]]; then
		opts="--1.8"
		version="${version%%-18mode}"
	fi

	for dir in "${RUBIES[@]}"; do
		dir="${dir%%/}"
		case "${dir##*/}" in
			"$version")	match="$dir" && break ;;
			*"$version"*)
				if [[ $match_exact == "false" ]]; then
					match="$dir"
				fi
				;;
		esac
	done

	if [[ -z "$match" ]]; then
                if [[ "$chruby_attempted_install" == "true" ]]; then
                	chruby_error "unknown Ruby: $version"
                        return 1
                fi

		chruby_log "Couldn't find Ruby $version, attempting download"

                ruby="${version%%-*}" # remove trailing '-*'
                if [[ $ruby == $version ]]; then
                	ruby='ruby'
                fi
                version="${version#$ruby}"
                version="${version#-}"

		case "$ruby" in
			rbx)

				rbx_url="$(curl -s http://binaries.rubini.us/index.txt | grep ubuntu/12.04/x86_64/rubinius-$version | grep -e '\.tar\.bz2$' | tail -n1)"
				wget -O- $rbx_url | tar -jx -C ~/.rvm/rubies
				for d in ~/.rvm/rubies/rubinius/*; do
					mv "$d" "$(dirname "${d/rubinius/rbx}")-$(basename "$d")"
				done
				rmdir ~/.rvm/rubies/rubinius
				;;
			jruby)
				wget -O- http://jruby.org.s3.amazonaws.com/downloads/${version#*-}/jruby-bin-${version}.tar.gz | tar -zx -C ~/.rvm/rubies
				ln -fs jruby ~/.rvm/rubies/jruby-${version#*-}/bin/ruby
				;;
			*)
				wget -O- https://rubies.travis-ci.org/$(lsb_release -is | tr 'A-Z' 'a-z')/$(lsb_release -rs)/$(uname -m)/$ruby-${version}.tar.bz2 | tar -jx -C ~/.rvm/rubies
				;;
		esac

                RUBIES=(~/.rvm/rubies/*)
                chruby_attempted_install=true match_exact=false chruby "$@"

                chruby_log "Installing Rake and Bundler"
                gem install bundler rake
        else
                chruby_use "$match" "$opts"
        fi
}
