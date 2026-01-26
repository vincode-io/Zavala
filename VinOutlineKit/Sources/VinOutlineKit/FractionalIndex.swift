//
//  FractionalIndex.swift
//
//
//  Created by Maurice Parker on 1/25/26.
//

import Foundation

/// A utility for generating fractional index strings for row ordering.
/// Uses a "Cardinality Hole" strategy where each row stores its own order value
/// as a string that can be lexicographically compared.
///
/// The algorithm represents positions as base-62 fractions. Each string represents
/// a number between 0 and 1. For example:
/// - "V" ≈ 0.5 (31/62)
/// - "a" ≈ 0.58 (36/62)
/// - "aV" ≈ 0.58 + 0.5/62 ≈ 0.588
///
/// The key property is that for any two distinct strings, we can always find
/// a string that lexicographically sorts between them.
public struct FractionalIndex {

	/// The digits used for encoding, in ASCII sort order.
	/// 0-9 (ASCII 48-57), A-Z (ASCII 65-90), a-z (ASCII 97-122)
	private static let digits: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")

	/// The base of our number system
	private static let base = 62

	/// Index of the smallest digit
	private static let smallestDigit = 0

	/// Index of the largest digit
	private static let largestDigit = 61

	/// Index of a middle digit (used for generating midpoints)
	private static let midDigit = 31 // 'V'

	/// Generate an order string between two values (either can be nil).
	/// - Parameters:
	///   - before: The order string that should sort before the result (nil means beginning)
	///   - after: The order string that should sort after the result (nil means end)
	/// - Returns: A string that sorts lexicographically between before and after
	public static func between(_ before: String?, _ after: String?) -> String {
		let b = before ?? ""
		let a = after ?? ""

		// Convert to digit arrays, treating empty strings specially
		let beforeDigits = b.compactMap { digitIndex($0) }
		let afterDigits = a.compactMap { digitIndex($0) }

		return midpoint(beforeDigits, afterDigits)
	}

	/// Generate initial evenly-distributed order values for a given count.
	/// - Parameter count: The number of order values needed
	/// - Returns: An array of order strings evenly distributed
	public static func initial(count: Int) -> [String] {
		guard count > 0 else { return [] }

		// Calculate minimum digits needed to ensure uniqueness
		// We need base^digits > count to have enough distinct values
		let digitsNeeded = max(1, Int(ceil(log(Double(count + 1)) / log(Double(base)))))

		// Total number of slots with this many digits
		let totalSlots = Int(pow(Double(base), Double(digitsNeeded)))

		var result = [String]()

		// Distribute evenly across the range, leaving room at boundaries
		for i in 1...count {
			let position = Double(i) / Double(count + 1)
			// Map to slot index within the available range
			let slotIndex = Int(position * Double(totalSlots - 2)) + 1

			// Convert slot index to base-62 string with fixed width
			var index = slotIndex
			var chars = [Character]()
			for _ in 0..<digitsNeeded {
				chars.insert(digits[index % base], at: 0)
				index /= base
			}
			result.append(String(chars))
		}

		return result
	}

	/// Check if rebalancing is needed based on string length.
	/// - Parameters:
	///   - order: The order string to check
	///   - threshold: Maximum acceptable length before rebalancing
	/// - Returns: true if the order string exceeds the threshold
	public static func needsRebalancing(_ order: String, threshold: Int = 50) -> Bool {
		return order.count > threshold
	}

	/// Generate new balanced order values for rebalancing a set of rows.
	/// - Parameter count: The number of order values needed
	/// - Returns: An array of evenly distributed order strings
	public static func rebalance(count: Int) -> [String] {
		return initial(count: count)
	}

	// MARK: - Private Helpers

	/// Convert a character to its digit index
	private static func digitIndex(_ char: Character) -> Int? {
		return digits.firstIndex(of: char)
	}

	/// Convert digit indices to a string
	private static func digitsToString(_ indices: [Int]) -> String {
		return String(indices.map { digits[$0] })
	}

	/// Find the lexicographic midpoint between two digit sequences.
	/// beforeDigits and afterDigits represent the bounds (exclusive).
	/// An empty beforeDigits means "before everything" (conceptually all 0s).
	/// An empty afterDigits means "after everything" (conceptually all z's).
	private static func midpoint(_ beforeDigits: [Int], _ afterDigits: [Int]) -> String {
		// Handle the simple cases
		if beforeDigits.isEmpty && afterDigits.isEmpty {
			// Return middle value
			return String(digits[midDigit])
		}

		if beforeDigits.isEmpty {
			// Need something before afterDigits
			// Find first non-zero digit and halve it
			return generateBefore(afterDigits)
		}

		if afterDigits.isEmpty {
			// Need something after beforeDigits
			return generateAfter(beforeDigits)
		}

		// Both bounds exist, find midpoint
		return generateBetween(beforeDigits, afterDigits)
	}

	/// Generate a value that sorts before the given digit sequence
	private static func generateBefore(_ after: [Int]) -> String {
		var result = [Int]()
		var foundNonZero = false

		for digit in after {
			if digit > 0 && !foundNonZero {
				// Found first non-zero digit, use midpoint between 0 and this digit
				foundNonZero = true
				if digit == 1 {
					// Need to go deeper: prefix with 0, then find midpoint
					result.append(0)
					continue
				} else {
					result.append(digit / 2)
					return digitsToString(result)
				}
			} else if !foundNonZero {
				// Digit is 0, include it and continue
				result.append(0)
			}
		}

		// All digits were 0 or we need to go deeper
		// Append midpoint
		result.append(midDigit)
		return digitsToString(result)
	}

	/// Generate a value that sorts after the given digit sequence
	private static func generateAfter(_ before: [Int]) -> String {
		var result = before

		// Find rightmost digit that can be incremented
		for i in (0..<result.count).reversed() {
			if result[i] < largestDigit {
				// Increment using midpoint between current and max
				let newDigit = result[i] + (largestDigit - result[i] + 1) / 2
				result[i] = newDigit
				return digitsToString(Array(result[0...i]))
			}
		}

		// All digits are at maximum, extend with a high-ish value
		result.append(midDigit)
		return digitsToString(result)
	}

	/// Generate a value between two digit sequences
	private static func generateBetween(_ before: [Int], _ after: [Int]) -> String {
		// Track the common prefix we're building
		var result = [Int]()

		let maxLen = max(before.count, after.count)

		// Find first position where they differ
		var pos = 0
		while pos < maxLen {
			let bDigit = pos < before.count ? before[pos] : smallestDigit
			let aDigit = pos < after.count ? after[pos] : largestDigit

			if bDigit == aDigit {
				// Same digit, add to common prefix and continue
				result.append(bDigit)
				pos += 1
				continue
			}

			if bDigit < aDigit {
				// Found difference - check if there's room
				if aDigit - bDigit > 1 {
					// Direct midpoint between the digits
					result.append((bDigit + aDigit) / 2)
					return digitsToString(result)
				} else {
					// Adjacent digits (bDigit and bDigit+1), need to go deeper
					// Result will be: commonPrefix + bDigit + suffix
					// where suffix > remaining of before
					result.append(bDigit)

					let bSuffix = pos + 1 < before.count ? Array(before[(pos + 1)...]) : []
					// We need something > bSuffix
					let suffix = generateAfter(bSuffix)
					return digitsToString(result) + suffix
				}
			}

			// bDigit > aDigit shouldn't happen if before < after
			break
		}

		// Strings are equal up to maxLen, extend with midpoint
		result.append(midDigit)
		return digitsToString(result)
	}
}
