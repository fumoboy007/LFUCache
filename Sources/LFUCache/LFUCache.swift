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

public class LFUCache<Key: Hashable, Value> {
   // MARK: Private Properties

   private let maximumCapacity: Int

   private var keyToLRUNodeMap = [Key: LRUNode]()

   private var headLFUNode: LFUNode?
   private var tailLFUNode: LFUNode?

   private var lastUsageTime: UInt64 = 0

   // MARK: Initialization

   public init(maximumCapacity: Int) {
      precondition(maximumCapacity > 0)

      self.maximumCapacity = maximumCapacity
   }

   // MARK: Basic Getters

   public var isEmpty: Bool {
      return keyToLRUNodeMap.isEmpty
   }

   public var count: Int {
      return keyToLRUNodeMap.count
   }

   // MARK: Subscripts

   public subscript(key: Key) -> Value? {
      get {
         guard let lruNode = keyToLRUNodeMap[key] else {
            return nil
         }

         updateUsageStats(for: lruNode)

         return lruNode.value
      }

      set {
         if let newValue = newValue {
            if let lruNode = keyToLRUNodeMap[key] {
               updateValue(in: lruNode, to: newValue)
            } else {
               insertValue(newValue, forKey: key)
            }
         } else {
            removeValue(forKey: key)
         }
      }
   }

   public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
      get {
         return self[key] ?? defaultValue()
      }

      set {
         self[key] = newValue
      }
   }

   // MARK: Inserting/Updating/Removing Values

   private func insertValue(_ value: Value,
                            forKey key: Key) {
      removeLeastFrequentlyUsedElementIfNeeded()

      let lfuNode = lfuNodeForFirstUsage()

      let lruNode = LRUNode(key: key,
                            value: value,
                            lastUsageTime: lastUsageTimeBeforeIncrementing(),
                            parentLFUNode: lfuNode)
      append(lruNode, to: lfuNode)

      keyToLRUNodeMap[key] = lruNode
   }

   private func removeLeastFrequentlyUsedElementIfNeeded() {
      guard keyToLRUNodeMap.count == maximumCapacity else {
         return
      }

      let lruNode = headLFUNode!.headLRUNode!
      remove(lruNode)

      keyToLRUNodeMap[lruNode.key] = nil
   }

   private func updateValue(in lruNode: LRUNode,
                            to newValue: Value) {
      updateUsageStats(for: lruNode)

      lruNode.value = newValue
   }

   private func removeValue(forKey key: Key) {
      guard let lruNode = keyToLRUNodeMap.removeValue(forKey: key) else {
         return
      }

      remove(lruNode)
   }

   // MARK: Updating Usage Stats

   private func updateUsageStats(for lruNode: LRUNode) {
      lruNode.lastUsageTime = lastUsageTimeBeforeIncrementing()

      let nextLFUNode = lfuNode(after: lruNode.parentLFUNode)
      remove(lruNode)
      append(lruNode, to: nextLFUNode)
   }

   private func lastUsageTimeBeforeIncrementing() -> UInt64 {
      let previousLastUsageTime = lastUsageTime
      lastUsageTime += 1
      return previousLastUsageTime
   }

   // MARK: Linked List Logic

   private func lfuNodeForFirstUsage() -> LFUNode {
      if let headLFUNode = headLFUNode, headLFUNode.usageCount == 1 {
         return headLFUNode
      } else {
         let lfuNode = LFUNode(usageCount: 1)

         lfuNode.nextNode = headLFUNode
         headLFUNode = lfuNode

         if tailLFUNode == nil {
            tailLFUNode = lfuNode
         }

         return lfuNode
      }
   }

   private func lfuNode(after previousLFUNode: LFUNode) -> LFUNode {
      let nextLFUNode = previousLFUNode.nextNode

      let usageCount = previousLFUNode.usageCount + 1
      if let nextLFUNode = nextLFUNode, nextLFUNode.usageCount == usageCount {
         return nextLFUNode
      } else {
         let lfuNode = LFUNode(usageCount: usageCount)

         lfuNode.nextNode = nextLFUNode
         previousLFUNode.nextNode = lfuNode

         if tailLFUNode === previousLFUNode {
            tailLFUNode = lfuNode
         }

         return lfuNode
      }
   }

   private func append(_ lruNode: LRUNode, to lfuNode: LFUNode) {
      if lfuNode.headLRUNode == nil {
         lfuNode.headLRUNode = lruNode
      }

      lfuNode.tailLRUNode?.nextNode = lruNode
      lfuNode.tailLRUNode = lruNode

      lruNode.parentLFUNode = lfuNode
   }

   private func remove(_ lruNode: LRUNode) {
      let lfuNode = lruNode.parentLFUNode!
      if lfuNode.headLRUNode === lruNode {
         lfuNode.headLRUNode = lruNode.nextNode
      }
      if lfuNode.tailLRUNode === lruNode {
         lfuNode.tailLRUNode = lruNode.previousNode
      }

      if lfuNode.isEmpty {
         remove(lfuNode)
      } else {
         lruNode.previousNode?.nextNode = lruNode.nextNode
         lruNode.nextNode = nil
      }

      lruNode.parentLFUNode = nil
   }

   private func remove(_ lfuNode: LFUNode) {
      if headLFUNode === lfuNode {
         headLFUNode = lfuNode.nextNode
      }
      if tailLFUNode === lfuNode {
         tailLFUNode = lfuNode.previousNode
      }

      lfuNode.previousNode?.nextNode = lfuNode.nextNode
      lfuNode.nextNode = nil
   }
}

// MARK: -

extension LFUCache {
   fileprivate class LFUNode {
      // MARK: Variables

      let usageCount: UInt64

      private(set) weak var previousNode: LFUNode?
      var nextNode: LFUNode? {
         willSet {
            nextNode?.previousNode = nil
         }

         didSet {
            nextNode?.previousNode = self
         }
      }

      var headLRUNode: LRUNode?
      var tailLRUNode: LRUNode?

      var isEmpty: Bool {
         return headLRUNode == nil
      }

      // MARK: Initialization

      init(usageCount: UInt64) {
         self.usageCount = usageCount
      }
   }
}

// MARK: -

extension LFUCache {
   fileprivate class LRUNode {
      // MARK: Variables

      let key: Key
      var value: Value

      var lastUsageTime: UInt64

      private(set) weak var previousNode: LRUNode?
      var nextNode: LRUNode? {
         willSet {
            nextNode?.previousNode = nil
         }

         didSet {
            nextNode?.previousNode = self
         }
      }

      weak var parentLFUNode: LFUNode!

      // MARK: Initialization

      init(key: Key,
           value: Value,
           lastUsageTime: UInt64,
           parentLFUNode: LFUNode) {
         self.key = key
         self.value = value
         self.lastUsageTime = lastUsageTime
         self.parentLFUNode = parentLFUNode
      }
   }
}

// MARK: - Sequence Conformance

// Note: We do not update the usage stats when iterating to avoid changing the iteration order.
extension LFUCache: Sequence {
   public struct Iterator: IteratorProtocol {
      private weak var nextLRUNode: LRUNode?

      fileprivate init(nextLRUNode: LRUNode?) {
         self.nextLRUNode = nextLRUNode
      }

      public mutating func next() -> (key: Key, value: Value)? {
         guard let lruNode = nextLRUNode else {
            return nil
         }

         nextLRUNode =
            lruNode.nextNode ??
            lruNode.parentLFUNode.nextNode?.headLRUNode

         return (lruNode.key, lruNode.value)
      }
   }

   public func makeIterator() -> Iterator {
      return Iterator(nextLRUNode: headLFUNode?.headLRUNode)
   }
}
