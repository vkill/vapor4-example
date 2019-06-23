import XCTest

import AppTests

var tests = [XCTestCaseEntry]()
tests += AppTests.allTests()
tests += AppFutureTests.allTests()
XCTMain(tests)
