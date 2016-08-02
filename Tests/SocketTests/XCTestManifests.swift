//
//  XCTestManifests.swift
//  Socket
//
//  Created by Bill Abt on 8/1/16.
//
//

import XCTest

#if !os(macOS)
	public func allTests() -> [XCTestCaseEntry] {
		return [
			testCase(BasicSocketTests.allTests),
		]
	}
#endif
