//
//  UserManager.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 10.11.2023.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore
import RevenueCat

enum ApiUsageError: Error {
    case exceededApiLimit
}

enum PremiumType: String {
    case week = "Week"
    case annual = "Annual"
    case rcWeek = "$rc_weekly"
    case rcAnnual = "$rc_annual"
}


enum PremiumError: Error {
    case makePremiumError
}

class UserManager{
    static let shared = UserManager()
    private let userCollection = Firestore.firestore().collection("users")
    
    private init(){}
    
    func getUser() async throws -> User? {
        let userId = KeychainManager.get(account: "account")
        let documentId = String(decoding:userId ?? Data(), as:UTF8.self)
        
        return try await userCollection.document(documentId).getDocument(as: User.self)
    }
    
    func getUserId() -> String? {
        var userId : String?
        Purchases.shared.getCustomerInfo {info, error in
            if error != nil {
                userId = nil
            }
            
            if let info = info {
               userId = info.originalAppUserId
            }
        }
        return userId
    }
    
    
    func createUser() async throws {
        let userId = KeychainManager.get(account: "account")
        let documentId = String(decoding:userId ?? Data(), as:UTF8.self)
        let user = User(
            fcmToken: "",
            id: documentId,
            isPremium: false,
            numberOfUsageApi: 0,
            successNumberOfUsageApi: 0,
            lastPremiumDate: nil,
            premiumType: ""
        )
        let data = try Firestore.Encoder().encode(user)
        try await userCollection.document(documentId).setData(data)
       
    }
    
    // make premium user
    func makeUserPremium(subscribeType: String) async throws {
        let userId = KeychainManager.get(account: "account")
        let documentId = String(decoding:userId ?? Data(), as:UTF8.self)
        
        switch subscribeType {
        case PremiumType.rcWeek.rawValue:
            let timestamp = Timestamp(date: Date())
            let type = PremiumType.week.rawValue
            let data: [String: Any] = [
                "lastPremiumDate": timestamp,
                "premiumType": type,
                "isPremium": true
            ]
            try await userCollection.document(documentId).updateData(data)
        case PremiumType.rcAnnual.rawValue:
            let timestamp = Timestamp(date: Date())
            let type = PremiumType.annual.rawValue
            let data: [String: Any] = [
                "lastPremiumDate": timestamp,
                "premiumType": type,
                "isPremium": true
            ]
            try await userCollection.document(documentId).updateData(data)
        default:
            throw PremiumError.makePremiumError
        }
    }
    
    func makeUserNullPremium() async throws{
        let userId = KeychainManager.get(account: "account")
        let documentId = String(decoding:userId ?? Data(), as:UTF8.self)
        
        let timestamp = Timestamp(date: Date())
        let data: [String: Any] = [
            "lastPremiumDate": timestamp,
            "premiumType": "",
            "isPremium": false
        ]
        
        try await userCollection.document(documentId).updateData(data)
    }
    
    func increaseApiUsage() async throws{
        do {
            let user = try await getUser()
            if let user = user{
                if !user.isPremium && user.numberOfUsageApi <= 3{
                    try await userCollection.document(user.id).updateData(["numberOfUsageApi" : user.numberOfUsageApi + 1])
                } else if user.isPremium {
                    try await userCollection.document(user.id).updateData(["numberOfUsageApi" : user.numberOfUsageApi + 1])
                } else {
                    throw WFError.apiUsageError
                }
            }
        } catch {
           throw WFError.apiUsageError
        }
    }
    
    func deleteUser(completion: @escaping (Error?) -> Void) {
        let userId = KeychainManager.get(account: "account")
        let documentId = String(decoding:userId ?? Data(), as:UTF8.self)
            userCollection.document(documentId).delete { error in
                completion(error)
        }
    }
}


