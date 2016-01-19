//
//  ETProtocols.swift
//  ETSocket
//
//  Created by Bill Abt on 1/7/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

public protocol ETReader {
	
	func readString() throws ->String?
	
	func readData(data: NSMutableData) throws ->Int
}

public protocol ETWriter {
	
	func writeData(data: NSData) throws

	func writeString(string: String) throws
}