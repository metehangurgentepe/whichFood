//
//  ThemeMode.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 3.11.2023.
//

import Foundation
import UIKit

// Tema modunu kaydetme
func saveThemeMode(mode: String) {
    UserDefaults.standard.set(mode, forKey: "themeMode")
}

// Tema modunu al
func getThemeMode() -> String? {
    return UserDefaults.standard.string(forKey: "themeMode")
}

// Uygulama başlangıcında tema modunu ayarlama
func setInitialThemeMode(mode: String) -> Void {
    if mode == "dark" {
        // Kullanıcının tercih ettiği tema modunu uygula
        return UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = .dark
        }
    } else if mode == "light" {
        // Kullanıcının tercih ettiği tema modunu uygula
        return UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = .light
        }
    }
}

