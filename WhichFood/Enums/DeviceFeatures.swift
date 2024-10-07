import UIKit

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
    static let isiPhone11 = idiom == .phone && ScreenSize.maxLength == 896.0 && nativeScale == scale
    static let isiPhone11Pro = idiom == .phone && ScreenSize.maxLength == 1125.0 && nativeScale == scale
    static let isiPhone11ProMax = idiom == .phone && ScreenSize.maxLength == 1242.0 && nativeScale == scale
    static let isiPhone12Mini = idiom == .phone && ScreenSize.maxLength == 780.0 && nativeScale == scale
    static let isiPhone12 = idiom == .phone && ScreenSize.maxLength == 844.0 && nativeScale == scale
    static let isiPhone12Pro = idiom == .phone && ScreenSize.maxLength == 844.0 && nativeScale == scale
    static let isiPhone12ProMax = idiom == .phone && ScreenSize.maxLength == 926.0 && nativeScale == scale
    static let isiPhone13Mini = idiom == .phone && ScreenSize.maxLength == 812.0 && nativeScale == scale
    static let isiPhone13Pro = idiom == .phone && ScreenSize.maxLength == 852.0 && nativeScale == scale
    static let isiPhone13ProMax = idiom == .phone && ScreenSize.maxLength == 932.0 && nativeScale == scale
    static let isiPhone14Plus = idiom == .phone && ScreenSize.maxLength == 852.0 && nativeScale == scale
    static let isiPhone14ProMax = idiom == .phone && ScreenSize.maxLength == 932.0 && nativeScale == scale
    static let isiPhone15ProMax = idiom == .phone && ScreenSize.maxLength == 932.0 && nativeScale == scale
    static let isiPhone15Pro = idiom == .phone && ScreenSize.maxLength == 852.0 && nativeScale == scale
    static let isiPhone15Plus = idiom == .phone && ScreenSize.maxLength == 932.0 && nativeScale == scale
    static let isiPhone15 = idiom == .phone && ScreenSize.maxLength == 852.0 && nativeScale == scale
    
    static let isiPad = idiom == .pad && ScreenSize.maxLength >= 1024
    
    static func isiPhoneXAspectRatio() -> Bool {
        return isiPhoneX || isiPhoneXsMaxAndXr || isiPhone11 || isiPhone11Pro || isiPhone11ProMax || isiPhone12Mini || isiPhone12 || isiPhone12Pro || isiPhone12ProMax || isiPhone13Mini || isiPhone13Pro || isiPhone13ProMax || isiPhone14Plus || isiPhone14ProMax || isiPhone15ProMax || isiPhone15Pro || isiPhone15Plus || isiPhone15
    }
}

struct ScreenSize {
    static let width = UIScreen.main.bounds.size.width
    static let height = UIScreen.main.bounds.size.height
    static let maxLength = max(ScreenSize.width, ScreenSize.height)
    static let minLength = min(ScreenSize.width, ScreenSize.height)
}
