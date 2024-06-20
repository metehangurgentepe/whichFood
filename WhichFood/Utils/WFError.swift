//
//  WFError.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 1.03.2024.
//
import Foundation

enum WFError: Error {
    case apiError
    case invalidEndpoint
    case noData
    case invalidResponse
    case serializationError
    case unableToFavorite
    case alreadyInFavorites
    case networkError
    case uploadPhotoError
    case apiUsageError
    
    var localizedDescription: String{
        switch self {
        case .apiError: return LocaleKeys.Error.apiError.rawValue.locale()
        case .invalidEndpoint: return LocaleKeys.Error.invalidEndpoint.rawValue.locale()
        case .invalidResponse: return LocaleKeys.Error.invalidResponse.rawValue.locale()
        case .noData: return LocaleKeys.Error.noData.rawValue.locale()
        case .serializationError: return LocaleKeys.Error.serializationError.rawValue.locale()
        case .unableToFavorite: return LocaleKeys.Error.unableToFavorite.rawValue.locale()
        case .alreadyInFavorites: return LocaleKeys.Error.alreadyInFavorites.rawValue.locale()
        case .networkError: return LocaleKeys.Error.networkError.rawValue.locale()
        case .uploadPhotoError: return LocaleKeys.Error.uploadPhotoError.rawValue.locale()
        case .apiUsageError: return LocaleKeys.Error.apiUsageError.rawValue.locale()
        }
    }
    var errorUserInfo: [String : Any] {
        [NSLocalizedDescriptionKey: localizedDescription]
    }
}
