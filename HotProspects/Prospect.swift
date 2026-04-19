//
//  Prospect.swift
//  HotProspects
//
//  Created by Сергей Захаров on 19.04.2026.
//

import Foundation
import SwiftData

@Model
class Prospect {
    var name: String
    var emailAddress: String
    var isContacted: Bool
    var createdAt: Date

    init(name: String, emailAddress: String, isContacted: Bool, createdAt: Date = .now) {
        self.name = name
        self.emailAddress = emailAddress
        self.isContacted = isContacted
        self.createdAt = createdAt
    }
}
