//
//  RateAppController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 13.01.2025.
//

import Foundation
import StoreKit

class RateAppController {
    static let shared = RateAppController()
    private let defaults = UserDefaults.standard
    
    private let minimumAppLaunchCount = 2
    private let daysUntilPrompt = 1
    private let promptSpacing = 3
    private let addedExpensesCount = 2
    private let minimumSpotSaves = 2  // Changed to require 2 spot saves
    
    
    private let appLaunchCountKey = "app_launch_count"
    private let firstLaunchDateKey = "first_launch_date"
    private let lastPromptDateKey = "last_prompt_date"
    private let addedExpensesCountKey = "added_expenses_count"
    private let lastShownDateKey = "last_shown_date"
    
    
    private init() {}
    
    func incrementAppLaunchCount() {
        let count = defaults.integer(forKey: appLaunchCountKey)
        defaults.set(count + 1, forKey: appLaunchCountKey)
        
        if defaults.object(forKey: firstLaunchDateKey) == nil {
            defaults.set(Date(), forKey: firstLaunchDateKey)
        }
    }
    
    func incrementAddedExpensesCount() {
        let count = defaults.integer(forKey: addedExpensesCountKey)
        defaults.set(count + 1, forKey: addedExpensesCountKey)
        
        if defaults.object(forKey: addedExpensesCountKey) == nil {
            defaults.set(1, forKey: addedExpensesCountKey)
        }
    }
    
    func shouldShowRateApp() -> Bool {
        let launchCount = defaults.integer(forKey: appLaunchCountKey)
        let firstLaunchDate = defaults.object(forKey: firstLaunchDateKey) as? Date ?? Date()
        let lastPromptDate = defaults.object(forKey: lastPromptDateKey) as? Date
        let addedExpensesCount = defaults.integer(forKey: addedExpensesCountKey)
        let lastShownDate = defaults.object(forKey: lastShownDateKey) as? Date
        
        guard launchCount >= minimumAppLaunchCount else { return false }
        
        if addedExpensesCount == 1 {
            return true
        }
        
        let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunchDate, to: Date()).day ?? 0
        guard daysSinceFirstLaunch >= daysUntilPrompt else { return false }
        
        if let lastPrompt = lastPromptDate {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastPrompt, to: Date()).day ?? 0
            guard daysSinceLastPrompt >= promptSpacing else { return false }
        }
        
        return true
    }
    
    func showRateApp() {
        if #available(iOS 14.0, *) {
            guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
            SKStoreReviewController.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview()
        }
        
        defaults.set(Date(), forKey: lastPromptDateKey)
        defaults.set(Date(), forKey: lastShownDateKey)
    }
}
