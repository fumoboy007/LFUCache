// Copyright © 2019 Darren Mo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the “Software”), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import LFUCache

import XCTest

final class LFUCacheTests: XCTestCase {
   func testEmpty() {
      let cache = LFUCache<String, String>(maximumCapacity: 1)

      XCTAssertNil(cache["not present"])
      XCTAssertEqual(cache["not present", default: "default value"], "default value")

      assertCache(cache, equalsElementsSortedByFrequency: [])
   }

   func testSingleElement() {
      let cache = LFUCache<String, String>(maximumCapacity: 1)
      assertCache(cache, equalsElementsSortedByFrequency: [])

      cache["key1"] = "value1"
      assertCache(cache, equalsElementsSortedByFrequency: [("key1", "value1")])

      XCTAssertEqual(cache["key1"], "value1")
      assertCache(cache, equalsElementsSortedByFrequency: [("key1", "value1")])

      cache["key2"] = "value2"
      assertCache(cache, equalsElementsSortedByFrequency: [("key2", "value2")])
   }

   func testTwoElements() {
      let cache = LFUCache<String, String>(maximumCapacity: 2)
      assertCache(cache, equalsElementsSortedByFrequency: [])

      cache["key1"] = "value1"
      assertCache(cache, equalsElementsSortedByFrequency: [("key1", "value1")])

      cache["key2"] = "value2a"
      assertCache(cache, equalsElementsSortedByFrequency: [("key1", "value1"), ("key2", "value2a")])

      XCTAssertEqual(cache["key1"], "value1")
      assertCache(cache, equalsElementsSortedByFrequency: [("key2", "value2a"), ("key1", "value1")])

      cache["key2"] = "value2b"
      assertCache(cache, equalsElementsSortedByFrequency: [("key1", "value1"), ("key2", "value2b")])
   }

   func testMultipleElements() {
      let cache = LFUCache<String, String>(maximumCapacity: 3)
      assertCache(cache, equalsElementsSortedByFrequency: [])

      cache["key1"] = "value1"
      assertCache(cache, equalsElementsSortedByFrequency: [("key1", "value1")])

      cache["key2"] = "value2"
      assertCache(cache, equalsElementsSortedByFrequency: [("key1", "value1"), ("key2", "value2")])

      cache["key3"] = "value3"
      assertCache(cache, equalsElementsSortedByFrequency: [("key1", "value1"), ("key2", "value2"), ("key3", "value3")])

      XCTAssertEqual(cache["key1"], "value1")
      assertCache(cache, equalsElementsSortedByFrequency: [("key2", "value2"), ("key3", "value3"), ("key1", "value1")])

      XCTAssertEqual(cache["key1"], "value1")
      assertCache(cache, equalsElementsSortedByFrequency: [("key2", "value2"), ("key3", "value3"), ("key1", "value1")])

      XCTAssertEqual(cache["key3"], "value3")
      assertCache(cache, equalsElementsSortedByFrequency: [("key2", "value2"), ("key3", "value3"), ("key1", "value1")])

      XCTAssertEqual(cache["key2"], "value2")
      assertCache(cache, equalsElementsSortedByFrequency: [("key3", "value3"), ("key2", "value2"), ("key1", "value1")])

      XCTAssertEqual(cache["key2"], "value2")
      assertCache(cache, equalsElementsSortedByFrequency: [("key3", "value3"), ("key1", "value1"), ("key2", "value2")])

      cache["key4"] = "value4"
      assertCache(cache, equalsElementsSortedByFrequency: [("key4", "value4"), ("key1", "value1"), ("key2", "value2")])

      cache["key1"] = nil
      assertCache(cache, equalsElementsSortedByFrequency: [("key4", "value4"), ("key2", "value2")])
   }

   private func assertCache(_ cache: LFUCache<String, String>,
                            equalsElementsSortedByFrequency expectedElementsSortedByFrequency: [(key: String, value: String)]) {
      XCTAssertEqual(cache.isEmpty, expectedElementsSortedByFrequency.isEmpty)
      XCTAssertEqual(cache.count, expectedElementsSortedByFrequency.count)

      let elementsSortedByFrequency = Array(cache)
      XCTAssertEqual(elementsSortedByFrequency.map { $0.key }, expectedElementsSortedByFrequency.map { $0.key })
      XCTAssertEqual(elementsSortedByFrequency.map { $0.value }, expectedElementsSortedByFrequency.map { $0.value })
   }

   static var allTests = [
      ("testEmpty", testEmpty),
      ("testSingleElement", testSingleElement),
      ("testTwoElements", testTwoElements),
      ("testMultipleElements", testMultipleElements)
   ]
}
