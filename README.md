# LFUCache

A Swift implementation of a [Least Frequently Used](https://en.wikipedia.org/wiki/Least_frequently_used) cache.

## Overview of Least Frequently Used Cache

From [Wikipedia](https://en.wikipedia.org/wiki/Cache_(computing)): “A cache […] stores data so that future requests for that data can be served faster; the data stored in a cache might be the result of an earlier computation or a copy of data stored elsewhere.”

A cache eviction policy prevents the cache from growing unbounded. The Least Frequently Used policy chooses to evict (you guessed it!) the least-frequently-used element when the cache is full. This library’s `LFUCache` falls back to the Least Recently Used policy when two elements have the same usage frequency.

## Algorithmic Time Complexity

| Operation | Time Complexity |
| --- | --- |
| `isEmpty` | `O(1)` |
| `count` | `O(1)` |
| `subscript(key:)` (get) | `O(1)` |
| `subscript(key:)` (insert) | `O(1)` |
| `subscript(key:)` (update) | `O(1)` |
| `subscript(key:)` (remove) | `O(1)` |

## API Usage

See `Tests/LFUCacheTests/LFUCacheTests.swift`.

## Compatibility

Tested using Swift 5. MIT license.
