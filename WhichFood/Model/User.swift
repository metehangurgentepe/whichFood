//
//  User.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 15.09.2023.
//

import Foundation

struct User: Decodable{
    var fcmToken: String
    var id: String
    var isPremium: Bool
}
