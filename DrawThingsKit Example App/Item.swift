//
//  Item.swift
//  DrawThingsKit Example App
//
//  Created by Brian Cantin on 2025-11-30.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
