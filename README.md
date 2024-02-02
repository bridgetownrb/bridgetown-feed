# Bridgetown Feed plugin

A Bridgetown plugin to generate an Atom (RSS-like) feed of your Bridgetown posts and other collection documents.

## Installation for Bridgetown 1.2+

Run this command to add this plugin to your site's Gemfile:

```shell
$ bundle add bridgetown-feed
```

Or simply add this line to your Gemfile:

```ruby
gem 'bridgetown-feed'
```

And then add the initializer to your configuration in `config/initializers.rb`:

```ruby
Bridgetown.configure do
  # existing config here

  init :"bridgetown-feed"
end
```

(For Bridgetown 1.1 or earlier, [read these instructions](https://github.com/bridgetownrb/bridgetown-feed/tree/v2.1.0).)

## Usage

The plugin exposes a helper tag to expose the appropriate meta tags to support automated discovery of your feed.

Simply place `feed_meta` someplace in your layout's `<head>` section to output the necessary metadata.

```liquid
<!-- layout.liquid -->
{% feed_meta %}
```

```erb
<!-- layout.erb -->
<%= feed_meta %>
```

The plugin will automatically generate an Atom feed at `/feed.xml`.

### Optional configuration options

The plugin will automatically use any of the following metadata variables if they are present in your site's `_data/site_metadata.yml` file.

* `title` or `name` - The title of the site, e.g., "My awesome site"
* `description` - A longer description of what your site is about, e.g., "Where I blog about Bridgetown and other awesome things"
* `author` - Global author information (see below)

In addition it looks for these `bridgetown.config.yml` settings:

* `url` - The URL to your site, e.g., `https://example.com`.

### Already have a feed path?

Do you already have an existing feed someplace other than `/feed.xml`, but are on a host like GitHub Pages that doesn't support machine-friendly redirects? If you simply swap out `bridgetown-feed` for your existing template, your existing subscribers won't continue to get updates. Instead, you can specify a non-default path via your site's config.

```yml
feed:
  path: atom.xml
```

To note, you shouldn't have to do this unless you already have a feed you're using, and you can't or wish not to redirect existing subscribers.

### Optional front matter

The plugin will use the following post metadata, automatically generated by Bridgetown, which you can override via a post's YAML front matter:

* `date`
* `title`
* `id`
* `category`
* `tags`

Additionally, the plugin will use the following values, if present in a post's YAML front matter:

* `image` - URL of an image that is representative of the post (can also be passed as `image.path`)

* `author` - The author of the post, e.g., "Dr. Bridgetown". If none is given, feed readers will look to the feed author as defined in `_data/site_metadata.yml`. Like the feed author, this can also be an object or a reference to an author in `_data/authors.yml` (see below).

### Author information

*TL;DR: In most cases, put `author: [your name]` in the document's front matter, for sites with multiple authors. If you need something more complicated, read on.*

There are several ways to convey author-specific information. Author information is found in the following order of priority:

1. An `author` object, in the documents's front matter, e.g.:

  ```yml
  author:
    name: Issac Asimov
  ```

2. An `author` object, in the site's `_data/site_metadata.yml`, e.g.:

  ```yml
  author:
    name: Issac Asimov
  ```

3. `site.data.authors[author]`, if an author is specified in the document's front matter, and a corresponding key exists in `site.data.authors`. E.g., you have the following in the document's front matter:

  ```yml
  author: iasimov
  ```

  And you have the following in `_data/authors.yml`:

  ```yml
  iasimov:
    picture: /images/marina.jpg
    name: Issac Asimov

  jwhite:
    picture: /images/jared.jpg
    name: Jared White
  ```

  In the above example, the author `iasimov`'s name will be resolved to `Issac Asimov`. This allows you to centralize author information in a single `_data/authors.yml` file for site with many authors that require more than just the author's username.

  *Pro-tip: If `authors` is present in the document's front matter as an array (and `author` is not), the plugin will use the first author listed.*

4. An author in the document's front matter (the simplest way), e.g.:

  ```yml
  author: marina
  ```

5. An author in the site's `_data/site_metadata.yml`, e.g.:

  ```yml
  author: marina
  ```

The author keys the plugin can read are `name`, `email`, and `uri` (for linking to an author's website).

### SmartyPants

The plugin uses [Bridgetown's `smartify` filter](https://www.bridgetownrb.com/docs/liquid/filters) for processing the site title and post titles. This will translate plain ASCII punctuation into "smart" typographic punctuation. This will not render or strip any Markdown you may be using in a title.

Bridgetown's `smartify` filter uses [kramdown](https://kramdown.gettalong.org/options.html) as a processor.  Accordingly, if you do not want "smart" typographic punctuation, disabling them in kramdown in your `bridgetown.config.yml` will disable them in your feed. For example:

   ```yml
   kramdown:
     smart_quotes:               apos,apos,quot,quot
     typographic_symbols:        {hellip: ...}
   ```

### Custom styling

Want to style what your feed looks like in the browser? Simply add an XSLT at `/feed.xslt.xml` and Bridgetown Feed will link to the stylesheet.

## Categories

Bridgetown Feed can generate feeds for each category. Simply define which categories you'd like feeds for in your config:

```yml
feed:
  categories:
    - news
    - updates
```

## Collections

Bridgetown Feed can generate feeds for collections other than the Posts collection. This works best for chronological collections (e.g., collections with dates in the filenames). Simply define which collections you'd like feeds for in your config:

```yml
feed:
  collections:
    - changes
```

By default, collection feeds will be outputted to `/feed/<COLLECTION>.xml`. If you'd like to customize the output path, specify a collection's custom path as follows:

```yml
feed:
  collections:
    changes:
      path: "/changes.xml"
```

Finally, collections can also have category feeds which are outputted as `/feed/<COLLECTION>/<CATEGORY>.xml`. Specify categories like so:

```yml
feed:
  collections:
    changes:
      path: "/changes.xml"
      categories:
        - news
        - updates
```

## Post Limit

Optional flag `post_limit` allows you to set a limit to the number of posts shown in the feed. Default value is `10`.

When it is set in `bridgetown.config.yml`, all collections will be limited:

```yml
feed:
  post_limit: 25
```

The same flag can also be set on a collection:

```yml
feed:
  collections:
    changes:
      post_limit: 25
```

## Testing

* Run `bundle exec rspec` to run the test suite
* Or run `script/cibuild` to validate with Rubocop and test with rspec together

## Contributing

1. Fork it (https://github.com/bridgetownrb/bridgetown-feed/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
