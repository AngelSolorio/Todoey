//
//  Item.swift
//  Todoey
//
//  Created by Angel Solorio on 1/27/19.
//  Copyright © 2019 Angel Solorio. All rights reserved.
//

import Foundation

class Item: Codable {
    var title: String = ""
    var done: Bool = false

    init(title: String) {
        self.title = title
    }

    init(title: String, isDone: Bool) {
        self.title = title
        self.done = isDone
    }
}
