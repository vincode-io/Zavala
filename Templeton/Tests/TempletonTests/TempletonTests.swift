import XCTest
@testable import Templeton

final class TempletonTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Templeton().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
