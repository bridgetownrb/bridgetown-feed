require "rss/maker"

module BridgetownFeed
  module FeedMaker
    # rubocop:disable Metrics
    def self.make_feed(view:, collection:, category:, xsl:)
      site = view.site

      RSS::Maker.make("2.0") do |maker|
        if xsl
          maker.xml_stylesheets.new_xml_stylesheet do |xss|
            xss.href = "#{site.config.url}/feed.xslt.xml"
            xss.type = "text/xml"
          end
        end

        title = site.metadata.title || site.metadata.name || ""
        title += " | #{collection.capitalize}" if collection != "posts"
        title += " | #{category.capitalize}" if category
        title = view.smartify(title)
        maker.channel.title = title

        description = site.metadata.description || site.metadata.tagline || "RSS Feed"
        maker.channel.description = description if description

        maker.channel.generator = "Bridgetown v#{Bridgetown::VERSION}"
        maker.channel.language = site.config.lang if site.config.lang
        maker.channel.updated = Time.now.to_s
        maker.channel.link = site.config.url

        if site.metadata.author.is_a?(Hash)
          maker.channel.managingEditor =
            "#{site.metadata.author.email || site.metadata.email} (#{site.metadata.author.name})"
        elsif site.metadata.email && site.metadata.author.is_a?(String)
          maker.channel.managingEditor = "#{site.metadata.email} (#{site.metadata.author})"
        elsif site.metadata.email
          maker.channel.managingEditor = site.metadata.email
        end

        maker.channel.categories.new_category { _1.content = category } if category

        feed_limit = if site.config.dig(:feed, :collections) &&
            site.config.feed.collections.is_a?(Hash) && site.config.feed.collections[collection]
                       site.config.feed.collections[collection].post_limit
                     else
                       site.config.dig(:feed, :post_limit) || 10
                     end

        resources = site.collections[collection].resources
        resources = resources.select { _1.data.categories.include?(category) } if category
        resources[0...feed_limit.to_i].each do |resource|
          maker.items.new_item do |item|
            item.link = resource.absolute_url

            item.title = view.strip_html(view.smartify(resource.data.title)) if resource.model.title

            item.description = resource.content_for_rss_feed(maker, view) # resource.content
            item.updated = resource.date

            resource.data.categories&.each do |cat|
              item.categories.new_category { _1.content = cat }
            end

            resource.data.tags&.each do |tag|
              item.categories.new_category { _1.content = tag }
            end

            if resource.data.author
              author = nil
              if resource.data.author.is_a?(String) && site.data.authors
                author = site.data.authors[resource.data.author]
              elsif resource.data.author.is_a?(Hash)
                author = resource.data.author
              end
              item.author = "#{author.email} (#{author.name})" if author
            end
          end
        end
      end
    end
    # rubocop:enable Metrics
  end
end
