//
//  Int+VOKTests.swift
//  VinOutlineKit
//
//  Created by Maurice Parker on 1/5/25.
//

import Foundation
import Testing
@testable import VinOutlineKit

final class IntVOKTests {
	
	@Test func levelOne() throws {
		#expect(Int(1).legalNumbering(level: 1) == "I.")
		#expect(Int(2).legalNumbering(level: 1) == "II.")
		#expect(Int(3).legalNumbering(level: 1) == "III.")
		#expect(Int(4).legalNumbering(level: 1) == "IV.")
		#expect(Int(5).legalNumbering(level: 1) == "V.")
		#expect(Int(6).legalNumbering(level: 1) == "VI.")
		#expect(Int(7).legalNumbering(level: 1) == "VII.")
		#expect(Int(8).legalNumbering(level: 1) == "VIII.")
		#expect(Int(9).legalNumbering(level: 1) == "IX.")
		#expect(Int(10).legalNumbering(level: 1) == "X.")
		
		#expect(Int(24).legalNumbering(level: 1) == "XXIV.")
		
		#expect(Int(101).legalNumbering(level: 1) == "CI.")
		#expect(Int(112).legalNumbering(level: 1) == "CXII.")
		#expect(Int(1234).legalNumbering(level: 1) == "MCCXXXIV.")
		
		#expect(Int(4001).legalNumbering(level: 1) == "MMMMI.")
		
		#expect(Int(5001).legalNumbering(level: 1) == "MMMMMI.")
	}
	
	@Test func levelTwo() throws {
		#expect(Int(1).legalNumbering(level: 2) == "A.")
		#expect(Int(2).legalNumbering(level: 2) == "B.")
		#expect(Int(3).legalNumbering(level: 2) == "C.")
		#expect(Int(4).legalNumbering(level: 2) == "D.")
		#expect(Int(5).legalNumbering(level: 2) == "E.")
		#expect(Int(6).legalNumbering(level: 2) == "F.")
		#expect(Int(7).legalNumbering(level: 2) == "G.")
		#expect(Int(8).legalNumbering(level: 2) == "H.")
		#expect(Int(9).legalNumbering(level: 2) == "I.")
		#expect(Int(10).legalNumbering(level: 2) == "J.")
		#expect(Int(26).legalNumbering(level: 2) == "Z.")
		#expect(Int(27).legalNumbering(level: 2) == "AA.")
		#expect(Int(28).legalNumbering(level: 2) == "AB.")
		#expect(Int(29).legalNumbering(level: 2) == "AC.")
		#expect(Int(52).legalNumbering(level: 2) == "AZ.")
		#expect(Int(53).legalNumbering(level: 2) == "BA.")
		#expect(Int(54).legalNumbering(level: 2) == "BB.")
		
		#expect(Int(702).legalNumbering(level: 2) == "ZZ.")
		
		#expect(Int(0).legalNumbering(level: 2) == "??.")
		#expect(Int(703).legalNumbering(level: 2) == "??.")
	}
	
	@Test func levelThree() throws {
		#expect(Int(1).legalNumbering(level: 3) == "1.")
		#expect(Int(11).legalNumbering(level: 3) == "11.")
		#expect(Int(199).legalNumbering(level: 3) == "199.")
	}
	
	@Test func levelFour() throws {
		#expect(Int(1).legalNumbering(level: 4) == "a.")
		#expect(Int(53).legalNumbering(level: 4) == "ba.")
		#expect(Int(702).legalNumbering(level: 4) == "zz.")
	}
	
	@Test func levelFive() throws {
		#expect(Int(1).legalNumbering(level: 5) == "(1)")
		#expect(Int(53).legalNumbering(level: 5) == "(53)")
		#expect(Int(702).legalNumbering(level: 5) == "(702)")
	}
	
	@Test func levelSix() throws {
		#expect(Int(1).legalNumbering(level: 6) == "(a)")
		#expect(Int(53).legalNumbering(level: 6) == "(ba)")
		#expect(Int(702).legalNumbering(level: 6) == "(zz)")
	}
	
	@Test func levelSeven() throws {
		#expect(Int(1).legalNumbering(level: 7) == "(i)")
		#expect(Int(53).legalNumbering(level: 7) == "(liii)")
		#expect(Int(702).legalNumbering(level: 7) == "(dccii)")
	}
	
	@Test func levelEight() throws {
		#expect(Int(1).legalNumbering(level: 8) == "(??)")
	}
	
}
