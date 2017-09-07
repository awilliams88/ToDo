//
//  Task.swift
//  ToDo
//
//  Created by Arpit Williams on 07/09/17.
//  Copyright © 2017 StarKnights. All rights reserved.
//

import Foundation
import RealmSwift

class Task: Object {
    dynamic var name = ""
    dynamic var createdAt = Date()
}
