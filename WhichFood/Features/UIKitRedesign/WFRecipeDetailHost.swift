import SwiftUI
import UIKit

/// Bridges the UIKit detail screen into the still-SwiftUI home, so the
/// migration can proceed one screen at a time.
struct WFRecipeDetailHost: UIViewControllerRepresentable {
    let recipe: RecipeResponseModel
    let isSaved: Bool
    let appState: WhichFoodAppState
    let close: () -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let detail = WFRecipeDetailViewController(
            recipe: recipe,
            isSaved: isSaved,
            appState: appState,
            close: close
        )
        let navigation = UINavigationController(rootViewController: detail)
        navigation.navigationBar.isTranslucent = true
        return navigation
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

/// Bridges the UIKit home screen into the SwiftUI tab bar.
struct WFHomeHost: UIViewControllerRepresentable {
    let appState: WhichFoodAppState
    let createFromIngredients: () -> Void
    let createFromPhoto: () -> Void
    let openRecipe: (RecipeResponseModel) -> Void

    func makeUIViewController(context: Context) -> WFHomeViewController {
        WFHomeViewController(
            appState: appState,
            createFromIngredients: createFromIngredients,
            createFromPhoto: createFromPhoto,
            createFromPrompt: { _ in },
            openRecipe: openRecipe
        )
    }

    func updateUIViewController(_ uiViewController: WFHomeViewController, context: Context) {}
}
