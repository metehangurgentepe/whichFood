//
//  UserManager.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 10.11.2023.
//

import Foundation
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
    
    func updateUser(user: User) async throws {
        do {
            let data = try Firestore.Encoder().encode(user)
            try await userCollection.document(user.id).updateData(data)
        } catch {
            print("Error updating user: \(error)")
            throw error
        }
    }
    
    
    func createUser() async throws {
        let userId = KeychainManager.get(account: "account")
        let documentId = String(decoding:userId ?? Data(), as:UTF8.self)

        // Check initial premium status from RevenueCat
        var initialPremiumStatus = false
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            initialPremiumStatus = customerInfo.entitlements.all["pro"]?.isActive == true
        } catch {
            print("Failed to check initial premium status: \(error)")
        }

        let user = User(
            fcmToken: "",
            id: documentId,
            isPremium: initialPremiumStatus,
            numberOfUsageApi: 0,
            successNumberOfUsageApi: 0,
            lastPremiumDate: initialPremiumStatus ? Timestamp() : nil,
            premiumType: initialPremiumStatus ? "pro" : "",
            premiumUpdatedAt: Timestamp()
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
    
    #if DEBUG
    /// When on, generation bypasses the free-tier limit and the Firestore
    /// bookkeeping entirely — handy on the simulator where the user document
    /// read can fail (e.g. App Check). Toggled from Settings.
    static var debugForcePremium = UserDefaults.standard.bool(forKey: "wf.debugForcePremium") {
        didSet { UserDefaults.standard.set(debugForcePremium, forKey: "wf.debugForcePremium") }
    }
    #endif

    func increaseApiUsage() async throws {
        #if DEBUG
        if Self.debugForcePremium { return }
        #endif

        // Let the real error propagate. Previously every failure (missing user
        // doc, Firestore/network error, hit limit) collapsed into a single
        // opaque apiUsageError, which is why "Couldn't create a recipe" was
        // impossible to diagnose.
        let user = try await getUser()
        guard let user else { throw WFError.apiUsageError }

        // Free tier is capped; premium is unlimited.
        guard user.isPremium || user.numberOfUsageApi < 3 else {
            throw WFError.apiUsageError
        }
        try await userCollection.document(user.id).updateData([
            "numberOfUsageApi": user.numberOfUsageApi + 1
        ])
    }
    
    func deleteUser(completion: @escaping (Error?) -> Void) {
        let userId = KeychainManager.get(account: "account")
        let documentId = String(decoding:userId ?? Data(), as:UTF8.self)
            userCollection.document(documentId).delete { error in
                completion(error)
        }
    }

    // MARK: - RevenueCat Integration

    func checkPremiumStatus() async throws -> Bool {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            let isPremium = customerInfo.entitlements.all["pro"]?.isActive == true

            // Sync premium status to Firebase
            try await syncPremiumStatusToFirebase(isPremium: isPremium)

            return isPremium
        } catch {
            throw WFError.apiError
        }
    }

    private func syncPremiumStatusToFirebase(isPremium: Bool) async throws {
        let userId = KeychainManager.get(account: "account")
        guard let userId = userId else {
            throw WFError.noData
        }

        let documentId = String(decoding: userId, as: UTF8.self)
        let userRef = userCollection.document(documentId)

        do {
            try await userRef.updateData([
                "isPremium": isPremium,
                "lastPremiumDate": Timestamp()
            ])
            print("✅ Premium status synced to Firebase: \(isPremium)")
        } catch {
            print("❌ Failed to sync premium status to Firebase: \(error)")
            throw WFError.invalidResponse
        }
    }
}


