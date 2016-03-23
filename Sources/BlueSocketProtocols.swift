//
//  BlueSocketProtocols.swift
//  BlueSocket
//
//  Created by Bill Abt on 1/7/16.
//  Copyright © 2016 IBM. All rights reserved.
//
// 	Licensed under the Apache License, Version 2.0 (the "License");
// 	you may not use this file except in compliance with the License.
// 	You may obtain a copy of the License at
//
// 	http://www.apache.org/licenses/LICENSE-2.0
//
// 	Unless required by applicable law or agreed to in writing, software
// 	distributed under the License is distributed on an "AS IS" BASIS,
// 	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// 	See the License for the specific language governing permissions and
// 	limitations under the License.
//

import Foundation

// MARK: BlueSocketReader

public protocol BlueSocketReader {
	
	///
	/// Reads a string.
	///
	/// - Returns: Optional String
	///
	func read() throws -> String?
	
	///
	/// Reads all available data
	///
	/// - Parameter data: NSMutableData object to contain read data.
	///
	/// - Returns: Integer representing the number of bytes read.
	///
	func read(into data: NSMutableData) throws -> Int
}

// MARK: BlueSocketWriter

public protocol BlueSocketWriter {
	
	///
	/// Writes data
	///
	/// - Parameter data: NSData object containing the data to be written.
	///
	func write(from data: NSData) throws
	
	///
	/// Writes a string
	///
	/// - Parameter string: String data to be written.
	///
	func write(from string: String) throws
}