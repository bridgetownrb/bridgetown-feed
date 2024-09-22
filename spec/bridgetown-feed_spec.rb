# frozen_string_literal: true

require "spec_helper"

describe(BridgetownFeed) do
  let(:overrides) { {} }
  let(:config) do
    Bridgetown.configuration(Bridgetown::Utils.deep_merge_hashes({
      "full_rebuild" => true,
      "root_dir"     => root_dir,
      "source"       => source_dir,
      "destination"  => dest_dir,
      "show_drafts"  => true,
      "url"          => "http://example.org",
      "collections"  => {
        "my_collection" => { "output" => true },
        "other_things"  => { "output" => false },
      },
    }, overrides)).tap do |conf|
      conf.run_initializers! context: :static
    end
  end
  let(:metadata_overrides) { {} }
  let(:metadata_defaults) do
    {
      "name"         => "My awesome site",
      "author"       => {
        "name" => "Dr. Bridgetown",
      }
    }
  end
  let(:site) { Bridgetown::Site.new(config) }
  let(:contents) { File.read(dest_dir("feed.xml")) }
  let(:context)  { make_context(:site => site) }
  let(:feed_meta) { Liquid::Template.parse("{% feed_meta %}").render!(context, {}) }
  before(:each) do
    metadata = metadata_defaults.merge(metadata_overrides).to_yaml.sub("---\n", "")
    File.write(source_dir("_data/site_metadata.yml"), metadata)
    site.process
    FileUtils.rm(source_dir("_data/site_metadata.yml"))
  end

  it "has no layout" do
    expect(contents).not_to match(%r!\ATHIS IS MY LAYOUT!)
  end

  it "creates a feed.xml file" do
    expect(Pathname.new(dest_dir("feed.xml"))).to exist
  end

  it "doesn't have multiple new lines or trailing whitespace" do
    expect(contents).to_not match %r!\s+\n!
    expect(contents).to_not match %r!\n{2,}!
  end

  it "puts all the posts in the feed.xml file" do
    expect(contents).to match "http://example.org/updates/bridgetown/2014/03/04/march-the-fourth/"
    expect(contents).to match "http://example.org/news/2014/03/02/march-the-second/"
    expect(contents).to match "http://example.org/news/2013/12/12/dec-the-second/"
    expect(contents).to match "http://example.org/2015/08/08/stuck-in-the-middle/"
    expect(contents).to_not match "http://example.org/2016/02/09/a-draft/"
  end

  it "does not include assets or any static files that aren't .html" do
    expect(contents).not_to match "http://example.org/images/hubot.png"
    expect(contents).not_to match "http://example.org/feeds/atom.xml"
  end

  it "preserves linebreaks in preformatted text in posts" do
    expect(contents).to match "Line 1\nLine 2\nLine 3"
  end

  it "supports post author name as an object" do
    expect(contents).to match %r!<author>\s*<name>Ben</name>\s*<email>ben@example\.com</email>\s*<uri>http://ben\.balter\.com</uri>\s*</author>!
  end

  it "supports post author name as a string" do
    expect(contents).to match %r!<author>\s*<name>Pat</name>\s*</author>!
  end

  it "does not output author tag no author is provided" do
    expect(contents).not_to match %r!<author>\s*<name></name>\s*</author>!
  end

  it "does use author reference with data from _data/authors.yml" do
    expect(contents).to match %r!<author>\s*<name>Garth</name>\s*<email>example@mail\.com</email>\s*<uri>http://garthdb\.com</uri>\s*</author>!
  end

  it "converts markdown posts to HTML" do
    expect(contents).to match %r!&lt;p&gt;March the second\!&lt;/p&gt;!
  end

  it "uses last_modified_at where available" do
    expect(contents).to match %r!<updated>2015-05-12T13:27:59\+00:00</updated>!
  end

  it "replaces newlines in posts to spaces" do
    expect(contents).to match '<title type="html">The plugin will properly strip newlines.</title>'
  end

  it "renders Liquid inside posts" do
    expect(contents).to match "Liquid is rendered."
    expect(contents).not_to match "Liquid is not rendered."
  end

  context "images" do
    let(:image1) { 'http://example.org/image.png' }
    let(:image2) { 'https://cdn.example.org/absolute.png?h=188&amp;w=250' }
    let(:image3) { 'http://example.org/object-image.png' }

    it "includes the item image" do
      expect(contents).to include(%(<media:thumbnail xmlns:media="http://search.yahoo.com/mrss/" url="#{image1}" />))
      expect(contents).to include(%(<media:thumbnail xmlns:media="http://search.yahoo.com/mrss/" url="#{image2}" />))
      expect(contents).to include(%(<media:thumbnail xmlns:media="http://search.yahoo.com/mrss/" url="#{image3}" />))
    end

    it "included media content for mail templates (Mailchimp)" do
      expect(contents).to include(%(<media:content medium="image" url="#{image1}" xmlns:media="http://search.yahoo.com/mrss/" />))
      expect(contents).to include(%(<media:content medium="image" url="#{image2}" xmlns:media="http://search.yahoo.com/mrss/" />))
      expect(contents).to include(%(<media:content medium="image" url="#{image3}" xmlns:media="http://search.yahoo.com/mrss/" />))
    end
  end

  context "erb helper" do
    it "outputs link tag" do
      page = site.collections.pages.resources.find { |item| item.data.title == "I'm a page" }
      expect(page.output).to include(%(<link type="application/atom+xml" rel="alternate" href="http://example.org/feed.xml" title="My awesome site" />))
    end
  end

  context "parsing" do
    let(:feed) { RSS::Parser.parse(contents) }

    it "outputs an RSS feed" do
      expect(feed.feed_type).to eql("atom")
      expect(feed.feed_version).to eql("1.0")
      expect(feed.encoding).to eql("UTF-8")
      expect(feed.lang).to be_nil
      expect(feed.valid?).to eql(true)
    end

    it "outputs the link" do
      expect(feed.link.href).to eql("http://example.org/feed.xml")
    end

    it "outputs the generator" do
      expect(feed.generator.content).to eql("Bridgetown")
      expect(feed.generator.version).to eql(Bridgetown::VERSION)
    end

    it "includes the items" do
      expect(feed.items.count).to eql(10)
    end

    it "includes item contents" do
      post = feed.items.last
      expect(post.title.content).to eql("Dec The Second")
      expect(post.link.href).to eql("http://example.org/news/2013/12/12/dec-the-second/")
      expect(post.published.content).to eql(Time.parse("2013-12-12"))
    end

    it "includes the item's excerpt" do
      post = feed.items.last
      expect(post.summary.content).to eql("Foo")
    end

    it "doesn't include the item's excerpt if blank" do
      post = feed.items.first
      expect(post.summary).to be_nil
    end

    it "has the correct item ids" do
      expect(feed.items.first.id.content).to eql("repo://posts.collection/_posts/2016-04-25-author-reference.md")
      expect(feed.items.last.id.content).to eql("https://example.com/foo")
    end

    context "with site.lang set" do
      lang = "en_US"
      let(:overrides) { { "lang" => lang } }
      it "outputs a valid feed" do
        expect(feed.feed_type).to eql("atom")
        expect(feed.feed_version).to eql("1.0")
        expect(feed.encoding).to eql("UTF-8")
        expect(feed.valid?).to eql(true)
      end

      it "outputs the correct language" do
        expect(feed.lang).to eql(lang)
      end

      it "sets the language of entries" do
        post = feed.items.first
        expect(post.lang).to eql(lang)
      end

      it "renders the feed meta" do
        expected = %r!<link href="http://example.org/" rel="alternate" type="text/html" hreflang="#{lang}" />!
        expect(contents).to match(expected)
      end
    end

    context "with site.title set" do
      let(:site_title) { "My Site Title" }
      let(:metadata_overrides) { { "title" => site_title } }

      it "uses site.title for the title" do
        expect(feed.title.content).to eql(site_title)
      end
    end

    context "with site.name set" do
      let(:site_name) { "My Site Name" }
      let(:metadata_overrides) { { "name" => site_name } }

      it "uses site.name for the title" do
        expect(feed.title.content).to eql(site_name)
      end
    end

    context "with site.name and site.title set" do
      let(:site_title) { "My Site Title" }
      let(:site_name) { "My Site Name" }
      let(:metadata_overrides) { { "title" => site_title, "name" => site_name } }

      it "uses site.title for the title, dropping site.name" do
        expect(feed.title.content).to eql(site_title)
      end
    end
  end

  context "smartify" do
    let(:site_title) { "Pat's Site" }
    let(:metadata_overrides) { { "title" => site_title } }
    let(:feed) { RSS::Parser.parse(contents) }

    it "processes site title with SmartyPants" do
      expect(feed.title.content).to eql("Pat’s Site")
    end
  end

  context "validation" do
    it "validates" do
      skip "Typhoeus couldn't find the 'libcurl' module on Windows" if Gem.win_platform?
      # See https://validator.w3.org/docs/api.html
      url = "https://validator.w3.org/feed/check.cgi?output=soap12"
      response = Typhoeus.post(url, :body => { :rawdata => contents }, :accept_encoding => "gzip")
      pending "Something went wrong with the W3 validator" unless response.success?
      result = Nokogiri::XML(response.body)
      result.remove_namespaces!

      result.css("warning").each do |warning|
        # Quiet a warning that results from us passing the feed as a string
        next if warning.css("text").text =~ %r!Self reference doesn't match document location!

        # Quiet expected warning that results from blank summary test case
        next if warning.css("text").text =~ %r!(content|summary) should not be blank!

        # Quiet expected warning about multiple posts with same updated time
        next if warning.css("text").text =~ %r!Two entries with the same value for atom:updated!

        warn "Validation warning: #{warning.css("text").text} on line #{warning.css("line").text} column #{warning.css("column").text}"
      end

      errors = result.css("error").map do |error|
        "Validation error: #{error.css("text").text} on line #{error.css("line").text} column #{error.css("column").text}"
      end

      expect(result.css("validity").text).to eql("true"), errors.join("\n")
    end
  end

  context "with a baseurl" do
    let(:overrides) do
      { "base_path" => "/bass" }
    end

    it "correctly adds the baseurl to the posts" do
      expect(contents).to match "http://example.org/bass/updates/bridgetown/2014/03/04/march-the-fourth/"
      expect(contents).to match "http://example.org/bass/news/2014/03/02/march-the-second/"
      expect(contents).to match "http://example.org/bass/news/2013/12/12/dec-the-second/"
    end

    it "renders the feed meta" do
      expected = 'href="http://example.org/bass/feed.xml"'
      expect(feed_meta).to include(expected)
    end
  end

  context "feed meta" do
    it "renders the feed meta" do
      expected = '<link type="application/atom+xml" rel="alternate" href="http://example.org/feed.xml" title="My awesome site" />'
      expect(feed_meta).to eql(expected)
    end

    context "with a blank site name" do
      let(:config) do
        Bridgetown.configuration(
          "source"      => source_dir,
          "destination" => dest_dir,
          "url"         => "http://example.org"
        )
      end
      let(:metadata_defaults) { {} }

      it "does not output blank title" do
        expect(feed_meta).not_to include("title=")
      end
    end
  end

  context "changing the feed path" do
    let(:overrides) do
      {
        "feed" => {
          "path" => "atom.xml",
        },
      }
    end

    it "should write to atom.xml" do
      expect(Pathname.new(dest_dir("atom.xml"))).to exist
    end

    it "renders the feed meta with custom feed path" do
      expected = 'href="http://example.org/atom.xml"'
      expect(feed_meta).to include(expected)
    end
  end

  context "changing the file path via collection meta" do
    let(:overrides) do
      {
        "feed" => {
          "collections" => {
            "posts" => {
              "path" => "atom.xml",
            },
          },
        },
      }
    end

    it "should write to atom.xml" do
      expect(Pathname.new(dest_dir("atom.xml"))).to exist
    end

    it "renders the feed meta with custom feed path" do
      expected = 'href="http://example.org/atom.xml"'
      expect(feed_meta).to include(expected)
    end
  end

  context "feed stylesheet" do
    it "includes the stylesheet" do
      expect(contents).to include('<?xml-stylesheet type="text/xml" href="http://example.org/feed.xslt.xml"?>')
    end
  end

  context "with site.lang set" do
    let(:overrides) { { "lang" => "en-US" } }

    it "should set the language" do
      expect(contents).to match 'type="text/html" hreflang="en-US" />'
    end
  end

  context "with post.lang set" do
    it "should set the language for that entry" do
      expect(contents).to match '<entry xml:lang="en">'
      expect(contents).to match '<entry>'
    end
  end

  context "categories" do
    context "with top-level post categories" do
      let(:overrides) do
        {
          "feed" => { "categories" => ["news"] },
        }
      end
      let(:news_feed) { File.read(dest_dir("feed/news.xml")) }

      it "outputs the primary feed" do
        expect(contents).to match "http://example.org/updates/bridgetown/2014/03/04/march-the-fourth/"
        expect(contents).to match "http://example.org/news/2014/03/02/march-the-second/"
        expect(contents).to match "http://example.org/news/2013/12/12/dec-the-second/"
        expect(contents).to match "http://example.org/2015/08/08/stuck-in-the-middle/"
        expect(contents).to_not match "http://example.org/2016/02/09/a-draft/"
      end

      it "outputs the category feed" do
        expect(news_feed).to match '<title type="html">My awesome site | News</title>'
        expect(news_feed).to match "http://example.org/news/2014/03/02/march-the-second/"
        expect(news_feed).to match "http://example.org/news/2013/12/12/dec-the-second/"
        expect(news_feed).to_not match "http://example.org/updates/bridgetown/2014/03/04/march-the-fourth/"
        expect(news_feed).to_not match "http://example.org/2015/08/08/stuck-in-the-middle/"
      end
    end

    context "with collection-level post categories" do
      let(:overrides) do
        {
          "feed" => {
            "collections" => {
              "posts" => {
                "categories" => ["news"],
              },
            },
          },
        }
      end
      let(:news_feed) { File.read(dest_dir("feed/news.xml")) }

      it "outputs the primary feed" do
        expect(contents).to match "http://example.org/updates/bridgetown/2014/03/04/march-the-fourth/"
        expect(contents).to match "http://example.org/news/2014/03/02/march-the-second/"
        expect(contents).to match "http://example.org/news/2013/12/12/dec-the-second/"
        expect(contents).to match "http://example.org/2015/08/08/stuck-in-the-middle/"
        expect(contents).to_not match "http://example.org/2016/02/09/a-draft/"
      end

      it "outputs the category feed" do
        expect(news_feed).to match '<title type="html">My awesome site | News</title>'
        expect(news_feed).to match "http://example.org/news/2014/03/02/march-the-second/"
        expect(news_feed).to match "http://example.org/news/2013/12/12/dec-the-second/"
        expect(news_feed).to_not match "http://example.org/updates/bridgetown/2014/03/04/march-the-fourth/"
        expect(news_feed).to_not match "http://example.org/2015/08/08/stuck-in-the-middle/"
      end
    end
  end

  context "collections" do
    let(:collection_feed) { File.read(dest_dir("feed/collection.xml")) }

    context "when initialized as an array" do
      let(:overrides) do
        {
          "collections" => {
            "collection" => {
              "output" => true,
            },
          },
          "feed"        => { "collections" => ["collection"] },
        }
      end

      it "outputs the collection feed" do
        expect(collection_feed).to match '<title type="html">My awesome site | Collection</title>'
        expect(collection_feed).to match "http://example.org/collection/collection-doc/"
        expect(collection_feed).to match "http://example.org/collection/collection-category-doc/"
        expect(collection_feed).to_not match "http://example.org/updates/bridgetown/2014/03/04/march-the-fourth/"
        expect(collection_feed).to_not match "http://example.org/2015/08/08/stuck-in-the-middle/"
      end
    end

    context "with categories" do
      let(:overrides) do
        {
          "collections" => {
            "collection" => {
              "output" => true,
            },
          },
          "feed"        => {
            "collections" => {
              "collection" => {
                "categories" => ["news"],
              },
            },
          },
        }
      end
      let(:news_feed) { File.read(dest_dir("feed/collection/news.xml")) }

      it "outputs the collection category feed" do
        expect(news_feed).to match '<title type="html">My awesome site | Collection | News</title>'
        expect(news_feed).to match "http://example.org/collection/collection-category-doc/"
        expect(news_feed).to_not match "http://example.org/collection/collection-doc/"
        expect(news_feed).to_not match "http://example.org/updates/bridgetown/2014/03/04/march-the-fourth/"
        expect(news_feed).to_not match "http://example.org/2015/08/08/stuck-in-the-middle/"
      end
    end

    context "with a custom path" do
      let(:overrides) do
        {
          "collections" => {
            "collection" => {
              "output" => true,
            },
          },
          "feed"        => {
            "collections" => {
              "collection" => {
                "categories" => ["news"],
                "path"       => "custom.xml",
              },
            },
          },
        }
      end

      it "should write to the custom path" do
        expect(Pathname.new(dest_dir("custom.xml"))).to exist
        expect(Pathname.new(dest_dir("feed/collection.xml"))).to_not exist
        expect(Pathname.new(dest_dir("feed/collection/news.xml"))).to exist
      end
    end
  end

  context "excerpt_only flag" do
    context "backward compatibility for no excerpt_only flag" do
      it "should be in contents" do
        expect(contents).to match '<content '
      end
    end

    context "when site.excerpt_only flag is true" do
      let(:overrides) do
        { "feed" => { "excerpt_only" => true } }
      end

      it "should not set any contents" do
        expect(contents).to_not match '<content '
      end
    end

    context "when site.excerpt_only flag is false" do
      let(:overrides) do
        { "feed" => { "excerpt_only" => false } }
      end

      it "should be in contents" do
        expect(contents).to match '<content '
      end
    end

    context "when post.excerpt_only flag is true" do
      let(:overrides) do
        { "feed" => { "excerpt_only" => false } }
      end

      it "should not be in contents" do
        expect(contents).to_not match "This content should not be in feed.</content>"
      end
    end
  end

  context "post_limit override" do
    it "limit the number of posts by default" do
      expect(contents.scan("<entry").size).to eq 10
    end

    context "when collection.post_limit is set" do
      let(:overrides) do
        {
          "feed" => {
            "collections" => {
              "posts" => {
                "post_limit": "1"
              },
            },
          },
        }
      end

      it "should limit the number of posts" do
        expect(contents.scan("<entry").size).to eq 1
      end
    end

    context "when site.post_limit is set" do
      let(:overrides) do
        {
          "feed" => {
            "post_limit": 1
          },
        }
      end

      it "should limit the number of posts" do
        expect(contents.scan("<entry").size).to eq 1
      end
    end
  end

  describe "feed title override" do
    let(:feed) { RSS::Parser.parse(contents) }

    context "with posts collection" do
      let(:overrides) do
        {
          "feed" => {
            "collections" => {
              "posts" => {}
            }
          },
        }
      end

      it "doesn't include a posts title" do
        expect(feed.title.content).not_to include "Posts"
      end
    end

    context "with feed title override" do
      let(:overrides) do
        {
          "feed" => {
            "collections" => {
              "posts" => {
                "title": "My Feed"
              },
            },
          },
        }
      end

      it "includes the custom title" do
        expect(feed.title.content).to include "My Feed"
      end
    end
  end

  describe "feed collection override" do
    context "without specifing the collection" do
      let(:overrides) do
        {
          "feed" => {
            "collections" => {
              "posts" => {}
            }
          },
        }
      end

      it "uses the key name as the collection" do
        expect(config.feed.collections.posts.collection).to eq "posts"
      end
    end

    context "without specifing the collection" do
      let(:overrides) do
        {
          "feed" => {
            "collections" => {
              "my_posts" => {
                "collection" => "posts"
              }
            }
          },
        }
      end

      it "uses the key name as the collection" do
        expect(config.feed.collections.my_posts.collection).to eq "posts"
      end
    end
  end
end
