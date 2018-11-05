import XCTest

import PackageConfigTests

var tests = [XCTestCaseEntry]()
tests += PackageConfigTests.allTests()
XCTMain(tests)