module Cashier
  extend self

  CACHE_KEY = 'cashier-tags'

  def adapter
    Cashier::Addons::Adapters.current_adapter
  end

  # Public: whether the module will perform caching or not. this is being set in the application layer .perform_caching configuration
  #
  # Examples
  #
  #   Cashier.perform_caching?
  #   # => true
  #
  def perform_caching?
    ::ApplicationController.perform_caching
  end

  # Public: store a fragment with an array of tags for this fragment.
  #
  # fragment - cached fragment.
  # tags - array of tags you want to assign this fragments.
  #
  # Examples
  #
  #   Cachier.store_fragment('foo', 'tag1', 'tag2', 'tag3')
  #
  def store_fragment(fragment, *tags)
    return unless perform_caching?
    Cashier::Addons::Plugins.call_plugin_method(:on_store_fragment, [fragment, tags])

    tags.each do |tag|
      # store the fragment
      adapter.store_fragment_in_tag(fragment, tag)
    end

     # now store the tag for book keeping
    adapter.store_tags(tags)
  end

  # Public: expire tags. expiring the keys 'assigned' to the tags you expire and removes the tags from the tags list
  # 
  # tags - array of tags to expire.
  # 
  # Examples
  #
  #   Cashier.expire('tag1', 'tag2')
  # 
  def expire(*tags)
    return unless perform_caching?
    Cashier::Addons::Plugins.call_plugin_method(:on_expire, tags)

    # delete them from the cache
    tags.each do |tag|
      fragment_keys = adapter.get_fragments_for_tag(tag)
      
      fragment_keys.each do |fragment_key|
        Rails.cache.delete(fragment_key)
      end

      adapter.delete_tag(tag)
    end

    # now remove them from the list
    # of stored tags
    adapter.remove_tags(tags)
  end

  # Public: returns the array of tags stored in the tags store.
  #
  #
  # Examples
  #
  #   Cashier.tags
  #   # => ['tag1', 'tag2']
  #
  def tags
    adapter.tags
  end

  # Public: clears the tags.
  #
  #
  # Examples
  #
  #   Cashier.clear
  #
  def clear
    Cashier::Addons::Plugins.call_plugin_method(:on_clear)
    adapter.clear
  end

  # Public: get all the keys names as an array.
  #
  #
  # Examples
  #
  #   Cachier.keys
  #   # => ['key1', 'key2', 'key3']
  #
  def keys
    adapter.keys
  end

  # Public: get all the keys for a specific tag as an array.
  #
  #
  # Examples
  #
  #   Cashier.tags_for('tag1')
  #   # => ['key1', 'key2', 'key3']
  #
  def keys_for(tag)
    adapter.get_fragments_for_tag(tag)
  end
end


require 'rails'
require 'cashier/addons/plugins'
require 'cashier/addons/adapters'
require 'active_support/cache/dalli_store_additions'
require 'cashier/adapters/cache_store'
require 'cashier/adapters/redis_store'