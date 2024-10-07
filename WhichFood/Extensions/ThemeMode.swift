//
//  ThemeMode.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 3.11.2023.
//

import Foundation
import UIKit

func saveThemeMode(mode: String) {
    UserDefaults.standard.set(mode, forKey: "themeMode")
}

func getThemeMode() -> String? {
    return UserDefaults.standard.string(forKey: "themeMode")
}


func setInitialThemeMode(mode: String) -> Void {
    if mode == "dark" {
        return UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = .dark
        }
    } else if mode == "light" {
        return UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = .light
        }
    }
}

