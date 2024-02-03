# frozen_string_literal: true

require_relative "feed_maker"

module BridgetownFeed
  class Generator < Bridgetown::Generator
    priority :lowest

    # Main plugin action, called by Bridgetown-core
    def generate(site)
      @site = site
      collections.each do |name, meta|
        Bridgetown.logger.info "Bridgetown Feed:", "Generating feed for #{name}"
        (meta["categories"] + [nil]).each do |category|
          path = feed_path(collection: name, category: category)
          next if file_exists?(path)

          @site.generated_pages << make_page(path, collection: name, category: category)
        end
      end
    end

    private

    # Returns the plugin's config or an empty hash if not set
    def config
      @config ||= @site.config["feed"] || {}
    end

    # Determines the destination path of a given feed
    #
    # collection - the name of a collection, e.g., "posts"
    # category - a category within that collection, e.g., "news"
    #
    # Will return "/feed.xml", or the config-specified default feed for posts
    # Will return `/feed/category.xml` for post categories
    # WIll return `/feed/collection.xml` for other collections
    # Will return `/feed/collection/category.xml` for other collection categories
    def feed_path(collection: "posts", category: nil)
      prefix = collection == "posts" ? "/feed" : "/feed/#{collection}"
      return "#{prefix}/#{category}.xml" if category

      collections.dig(collection, "path") || "#{prefix}.xml"
    end

    # Returns a hash representing all collections to be processed and their metadata
    # in the form of { collection_name => { categories = [...], path = "..." } }
    def collections
      return @collections if defined?(@collections)

      # TODO: I don't think we need to bother with most of this, due to 
      # Bridgetown 1.x config format

      @collections = if config["collections"].is_a?(Array)
                       config["collections"].to_h { |c| [c, {}] }
                     elsif config["collections"].is_a?(Hash)
                       config["collections"]
                     else
                       {}
                     end

      @collections = normalize_posts_meta(@collections)
      @collections.each_value do |meta|
        meta["categories"] = (meta["categories"] || []).to_set
      end

      @collections
    end

    # Checks if a file already exists in the site source
    def file_exists?(file_path)
      File.exist? @site.in_source_dir(file_path)
    end

    # Generates contents for an RSS feed
    def make_page(file_path, collection: "posts", category: nil)
      # We create a Ruby-based view so that we can generate the feed using Ruby's RSS builder gem 
      rss_feed = Bridgetown::GeneratedPage.new(
        @site, __dir__, "", file_path.sub(%r{.xml$}, ".rb"), from_plugin: true
      )

      # Here's the Ruby code we'll want processed through the template system.
      # Adding the `atom:link` tag here is a little hacky, but there's no simple way to do it
      # through the RSS maker DSL directly.
      rss_feed.content = <<~RUBY
        BridgetownFeed::FeedMaker
          .make_feed(view: self, collection: data.collection, category: data.category, xsl: data.xsl)
          .to_s.sub(%r!</channel>\n</rss>$!, %(  <atom:link href="\#{site.config.url}\#{page.relative_url}" rel="self" type="application/rss+xml" />\n  </channel>\n</rss>))
      RUBY

      # Front-matter setup
      rss_feed.data.layout = "none"
      rss_feed.data.permalink = file_path
      rss_feed.data.sitemap = false
      rss_feed.data.xsl = file_exists?("feed.xslt.xml")
      rss_feed.data.collection = collection
      rss_feed.data.category = category if category

      rss_feed
    end

    # Special case the "posts" collection, which, for ease of use and backwards
    # compatability, can be configured via top-level keys or directly as a collection
    def normalize_posts_meta(hash)
      hash["posts"] ||= {}
      hash["posts"]["path"] ||= config["path"]
      hash["posts"]["categories"] ||= config["categories"]
      config["path"] ||= hash["posts"]["path"]
      hash
    end
  end
end
