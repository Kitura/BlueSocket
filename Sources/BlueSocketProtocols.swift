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

public protocol BlueSocketReader {
	
	func readString() throws -> String?
	
	func readData(data: NSMutableData) throws -> Int
}

public protocol BlueSocketWriter {
	
	func writeData(data: NSData) throws

	func writeString(string: String) throws
}