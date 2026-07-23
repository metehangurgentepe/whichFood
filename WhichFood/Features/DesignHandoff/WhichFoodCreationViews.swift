import SwiftUI
import UIKit

enum WFRecipeCreationMode {
    case ingredients
    case photo(UIImage)
    /// Free-text description typed by the user.
    case prompt(String)
}

private enum WFCreationStage {
    case preferences
    case ingredients
    case generating
    case recipe
    case failed
}

struct WFRecipeCreationFlow: View {
    let mode: WFRecipeCreationMode
    @ObservedObject var appState: WhichFoodAppState
    @Environment(\.dismiss) private var dismiss

    @State private var stage: WFCreationStage
    @State private var preferences = Set<String>()
    @State private var selectedIngredientNames = Set<String>()
    @State private var generatedRecipe: RecipeResponseModel?
    @State private var showReview = false
    @State private var didStartPhoto = false

    init(mode: WFRecipeCreationMode, appState: WhichFoodAppState) {
        self.mode = mode
        self.appState = appState
        switch mode {
        case .ingredients: _stage = State(initialValue: .preferences)
        case .photo, .prompt: _stage = State(initialValue: .generating)
        }
    }

    var body: some View {
        ZStack {
            switch stage {
            case .preferences:
                WFPreferencesView(
                    selected: $preferences,
                    back: { dismiss() },
                    next: { withAnimation(.easeInOut(duration: 0.2)) { stage = .ingredients } }
                )
            case .ingredients:
                WFIngredientSelectionView(
                    selectedNames: $selectedIngredientNames,
                    back: { withAnimation(.easeInOut(duration: 0.2)) { stage = .preferences } },
                    review: { showReview = true }
                )
            case .generating:
                WFGenerationLoadingView(mode: loadingMode)
                    .transition(.opacity)
            case .recipe:
                if let generatedRecipe {
                    WFRecipeDetailView(
                        initialRecipe: generatedRecipe,
                        isSaved: false,
                        appState: appState,
                        close: { dismiss() }
                    )
                }
            case .failed:
                WFFailedGenerationView(
                    retry: { startGeneration() },
                    close: { dismiss() }
                )
            }

            if showReview {
                WFSelectedIngredientsSheet(
                    selectedNames: $selectedIngredientNames,
                    dismiss: { showReview = false },
                    generate: {
                        showReview = false
                        startGeneration()
                    }
                )
                .transition(.opacity)
                .zIndex(4)
            }
        }
        .onAppear {
            switch mode {
            case .photo, .prompt: break
            case .ingredients: return
            }
            guard !didStartPhoto else { return }
            didStartPhoto = true
            startGeneration()
        }
    }

    private var loadingMode: WFGenerationLoadingView.Mode {
        switch mode {
        case .ingredients: return .ingredients
        case .photo, .prompt: return .photo
        }
    }

    private func startGeneration() {
        withAnimation { stage = .generating }
        Task {
            let recipe: RecipeResponseModel?
            switch mode {
            case .ingredients:
                let ingredients = Ingredient.allIngredients().filter { selectedIngredientNames.contains($0.name) }
                recipe = await appState.generateRecipe(
                    ingredients: ingredients,
                    preferences: Array(preferences)
                )
            case .photo(let image):
                recipe = await appState.generateRecipe(from: image)
            case .prompt(let text):
                recipe = await appState.generateRecipe(fromDescription: text)
            }

            await MainActor.run {
                if let recipe {
                    generatedRecipe = recipe
                    withAnimation(.easeInOut(duration: 0.25)) { stage = .recipe }
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) { stage = .failed }
                }
            }
        }
    }
}

private struct WFPreferencesView: View {
    @Binding var selected: Set<String>
    let back: () -> Void
    let next: () -> Void

    private let options = [
        "Easy", "Medium", "Difficult", "Healthy", "Vegan", "Vegetarian",
        "Breakfast", "Lunch", "Dinner", "Dessert", "Hearty"
    ]
    private let columns = [GridItem(.adaptive(minimum: 92), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WFIconButton(systemName: "chevron.left", action: back)
                .padding(.bottom, 22)
            Text("What are you in the mood for?")
                .font(WFFont.heading(25, weight: .bold))
                .foregroundColor(WFPalette.text)
            Text("Pick as many as you like — we'll shape the recipe around them.")
                .font(WFFont.body(14))
                .foregroundColor(WFPalette.secondaryText)
                .lineSpacing(3)
                .padding(.top, 8)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(options, id: \.self) { option in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if selected.contains(option) { selected.remove(option) } else { selected.insert(option) }
                    } label: {
                        Text(option)
                            .font(WFFont.body(14, weight: .semibold))
                            .foregroundColor(selected.contains(option) ? .white : WFPalette.text)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(selected.contains(option) ? WFPalette.orange : WFPalette.card)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(selected.contains(option) ? Color.clear : WFPalette.border, lineWidth: 1.5))
                    }
                    .buttonStyle(WFPressButtonStyle())
                }
            }
            .padding(.top, 24)
            Spacer()
            Button("Choose ingredients", action: next)
                .buttonStyle(WFPrimaryButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 30)
        .wfScreenBackground()
    }
}

private struct WFIngredientSelectionView: View {
    @Binding var selectedNames: Set<String>
    let back: () -> Void
    let review: () -> Void

    @State private var query = ""
    @State private var activeCategory: CategoryModel = .vegetable

    private let categories: [CategoryModel] = [.vegetable, .meat, .dairy, .grain, .fruit, .seafood, .herb, .nut]
    private let columns = [GridItem(.adaptive(minimum: 105), spacing: 10)]

    private var visibleIngredients: [Ingredient] {
        let all = Ingredient.allIngredients()
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return all.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        return all.filter { $0.category == activeCategory }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    WFIconButton(systemName: "chevron.left", action: back)
                    Text("What's in your kitchen?")
                        .font(WFFont.heading(19, weight: .bold))
                        .foregroundColor(WFPalette.text)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                WFSearchField(text: $query, placeholder: "Search ingredients…")
                    .padding(.horizontal, 24)
                    .padding(.top, 14)

                if query.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.rawValue) { category in
                                WFChip(
                                    title: category.localizedValue,
                                    selected: activeCategory == category,
                                    darkSelection: true
                                ) { activeCategory = category }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 14)
                }

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                        ForEach(uniqueIngredients, id: \.name) { ingredient in
                            let selected = selectedNames.contains(ingredient.name)
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if selected { selectedNames.remove(ingredient.name) }
                                else { selectedNames.insert(ingredient.name) }
                            } label: {
                                HStack(spacing: 6) {
                                    if selected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    Text(ingredient.name)
                                        .font(WFFont.body(13, weight: .semibold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .foregroundColor(selected ? .white : WFPalette.text)
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .padding(.horizontal, 8)
                                .background(selected ? WFPalette.orange : WFPalette.card)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(selected ? Color.clear : WFPalette.border, lineWidth: 1.5))
                            }
                            .buttonStyle(WFPressButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, selectedNames.isEmpty ? 24 : 108)
                }
            }
            .wfScreenBackground()

            if !selectedNames.isEmpty {
                Button(action: review) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(selectedNames.count) ingredients selected")
                                .font(WFFont.heading(14, weight: .bold))
                            Text("Ready to turn them into a recipe")
                                .font(WFFont.body(11.5))
                                .foregroundColor(.white.opacity(0.68))
                        }
                        Spacer()
                        HStack(spacing: 5) {
                            Text("Review")
                            Image(systemName: "chevron.right")
                        }
                        .font(WFFont.body(13, weight: .bold))
                        .foregroundColor(WFPalette.amber)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 68)
                    .background(WFPalette.dark)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: WFPalette.text.opacity(0.2), radius: 18, y: 8)
                }
                .buttonStyle(WFPressButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.3), value: selectedNames.isEmpty)
    }

    private var uniqueIngredients: [Ingredient] {
        var seen = Set<String>()
        return visibleIngredients.filter { seen.insert($0.name).inserted }
    }
}

private struct WFSelectedIngredientsSheet: View {
    @Binding var selectedNames: Set<String>
    let dismiss: () -> Void
    let generate: () -> Void
    private let columns = [GridItem(.adaptive(minimum: 105), spacing: 9)]

    var body: some View {
        ZStack(alignment: .bottom) {
            WFPalette.text.opacity(0.45).ignoresSafeArea().onTapGesture(perform: dismiss)
            VStack(alignment: .leading, spacing: 0) {
                Capsule().fill(WFPalette.tertiaryText).frame(width: 38, height: 5)
                    .frame(maxWidth: .infinity).padding(.top, 10)
                Text("Your ingredients")
                    .font(WFFont.heading(22, weight: .bold))
                    .foregroundColor(WFPalette.text)
                    .padding(.top, 18)
                Text("Tap any item to remove it.")
                    .font(WFFont.body(13))
                    .foregroundColor(WFPalette.secondaryText)
                    .padding(.top, 4)
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 9) {
                        ForEach(Array(selectedNames).sorted(), id: \.self) { name in
                            Button {
                                selectedNames.remove(name)
                                if selectedNames.isEmpty { dismiss() }
                            } label: {
                                HStack(spacing: 5) {
                                    Text(name).lineLimit(1).minimumScaleFactor(0.8)
                                    Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
                                }
                                .font(WFFont.body(12.5, weight: .semibold))
                                .foregroundColor(WFPalette.selectedText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .padding(.horizontal, 8)
                                .background(WFPalette.selectedBackground)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 18)
                }
                .frame(maxHeight: 260)
                Button(action: generate) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles").foregroundColor(WFPalette.amber)
                        Text("Generate my recipe")
                    }
                }
                .buttonStyle(WFPrimaryButtonStyle(enabled: !selectedNames.isEmpty))
                .disabled(selectedNames.isEmpty)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
            .background(WFPalette.background)
            .clipShape(WFRoundedCorners(radius: 26, corners: [.topLeft, .topRight]))
            .shadow(color: WFPalette.text.opacity(0.2), radius: 24, y: -8)
        }
    }
}

struct WFGenerationLoadingView: View {
    enum Mode { case ingredients, photo, remix }
    let mode: Mode
    @State private var spin = false
    @State private var pulse = false

    private var copy: (String, String) {
        switch mode {
        case .ingredients:
            return ("Cooking up your recipe…", "Balancing your ingredients, preferences and skill level.")
        case .photo:
            return ("Reading your dish…", "Identifying ingredients, technique and cuisine from your photo.")
        case .remix:
            return ("Remixing your recipe…", "Rebalancing ingredients, steps and timing around your twist.")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                Circle()
                    .fill(WFPalette.amber.opacity(pulse ? 0.08 : 0.22))
                    .frame(width: pulse ? 136 : 108, height: pulse ? 136 : 108)
                Circle()
                    .stroke(WFPalette.border, lineWidth: 6)
                    .frame(width: 104, height: 104)
                Circle()
                    .trim(from: 0, to: 0.27)
                    .stroke(WFPalette.orange, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 104, height: 104)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                Image(systemName: "fork.knife")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(WFPalette.orange)
            }
            Text(copy.0)
                .font(WFFont.heading(22, weight: .bold))
                .foregroundColor(WFPalette.text)
                .padding(.top, 30)
            Text(copy.1)
                .font(WFFont.body(14))
                .foregroundColor(WFPalette.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 38)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 12) {
                ForEach([1.0, 0.8, 0.6], id: \.self) { fraction in
                    GeometryReader { proxy in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(WFPalette.border.opacity(0.8))
                            .frame(width: proxy.size.width * fraction, height: 10)
                    }
                    .frame(height: 10)
                }
            }
            .padding(.horizontal, 54)
            .padding(.top, 38)
            Spacer()
        }
        .wfScreenBackground()
        .onAppear {
            withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) { spin = true }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

private struct WFFailedGenerationView: View {
    let retry: () -> Void
    let close: () -> Void
    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 42, weight: .medium))
                .foregroundColor(WFPalette.orange)
            Text("We couldn't finish that recipe")
                .font(WFFont.heading(21, weight: .bold))
            Text("Check your connection and try again. Your selections are still here.")
                .font(WFFont.body(14))
                .foregroundColor(WFPalette.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
            Button("Try again", action: retry).buttonStyle(WFPrimaryButtonStyle())
            Button("Close", action: close)
                .font(WFFont.body(14, weight: .semibold))
                .foregroundColor(WFPalette.secondaryText)
                .frame(height: 44)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .wfScreenBackground()
    }
}
