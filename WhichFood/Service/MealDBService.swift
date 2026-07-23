import Foundation

/// TheMealDB — a free, keyless recipe API used to seed the Discover tab.
///
/// Its content is English-only, so it is gated to English-language users; every
/// other locale keeps seeing only the app's own generated recipes.
final class MealDBService {
    static let shared = MealDBService()

    private let baseURL = "https://www.themealdb.com/api/json/v1/1"
    private let session = URLSession.shared

    private init() {}

    /// Whether the browsing catalogue should include MealDB results at all.
    static var isAvailableForCurrentLanguage: Bool {
        let language = Bundle.main.preferredLocalizations.first ?? "en"
        return language.hasPrefix("en")
    }

    /// A handful of categories gives a reasonable spread without hammering the API.
    private let categories = ["Chicken", "Beef", "Seafood", "Vegetarian", "Pasta", "Dessert"]

    func fetchCatalog() async -> [RecipeResponseModel] {
        guard Self.isAvailableForCurrentLanguage else { return [] }

        // Category listings only carry id/name/thumb, so each meal is then
        // fetched in full to get ingredients and instructions.
        var summaries: [MealSummary] = []
        for category in categories {
            summaries.append(contentsOf: await fetchSummaries(category: category).prefix(6))
        }

        return await withTaskGroup(of: RecipeResponseModel?.self) { group in
            for summary in summaries {
                group.addTask { await self.fetchDetail(id: summary.idMeal) }
            }

            var recipes: [RecipeResponseModel] = []
            for await recipe in group {
                if let recipe { recipes.append(recipe) }
            }
            return recipes.sorted { $0.foodName < $1.foodName }
        }
    }

    func search(_ query: String) async -> [RecipeResponseModel] {
        guard Self.isAvailableForCurrentLanguage else { return [] }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search.php?s=\(encoded)")
        else { return [] }

        let meals = await fetchMeals(from: url)
        return meals.compactMap(Self.makeRecipe)
    }

    // MARK: - Requests

    private func fetchSummaries(category: String) async -> [MealSummary] {
        guard let encoded = category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/filter.php?c=\(encoded)")
        else { return [] }

        do {
            let (data, _) = try await session.data(from: url)
            return try JSONDecoder().decode(MealSummaryResponse.self, from: data).meals ?? []
        } catch {
            return []
        }
    }

    private func fetchDetail(id: String) async -> RecipeResponseModel? {
        guard let url = URL(string: "\(baseURL)/lookup.php?i=\(id)") else { return nil }
        return await fetchMeals(from: url).first.flatMap(Self.makeRecipe)
    }

    private func fetchMeals(from url: URL) async -> [Meal] {
        do {
            let (data, _) = try await session.data(from: url)
            return try JSONDecoder().decode(MealResponse.self, from: data).meals ?? []
        } catch {
            return []
        }
    }

    // MARK: - Mapping

    private static func makeRecipe(from meal: Meal) -> RecipeResponseModel? {
        guard let name = meal.strMeal, !name.isEmpty else { return nil }

        let ingredients = meal.ingredientLines
        let steps = meal.instructionSteps
        guard !ingredients.isEmpty, !steps.isEmpty else { return nil }

        var tags = [meal.strCategory, meal.strArea].compactMap { $0 }.filter { !$0.isEmpty }
        if let extra = meal.strTags?.split(separator: ",") {
            tags.append(contentsOf: extra.map { $0.trimmingCharacters(in: .whitespaces) })
        }

        return RecipeResponseModel(
            foodName: name,
            ingredients: ingredients,
            recipe: steps,
            // MealDB carries no timings; leave them unset rather than invent numbers
            cookTime: "—",
            prepTime: nil,
            totalTime: nil,
            difficulty: nil,
            servings: nil,
            description: meal.strArea.map { "\($0) classic" } ?? "",
            type: meal.strCategory?.lowercased(),
            cuisine: meal.strArea,
            allergens: nil,
            tags: tags.isEmpty ? nil : tags,
            cal: nil,
            nutritionalInfo: nil,
            tips: nil,
            imageURL: meal.strMealThumb
        )
    }
}

// MARK: - Wire format

private struct MealSummaryResponse: Decodable {
    let meals: [MealSummary]?
}

private struct MealSummary: Decodable {
    let idMeal: String
}

private struct MealResponse: Decodable {
    let meals: [Meal]?
}

/// TheMealDB returns ingredients as 20 flat `strIngredient1…20` / `strMeasure1…20`
/// pairs rather than an array, so they are decoded by key and recombined.
private struct Meal: Decodable {
    let strMeal: String?
    let strCategory: String?
    let strArea: String?
    let strInstructions: String?
    let strMealThumb: String?
    let strTags: String?

    private let ingredients: [String?]
    private let measures: [String?]

    private struct DynamicKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)

        func string(_ key: String) -> String? {
            guard let codingKey = DynamicKey(stringValue: key) else { return nil }
            return try? container.decodeIfPresent(String.self, forKey: codingKey)
        }

        strMeal = string("strMeal")
        strCategory = string("strCategory")
        strArea = string("strArea")
        strInstructions = string("strInstructions")
        strMealThumb = string("strMealThumb")
        strTags = string("strTags")

        ingredients = (1...20).map { string("strIngredient\($0)") }
        measures = (1...20).map { string("strMeasure\($0)") }
    }

    /// "2 tbsp Olive Oil" — measure first so the app's servings scaler, which
    /// reads the leading number, can rescale it.
    var ingredientLines: [String] {
        zip(ingredients, measures).compactMap { ingredient, measure in
            let name = ingredient?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty else { return nil }

            let amount = measure?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return amount.isEmpty ? name : "\(amount) \(name)"
        }
    }

    var instructionSteps: [String] {
        guard let text = strInstructions else { return [] }

        return text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 2 }
            // Some entries prefix steps with "1." / "STEP 1"
            .map { $0.replacingOccurrences(of: "^(STEP\\s*)?\\d+[.)]\\s*", with: "", options: [.regularExpression, .caseInsensitive]) }
            .filter { !$0.isEmpty }
    }
}
