# frozen_string_literal: true

require "bridgetown"
require "fileutils"
require "bridgetown-feed/generator"

module BridgetownFeed
  autoload :MetaTag,          "bridgetown-feed/meta-tag"
  autoload :PageWithoutAFile, "bridgetown-feed/page-without-a-file.rb"
end

Liquid::Template.register_tag "feed_meta", BridgetownFeed::MetaTag
