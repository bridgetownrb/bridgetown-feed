# frozen_string_literal: true

module BridgetownFeed
  class MetaTag < Liquid::Tag
    # Use Bridgetown's native relative_url filter
    include Bridgetown::Filters::URLFilters

    def render(context)
      @context = context
      attrs    = attributes.map { |k, v| %(#{k}="#{v}") }.join(" ")
      "<link #{attrs} />"
    end

    private

    def config
      @config ||= @context.registers[:site].config
    end

    def metadata
      @metadata ||= @context.registers[:site].data["site_metadata"]
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
