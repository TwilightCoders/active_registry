# frozen_string_literal: true

# Manages query result caching for performance optimization
module RegistryQueryCache
  CACHE_SIZE_LIMIT = 1000

  def initialize_query_cache
    @query_cache = {}
    @cache_hits = 0
    @cache_misses = 0
  end

  # Check cache for a query result
  def check_cache(cache_key)
    if @query_cache.key?(cache_key)
      @cache_hits += 1
      @query_cache[cache_key]
    else
      @cache_misses += 1
      nil
    end
  end

  # Store a query result in the cache
  def store_in_cache(cache_key, result_set)
    return if @query_cache.size >= CACHE_SIZE_LIMIT

    @query_cache[cache_key] = result_set.dup
  end

  # Invalidate all cached queries (called when registry changes)
  def invalidate_cache
    @query_cache.clear
  end

  # Get cache performance statistics
  def cache_stats
    total_queries = @cache_hits + @cache_misses
    return { hits: 0, misses: 0, hit_rate: 0.0, total_queries: 0 } if total_queries.zero?

    {
      hits: @cache_hits,
      misses: @cache_misses,
      hit_rate: (@cache_hits.to_f / total_queries * 100).round(2),
      total_queries: total_queries
    }
  end
end
