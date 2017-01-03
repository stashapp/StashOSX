//
//  JSON+Helpers.swift
//  Stash
//
//

import SwiftyJSON

extension JSON {
    public var stringArray: [String] {
        get {
            var items: [String] = []
            if self.type == .array {
                for item in arrayValue {
                    if let itemString = item.string {
                        items.append(itemString)
                    }
                }
            }
            
            return items
        }
    }
}
