require 'certified'
require 'open-uri'
require 'Nokogiri'

module Travis
  module Build
    class Script
      module Dotnet
        def get_dotnet_core_sdk_version_latest()
            return extract_latest_sdk_version(get_dotnet_core_download_page_link_latest())
        end

        def get_dotnet_core_sdk_version_preview()
            return extract_latest_sdk_version(get_dotnet_core_download_page_link_preview())
        end

        def get_dotnet_core_version_anchors()
            dotnet_download_archive_page_html = Nokogiri::HTML(open("https://www.microsoft.com/net/download/archives"))
            dotnet_core_version_anchors = dotnet_download_archive_page_html.css('div.container ul li a[@href^="/net/download/dotnet-core"]')
            return dotnet_core_version_anchors
        end

        def get_dotnet_core_download_page_link_latest()
            return "https://www.microsoft.com" + get_dotnet_core_version_anchors[1]['href']
        end

        def get_dotnet_core_download_page_link_preview()
            return "https://www.microsoft.com" + get_dotnet_core_version_anchors[0]['href']
        end

        def extract_latest_sdk_version(dotnet_core_download_page_link)
            html = Nokogiri::HTML(open(dotnet_core_download_page_link))
            id_prefix = 'sdk-'
            return html.css('table.table h3.h5[@id^='+id_prefix+']')[0].attr('id')[id_prefix.length..-1]
        end
      end
    end
  end
end


if __FILE__ == $0
  require "test/unit"
  include Travis::Build::Script::Dotnet

  class TestDotnet < Test::Unit::TestCase

    def test_latest
      o = Travis::Build::Script.new()
      puts o.get_dotnet_core_sdk_version_latest()
    end

    def test_preview
      o = Travis::Build::Script.new()
      puts o.get_dotnet_core_sdk_version_preview()
    end

  end
end
