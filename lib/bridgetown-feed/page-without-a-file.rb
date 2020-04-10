# frozen_string_literal: true

module BridgetownFeed
  class PageWithoutAFile < Bridgetown::Page
    def read_yaml(*)
      @data ||= {}
    end
  end
end
