# frozen_string_literal: true

module BridgetownFeed
  class Builder < Bridgetown::Builder
    include Bridgetown::Filters::URLFilters

    Context = Struct.new(:registers)

    def build
      @context = Context.new({ site: site })
      helper "feed_meta", :generate_link_tag
      liquid_tag "feed_meta", :generate_link_tag
    end

    def generate_link_tag(*)
      attrs = attributes.map { |k, v| %(#{k}="#{v}") }.join(" ")
      tag_output = "<link #{attrs} />"
      tag_output.respond_to?(:html_safe) ? tag_output.html_safe : tag_output
    end

    private

    def config
      @config ||= site.config
    end

    def metadata
      @metadata ||= site.data["site_metadata"]
    end

    def attributes
      {
        type: "application/atom+xml",
        rel: "alternate",
        href: absolute_url(path),
        title: title,
      }.keep_if { |_, v| v }
    end

    def path
      config.dig("feed", "path") || "feed.xml"
    end

    def title
      metadata["title"] || metadata["name"]
    end
  end
end
