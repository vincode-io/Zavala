//
//  FractionalIndexTests.swift
//
//
//  Created by Maurice Parker on 1/25/26.
//

import Foundation
import Testing
@testable import VinOutlineKit

struct FractionalIndexTests {

	// MARK: - Initial Order Tests

	@Test func initialWithZeroCount() {
		let orders = FractionalIndex.initial(count: 0)
		#expect(orders.isEmpty)
	}

	@Test func initialWithOneItem() {
		let orders = FractionalIndex.initial(count: 1)
		#expect(orders.count == 1)
		#expect(orders[0] == "V") // Middle of alphabet (index 31 of 62)
	}

	@Test func initialWithMultipleItems() {
		let orders = FractionalIndex.initial(count: 3)
		#expect(orders.count == 3)
		// Should be evenly distributed
		#expect(orders[0] < orders[1])
		#expect(orders[1] < orders[2])
	}

	@Test func initialValuesAreSorted() {
		for count in 1...10 {
			let orders = FractionalIndex.initial(count: count)
			let sorted = orders.sorted()
			#expect(orders == sorted)
		}
	}

	// MARK: - Between Tests

	@Test func betweenNilAndNil() {
		let order = FractionalIndex.between(nil, nil)
		#expect(!order.isEmpty)
		#expect(order == "V") // Middle of alphabet (index 31 of 62)
	}

	@Test func betweenNilAndValue() {
		let order = FractionalIndex.between(nil, "m")
		#expect(!order.isEmpty)
		#expect(order < "m")
	}

	@Test func betweenValueAndNil() {
		let order = FractionalIndex.between("m", nil)
		#expect(!order.isEmpty)
		#expect(order > "m")
	}

	@Test func betweenTwoValues() {
		let order = FractionalIndex.between("C", "G")
		#expect(!order.isEmpty)
		#expect(order > "C")
		#expect(order < "G")
	}

	@Test func betweenAdjacentValues() {
		let order = FractionalIndex.between("a", "b")
		#expect(!order.isEmpty)
		#expect(order > "a")
		#expect(order < "b")
	}

	@Test func betweenWithLongStrings() {
		let order = FractionalIndex.between("aaa", "aab")
		#expect(!order.isEmpty)
		#expect(order > "aaa")
		#expect(order < "aab")
	}

	@Test func betweenMaintainsSortOrder() {
		var orders = FractionalIndex.initial(count: 3)

		// Insert between first two
		let newOrder = FractionalIndex.between(orders[0], orders[1])
		orders.insert(newOrder, at: 1)

		let sorted = orders.sorted()
		#expect(orders == sorted)
	}

	@Test func repeatedInsertionsAtSamePosition() {
		// Start with a middle value (realistic starting point)
		var orders = ["V"]

		// Keep inserting at the beginning
		for _ in 0..<20 {
			let newOrder = FractionalIndex.between(nil, orders.first!)
			orders.insert(newOrder, at: 0)
		}

		let sorted = orders.sorted()
		#expect(orders == sorted)
	}

	@Test func repeatedInsertionsAtEnd() {
		// Start with a middle value
		var orders = ["V"]

		// Keep inserting at the end
		for _ in 0..<20 {
			let newOrder = FractionalIndex.between(orders.last!, nil)
			orders.append(newOrder)
		}

		let sorted = orders.sorted()
		#expect(orders == sorted)
	}

	@Test func insertBetweenSamePosition() {
		var orders = ["a", "b"]

		// Keep inserting between the same two values
		for _ in 0..<20 {
			let newOrder = FractionalIndex.between(orders[0], orders[1])
			orders.insert(newOrder, at: 1)
		}

		let sorted = orders.sorted()
		#expect(orders == sorted)
	}

	// MARK: - Rebalancing Tests

	@Test func needsRebalancingShortString() {
		#expect(!FractionalIndex.needsRebalancing("abc"))
	}

	@Test func needsRebalancingLongString() {
		let longString = String(repeating: "a", count: 51)
		#expect(FractionalIndex.needsRebalancing(longString))
	}

	@Test func needsRebalancingAtThreshold() {
		let exactString = String(repeating: "a", count: 50)
		#expect(!FractionalIndex.needsRebalancing(exactString))
	}

	@Test func needsRebalancingCustomThreshold() {
		#expect(FractionalIndex.needsRebalancing("abcde", threshold: 3))
		#expect(!FractionalIndex.needsRebalancing("ab", threshold: 3))
	}

	@Test func rebalanceGeneratesEvenDistribution() {
		let orders = FractionalIndex.rebalance(count: 5)
		#expect(orders.count == 5)

		let sorted = orders.sorted()
		#expect(orders == sorted)
	}

	@Test func rebalanceWithLargeCountHasNoDuplicates() {
		let orders = FractionalIndex.rebalance(count: 152)
		#expect(orders.count == 152)

		let uniqueOrders = Set(orders)
		#expect(uniqueOrders.count == orders.count, "Found \(orders.count - uniqueOrders.count) duplicate(s) in rebalanced orders")
	}

	// MARK: - Edge Cases

	@Test func beforeFirstCharacter() {
		// Test inserting before "a" (middle of alphabet, index 36)
		let order = FractionalIndex.between(nil, "a")
		#expect(!order.isEmpty)
		#expect(order < "a")
	}

	@Test func afterLastCharacter() {
		let order = FractionalIndex.between("z", nil)
		#expect(!order.isEmpty)
		#expect(order > "z")
	}

	@Test func betweenAllAs() {
		let order = FractionalIndex.between("aaa", "aab")
		#expect(order > "aaa")
		#expect(order < "aab")
	}

	@Test func betweenAllZs() {
		let order = FractionalIndex.between("zzz", nil)
		#expect(order > "zzz")
	}

	@Test func betweenPrefixStrings() {
		// "a" is a prefix of "ab", so we need something between "a" and "ab"
		let order = FractionalIndex.between("a", "ab")
		#expect(order > "a")
		#expect(order < "ab")
	}

	// MARK: - Stress Tests

	@Test func manyRandomInsertions() {
		var orders = FractionalIndex.initial(count: 5)

		for _ in 0..<100 {
			let insertIndex = Int.random(in: 0...orders.count)
			let before = insertIndex > 0 ? orders[insertIndex - 1] : nil
			let after = insertIndex < orders.count ? orders[insertIndex] : nil
			let newOrder = FractionalIndex.between(before, after)
			orders.insert(newOrder, at: insertIndex)

			let sorted = orders.sorted()
			#expect(orders == sorted, "Order was violated after insertion at index \(insertIndex)")
		}
	}

}
