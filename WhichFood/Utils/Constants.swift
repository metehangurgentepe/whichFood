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
        case appStoreLink = "https://apps.apple.com/tr/app/whichfood/id6467032293?l=tr"
        case eventierLink = "https://apps.apple.com/tr/app/eventier/id6462756481?l=tr"
        case email = "metehangurgentepe@gmail.com"
        case termsOfService = "https://gist.github.com/metehangurgentepe/ebe86cb7265a2063500ec8fee22baba3#file-terms_of_service-md"
        case privacyPolicy = "https://gist.github.com/metehangurgentepe/ea46f5a99eba8a600e6a6bf1fe522460#file-privacy-policy-md"
        case website = "https://superlative-bienenstitch-1a1e1f.netlify.app/"
    }
    enum RevenueCat: String {
        case apiKey = "appl_HHkSCFFiKhyInFriiivjyCTgdvX"
        case entitlementID = "pro"
    }
    
    enum ImageToText: String {
        case link = "https://text-in-images-recognition.p.rapidapi.com/prod"
    }
    
    enum GeminiApiKey: String {
        case apiKey = "AIzaSyBoOyyTtptKdWjLz2EPC7tUkvt8WoGZXjU"
    }
    
    enum Api: String {
        case baseURL = "https://europe-west3-whichfood-983f1.cloudfunctions.net"
        case postData = "openAIChatCompletion"
        case generateImage = "https://europe-west3-whichfood-983f1.cloudfunctions.net/generateImage"
    }
}





