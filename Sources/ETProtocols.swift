//
//  ETProtocols.swift
//  ETSocket
//
//  Created by Bill Abt on 1/7/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

public protocol ETReader {
	
	func readData(buffer: UnsafeMutablePointer<CChar>, bufSize: Int) throws ->Int
	
	func readData(data: NSMutableData) throws ->Int
}

public protocol ETWriter {
	
	func writeData(buffer: UnsafePointer<Void>, bufSize: Int) throws
	
	func writeData(data: NSData) throws
}