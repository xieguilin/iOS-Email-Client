//
//  Account.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/5/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Account: Object{
    @objc dynamic var username = ""
    @objc dynamic var name = ""
    @objc dynamic var password = ""
    @objc dynamic var jwt = ""
    @objc dynamic var rawIdentityKeyPair = ""
    @objc dynamic var regId = 0
    
    override static func primaryKey() -> String? {
        return "username"
    }
}
