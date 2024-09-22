# Changelog

## Unreleased

* add option to set a collection feed's title and backing collection

...

## 3.1.2 / 2024-03-02

* Fix: as readme promises, use `id` from a post's front matter if present

## 3.1.1 / 2024-02-02

* Remove duplicate variable assignment (@jbennett)

## 3.1.0 / 2024-02-01

* Add an option to set the post_limit (@jbennett)

## 3.0.0 / 2022-10-08

* Upgrade to initializers system in Bridgetown 1.2

## 2.1.0 / 2021-10-26

* Update test suite and ensure generated pages have the right permalink
* Switch from `site.pages` to `site.generated_pages` due to Bridgetown 1.0 API change

## 2.0.1 / 2021-06-04

* Fix bug where resources' relative URLs weren't included properly

## 2.0.0 / 2021-04-17

* New release with helper to support Ruby templates like ERB

## 1.1.3 / 2020-11-05

* Add `template_engine: liquid` to the feed XML so it plays well with Bridgetown 0.18+

## 1.1.2 / 2020-05-01

Update to require a minimum Ruby version of 2.5.

## 1.1.1 / 2020-04-19

Update to use `_data/site_metadata.yml` in line with the rest of the ecosystem.

## 1.0.0 / 2020-04-09

Use Bridgetown gem and rename to bridgetown-feed.