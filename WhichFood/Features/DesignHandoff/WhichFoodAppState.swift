import Foundation
import SwiftUI
import UIKit
import FirebaseStorage
import RevenueCat

@MainActor
final class WhichFoodAppState: ObservableObject {
    @Published var savedRecipes: [Recipe] = []
    @Published var catalogRecipes: [Recipe] = []
    @Published var favoriteRecipes: [RecipeResponseModel] = []
    /// Browsable recipes from TheMealDB. Empty for non-English users.
    @Published var externalRecipes: [RecipeResponseModel] = []
    @Published var isLoadingLibrary = false
    #if DEBUG
    /// When true (screenshot capture mode), the async loaders are no-ops so the
    /// injected mock recipes aren't overwritten by empty persistence/network data.
    var isScreenshotSeeded = false
    #endif
    @Published var isGenerating = false
    @Published var errorMessage: String?
    /// True when the most recent generation failed because the free-tier limit
    /// was reached — the creation flow shows the paywall instead of an error.
    @Published var hitUsageLimit = false
    @Published var currentUser: User?
    @Published var isPremium = false

    #if DEBUG
    /// Debug-only premium override, surfaced as a toggle in Settings.
    @Published var debugPremiumOverride = UserManager.debugForcePremium {
        didSet {
            UserManager.debugForcePremium = debugPremiumOverride
            objectWillChange.send()
        }
    }
    #endif

    /// Premium as far as the UI is concerned — real entitlement, or the debug override.
    var effectiveIsPremium: Bool {
        #if DEBUG
        if debugPremiumOverride { return true }
        #endif
        return isPremium
    }

    var generationsLeft: Int {
        #if DEBUG
        if debugPremiumOverride { return 999 }
        #endif
        guard let currentUser else { return 3 }
        return currentUser.isPremium ? 999 : max(0, 3 - currentUser.numberOfUsageApi)
    }

    func loadAll() async {
        #if DEBUG
        if isScreenshotSeeded { return }
        #endif
        async let library: Void = loadLibrary()
        async let catalog: Void = loadCatalog()
        async let favorites: Void = loadFavorites()
        async let user: Void = loadUser()
        async let external: Void = loadExternalRecipes()
        _ = await (library, catalog, favorites, user, external)
    }

    func loadExternalRecipes() async {
        // Silent on failure: this is supplementary browsing content, not
        // something worth interrupting the user with.
        externalRecipes = await MealDBService.shared.fetchCatalog()
    }

    func loadLibrary() async {
        #if DEBUG
        if isScreenshotSeeded { return }
        #endif
        isLoadingLibrary = true
        defer { isLoadingLibrary = false }
        do {
            savedRecipes = try await SavedRecipesManager.shared.getAllRecipesByUser()
                .sorted { $0.createdAt.dateValue() > $1.createdAt.dateValue() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadCatalog() async {
        do {
            catalogRecipes = try await SavedRecipesManager.shared.getRecipes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadFavorites() async {
        #if DEBUG
        if isScreenshotSeeded { return }
        #endif
        await withCheckedContinuation { continuation in
            PersistenceManager.retrieveFavorites { result in
                Task { @MainActor in
                    switch result {
                    case .success(let recipes): self.favoriteRecipes = recipes
                    case .failure(let error): self.errorMessage = error.localizedDescription
                    }
                    continuation.resume()
                }
            }
        }
    }

    func loadUser() async {
        do {
            currentUser = try await UserManager.shared.getUser()
            let customerInfo = try? await Purchases.shared.customerInfo()
            isPremium = customerInfo?.entitlements.all["pro"]?.isActive == true
        } catch {
            // The cooking experience remains usable while account metadata is unavailable.
        }
    }

    func isFavorite(_ recipe: RecipeResponseModel) -> Bool {
        favoriteRecipes.contains { recipeKey($0) == recipeKey(recipe) }
    }

    func toggleFavorite(_ recipe: RecipeResponseModel) {
        let adding = !isFavorite(recipe)
        PersistenceManager.updateWith(
            favorite: recipe,
            actionType: adding ? .add : .remove
        ) { [weak self] error in
            Task { @MainActor in
                if let error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    await self?.loadFavorites()
                }
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(adding ? .success : .warning)
    }

    func delete(_ recipe: Recipe) async {
        SavedRecipesManager.shared.deleteRecipeByUserID(id: recipe.id)
        savedRecipes.removeAll { $0.id == recipe.id }
    }

    func save(_ recipe: RecipeResponseModel) async -> Bool {
        do {
            try await SavedRecipesManager.shared.saveRecipe(
                name: recipe.foodName,
                recipe: recipe.recipe,
                ingredients: recipe.ingredients,
                desc: recipe.description,
                cookTime: recipe.cookTime,
                type: recipe.type ?? "general",
                imageURL: recipe.imageURL ?? "",
                prepTime: recipe.prepTime,
                totalTime: recipe.totalTime,
                difficulty: recipe.difficulty,
                servings: recipe.servings,
                cuisine: recipe.cuisine,
                tags: recipe.tags,
                cal: recipe.cal,
                nutritionalInfo: recipe.nutritionalInfo,
                allergens: recipe.allergens,
                tips: recipe.tips
            )
            await loadLibrary()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return true
        } catch {
            errorMessage = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return false
        }
    }

    /// Free-text path: the user describes what they want in their own words.
    func generateRecipe(fromDescription description: String) async -> RecipeResponseModel? {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        isGenerating = true
        hitUsageLimit = false
        defer { isGenerating = false }

        do {
            try await UserManager.shared.increaseApiUsage()
            let language = Bundle.main.preferredLocalizations.first ?? "en"
            let profile = onboardingProfile
            let prompt = """
            Create one realistic, complete recipe in language code \(language).
            The user asked for: \(trimmed)
            User cooking profile: \(profile).
            Honour the request as closely as possible. If it is vague, make sensible choices.
            Return only valid JSON matching this schema, with no markdown:
            \(recipeJSONSchema)
            """
            guard let response = try await GeminiManager.shared.fetchRecipe(prompt: prompt) else {
                throw WFError.noData
            }
            var recipe = try decodeRecipe(from: response)
            recipe.imageURL = await generateAndUploadImage(for: recipe.foodName)
            await loadUser()
            return recipe
        } catch {
            recordGenerationFailure(error)
            return nil
        }
    }

    func generateRecipe(ingredients: [Ingredient], preferences: [String]) async -> RecipeResponseModel? {
        guard !ingredients.isEmpty else { return nil }
        isGenerating = true
        hitUsageLimit = false
        defer { isGenerating = false }

        do {
            try await UserManager.shared.increaseApiUsage()
            let language = Bundle.main.preferredLocalizations.first ?? "en"
            let profile = onboardingProfile
            let prompt = """
            Create one realistic, complete recipe in language code \(language).
            Available ingredients: \(ingredients.map(\.name).joined(separator: ", ")).
            Mood and preferences: \(preferences.joined(separator: ", ")).
            User cooking profile: \(profile).
            Use the available ingredients as the foundation. Basic pantry staples may be added when needed.
            Return only valid JSON matching this schema, with no markdown:
            \(recipeJSONSchema)
            """
            guard let response = try await GeminiManager.shared.fetchRecipe(prompt: prompt) else {
                throw WFError.noData
            }
            var recipe = try decodeRecipe(from: response)
            recipe.imageURL = await generateAndUploadImage(for: recipe.foodName)
            await loadUser()
            return recipe
        } catch {
            recordGenerationFailure(error)
            return nil
        }
    }

    func generateRecipe(from image: UIImage) async -> RecipeResponseModel? {
        isGenerating = true
        hitUsageLimit = false
        defer { isGenerating = false }

        do {
            try await UserManager.shared.increaseApiUsage()
            let language = Bundle.main.preferredLocalizations.first ?? "en"
            let prompt = """
            Identify the dish in this photo and create a realistic, detailed recipe in language code \(language).
            Include quantities, clear cooking steps, timing, servings, difficulty, cuisine, allergens,
            tags, nutrition estimates and one useful chef tip. Return only valid JSON matching:
            \(recipeJSONSchema)
            """
            guard let response = try await GeminiManager.shared.generateRecipeFromImage(image: image, prompt: prompt) else {
                throw WFError.noData
            }
            var recipe = try decodeRecipe(from: response)
            recipe.imageURL = try? await upload(image: image, folder: "food_photos")
            await loadUser()
            return recipe
        } catch {
            recordGenerationFailure(error)
            return nil
        }
    }

    func remix(_ recipe: RecipeResponseModel, twist: String) async -> RecipeResponseModel? {
        isGenerating = true
        hitUsageLimit = false
        defer { isGenerating = false }
        do {
            try await UserManager.shared.increaseApiUsage()
            let data = try JSONEncoder().encode(recipe)
            let original = String(data: data, encoding: .utf8) ?? "{}"
            let prompt = """
            Rewrite this recipe with the following twist: \(twist).
            Keep it realistic and update the name, ingredients, timing, instructions, tags, nutrition and chef tip.
            Original recipe: \(original)
            Return only valid JSON matching: \(recipeJSONSchema)
            """
            guard let response = try await GeminiManager.shared.fetchRecipe(prompt: prompt) else {
                throw WFError.noData
            }
            var remixed = try decodeRecipe(from: response)
            remixed.imageURL = await generateAndUploadImage(for: remixed.foodName)
            await loadUser()
            return remixed
        } catch {
            recordGenerationFailure(error)
            return nil
        }
    }

    private var onboardingProfile: String {
        let defaults = UserDefaults.standard
        let skill = defaults.string(forKey: "userCookingSkill") ?? "not specified"
        let tools = defaults.stringArray(forKey: "userKitchenTools") ?? []
        let restrictions = defaults.stringArray(forKey: "userDietaryRestrictions") ?? []
        let people = defaults.integer(forKey: "userPeopleCount")
        return "skill=\(skill); tools=\(tools.joined(separator: ", ")); dietary=\(restrictions.joined(separator: ", ")); servings=\(max(1, people))"
    }

    private var recipeJSONSchema: String {
        """
        {"foodName":"","ingredients":[""],"recipe":[""],"cookTime":"","prepTime":"","totalTime":"","difficulty":"","servings":"","description":"","type":"","cuisine":"","allergens":[""],"tags":[""],"cal":{"carbs":"","fat":"","protein":"","totalCalories":""},"nutritionalInfo":{"sugar":"","fiber":"","sodium":"","cholesterol":""},"tips":[""]}

        Formatting rules (follow exactly):
        - Write ALL human-readable text (foodName, every ingredient name, every instruction, description, tags, difficulty, tips) in the requested language. Keep the JSON keys in English and keep units (g, kcal, min) unchanged.
        - "servings": a plain integer as a string, e.g. "4". No words.
        - "ingredients": every item MUST start with a numeric quantity and unit, then the ingredient name, e.g. "2 cups flour", "200 g chicken breast", "1 tbsp olive oil", "3 eggs". Never put the name before the number. Use digits, never spelled-out numbers. Quantities must correspond to exactly the "servings" count above so they can be scaled.
        - "cal": nutrition PER SINGLE SERVING. "carbs", "fat", "protein" are grams written as a number followed by " g" (e.g. "24 g"). "totalCalories" is a number followed by " kcal" (e.g. "540 kcal"). Never leave any of these blank; always provide a realistic estimate.
        - "cookTime"/"prepTime"/"totalTime": a number followed by " min" (e.g. "25 min").
        - "difficulty": one of "Easy", "Medium", "Hard".
        """
    }

    private func decodeRecipe(from response: String) throws -> RecipeResponseModel {
        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let json: String
        if cleaned.hasPrefix("{") && cleaned.hasSuffix("}") {
            json = cleaned
        } else if let start = cleaned.firstIndex(of: "{"), let end = cleaned.lastIndex(of: "}") {
            json = String(cleaned[start...end])
        } else {
            throw WFError.invalidResponse
        }
        guard let data = json.data(using: .utf8) else { throw WFError.noData }
        return try JSONDecoder().decode(RecipeResponseModel.self, from: data)
    }

    private func generateAndUploadImage(for foodName: String) async -> String? {
        do {
            guard let image = try await GeminiManager.shared.generateFoodImage(
                prompt: "Professional natural-light editorial food photography of \(foodName), warm styling, overhead three-quarter angle, no text"
            ) else { return nil }
            return try await upload(image: image, folder: "foodImages")
        } catch {
            return nil
        }
    }

    private func upload(image: UIImage, folder: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.72) else {
            throw WFError.uploadPhotoError
        }
        let reference = Storage.storage().reference().child("\(folder)/\(UUID().uuidString).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await reference.putDataAsync(data, metadata: metadata)
        return try await reference.downloadURL().absoluteString
    }

    private func recordGenerationFailure(_ error: Error) {
        errorMessage = error.localizedDescription
        if case WFError.apiUsageError = error {
            hitUsageLimit = true
        }
    }

    private func recipeKey(_ recipe: RecipeResponseModel) -> String {
        recipe.foodName.lowercased() + "|" + recipe.ingredients.joined(separator: "|").lowercased()
    }
}

extension RecipeResponseModel {
    var wfIdentifier: String {
        foodName + "|" + ingredients.joined(separator: "|") + "|" + cookTime
    }
}
