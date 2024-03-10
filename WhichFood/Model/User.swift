//
//  User.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 15.09.2023.
//

import Foundation
import FirebaseFirestore

struct User: Codable{
    var fcmToken: String
    var id: String
    var isPremium: Bool
    var numberOfUsageApi: Int
    var successNumberOfUsageApi: Int
    var lastPremiumDate: Timestamp?
    var premiumType: String
}
