//
//  Data.swift
//  Todoey
//
//  Created by Angel Solorio on 2/5/19.
//  Copyright © 2019 Angel Solorio. All rights reserved.
//

import Foundation
import RealmSwift

class Category: Object {
    @objc dynamic var index: Int = 0
    @objc dynamic var name: String = ""
    @objc dynamic var color: String = ""
    @objc dynamic var dateCreated: Date = Date.init()
    let items = List<Item>()
}
