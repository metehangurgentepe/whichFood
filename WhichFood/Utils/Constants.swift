//
//  Constants.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.09.2023.
//

import Foundation
import UIKit


struct Constants {
    enum PremiumPackage: String{
        case year = "com.metehangurgentepe.WhichFood.premiumYearly"
        case month = "com.metehangurgentepe.WhichFood.premium"
    }
    enum Links: String {
        case appStoreLink = "https://apps.apple.com/tr/app/eventier/id6462756481?l=tr"
        case email = "metehangurgentepe@gmail.com"
        case termsOfService = "https://gist.github.com/metehangurgentepe/ebe86cb7265a2063500ec8fee22baba3#file-terms_of_service-md"
        case privacyPolicy = "https://gist.github.com/metehangurgentepe/ea46f5a99eba8a600e6a6bf1fe522460#file-privacy-policy-md"
    }
    enum RevenueCat: String {
        case apiKey = "appl_HHkSCFFiKhyInFriiivjyCTgdvX"
        case entitlementID = "pro"
    }
    
    enum ImageToText: String {
        case link = "https://text-in-images-recognition.p.rapidapi.com/prod"
    }
}

enum ScreenSize{
    static let width = UIScreen.main.bounds.size.width
    static let height = UIScreen.main.bounds.size.height
    static let maxLength = max(ScreenSize.width, ScreenSize.height)
    static let minLength = min(ScreenSize.width, ScreenSize.height)
}


enum Images {
    static let recipe = UIImage(named: "recipe")
    static let check = UIImage(named: "check")
    static let exit = UIImage(named: "exit_button")
    static let infinity = UIImage(named: "infinity")
    static let fork = UIImage(named: "fork")
    static let scribble = UIImage(named: "scribble")
    static let whiteImage = UIImage(named: "white_image")
    static let background = UIImage(named: "premium_background")
    static let premium = UIImage(named: "crown.fill")
    static let network = UIImage(named: "network")
    static let darkMode = UIImage(named: "sun.max.fill")
    static let email = UIImage(named: "envelope.fill")
    static let icon = UIImage(named: "AppIcon")
    static let camera = UIImage(named: "camera.fill")
    
}

enum SFSymbols {
    static let person =  UIImage(systemName: "person")
    static let playRectangle = UIImage(systemName:"play.rectangle")
    static let home = UIImage(systemName:"house")
    static let selectedHome = UIImage(systemName:"house.fill")
    static let search = UIImage(systemName: "magnifyingglass")
    static let selectedSearch = UIImage(systemName: "magnifyingglass.circle.fill")
    static let favorites = UIImage(systemName:"heart")
    static let selectedFavorites = UIImage(systemName:"heart.fill")
    static let followers = UIImage(systemName:"heart")
    static let following = UIImage(systemName:"person.2")
    static let filter = UIImage(systemName: "line.3.horizontal.decrease.circle.fill")
    static let question = UIImage(systemName: "questionmark")
    static let starFill = UIImage(systemName: "star.fill")
    static let star = UIImage(systemName: "star.fill")
    static let halfStar = UIImage(systemName: "star.lefthalf.fill")
    static let lane = UIImage(systemName: "lane")
    static let settings = UIImage(systemName: "gear")
    static let saveButton = UIImage(systemName: "externaldrive.badge.plus")
    static let copy = UIImage(systemName: "doc.on.doc")
   
}


enum DeviceTypes {
    static let idiom = UIDevice.current.userInterfaceIdiom
    static let nativeScale = UIScreen.main.nativeScale
    static let scale = UIScreen.main.scale
    
    
    static let isiPhoneSE = idiom == .phone && ScreenSize.maxLength == 568.0
    static let isiPhone8Standart = idiom == .phone && ScreenSize.maxLength == 667.0 && nativeScale == scale
    static let isiPhone8Zoomed = idiom == .phone && ScreenSize.maxLength == 667.0 && nativeScale > scale
    static let isiPhone8PlusStandart = idiom == .phone && ScreenSize.maxLength == 736.0
    static let isiPhone8PlusZoomed = idiom == .phone && ScreenSize.maxLength == 736.0 && nativeScale < scale
    static let isiPhoneX = idiom == .phone && ScreenSize.maxLength == 812.0
    static let isiPhoneXsMaxAndXr = idiom == .phone && ScreenSize.maxLength == 896.0
    static let isiPad = idiom == .phone && ScreenSize.maxLength >= 1024
    
    static func isiPhoneXAspectRatio() -> Bool {
        return isiPhoneX || isiPhoneXsMaxAndXr
    }
}

enum Categories {
    static let easy = LocaleKeys.FoodCategory.easy.rawValue.locale()
    static let mid = LocaleKeys.FoodCategory.mid.rawValue.locale()
    static let hard = LocaleKeys.FoodCategory.hard.rawValue.locale()
    static let healthy = LocaleKeys.FoodCategory.healthy.rawValue.locale()
    static let enjoy = LocaleKeys.FoodCategory.enjoy.rawValue.locale()
    static let hearty = LocaleKeys.FoodCategory.hearty.rawValue.locale()
    static let vegan = LocaleKeys.FoodCategory.vegan.rawValue.locale()
    static let dessert = LocaleKeys.FoodCategory.dessert.rawValue.locale()
    static let vegetarian = LocaleKeys.FoodCategory.vegetarian.rawValue.locale()
    static let breakfast = LocaleKeys.FoodCategory.breakfast.rawValue.locale()
    static let lunch = LocaleKeys.FoodCategory.lunch.rawValue.locale()
    static let dinner = LocaleKeys.FoodCategory.dinner.rawValue.locale()
    
    static let categoriesList: [String] = [
            easy, mid, hard, healthy, enjoy, hearty, vegan, dessert, vegetarian, breakfast, lunch, dinner
        ]
}
