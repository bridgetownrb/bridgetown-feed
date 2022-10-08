# frozen_string_literal: true

require "bridgetown"
require "fileutils"
require "bridgetown-feed/builder"
require "bridgetown-feed/generator"

Bridgetown.initializer :"bridgetown-feed" do |config|
  config.builder BridgetownFeed::Builder
end
