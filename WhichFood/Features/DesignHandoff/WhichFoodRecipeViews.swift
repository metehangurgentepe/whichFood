import SwiftUI
import UIKit

struct WFRecipeDetailView: View {
    @State private var recipe: RecipeResponseModel
    @State private var saved: Bool
    @ObservedObject var appState: WhichFoodAppState
    let close: () -> Void

    @State private var servings: Int
    @State private var checkedIngredients = Set<Int>()
    @State private var showCookingMode = false
    @State private var showRemixSheet = false
    @State private var remixing = false
    @State private var showShare = false

    private let baseServings: Int

    init(initialRecipe: RecipeResponseModel, isSaved: Bool, appState: WhichFoodAppState, close: @escaping () -> Void) {
        _recipe = State(initialValue: initialRecipe)
        _saved = State(initialValue: isSaved)
        self.appState = appState
        self.close = close
        let parsed = Self.parseServings(initialRecipe.servings)
        baseServings = parsed
        _servings = State(initialValue: parsed)
    }

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                // Native navigation bar: system back/heart/share items sitting on a
                // transparent bar so the hero photo shows through behind them.
                NavigationStack {
                    content(showsOverlayButtons: false)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(.hidden, for: .navigationBar)
                        .toolbarColorScheme(.dark, for: .navigationBar)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: close) {
                                    Image(systemName: "chevron.left")
                                }
                            }
                            ToolbarItemGroup(placement: .navigationBarTrailing) {
                                Button { appState.toggleFavorite(recipe) } label: {
                                    Image(systemName: appState.isFavorite(recipe) ? "heart.fill" : "heart")
                                }
                                Button { showShare = true } label: {
                                    Image(systemName: "square.and.arrow.up")
                                }
                            }
                        }
                }
            } else {
                content(showsOverlayButtons: true)
            }
        }
        .fullScreenCover(isPresented: $showCookingMode) {
            WFCookingModeView(steps: recipe.recipe)
        }
        .sheet(isPresented: $showShare) {
            WFActivityView(items: [shareText])
        }
    }

    private func content(showsOverlayButtons: Bool) -> some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    hero(showsOverlayButtons: showsOverlayButtons)
                    VStack(alignment: .leading, spacing: 0) {
                        tags
                        Text(recipe.foodName)
                            .font(WFFont.heading(24, weight: .bold))
                            .foregroundColor(WFPalette.text)
                            .padding(.top, 14)
                        if !recipe.description.isEmpty {
                            Text(recipe.description)
                                .font(WFFont.body(14))
                                .foregroundColor(WFPalette.secondaryText)
                                .lineSpacing(4)
                                .padding(.top, 8)
                        }
                        metaStrip.padding(.top, 18)
                        nutrition.padding(.top, 22)
                        actionRow.padding(.top, 22)
                        ingredientsCard.padding(.top, 24)
                        instructions.padding(.top, 26)
                        allergenBanner
                        chefTip
                        if !saved {
                            Button {
                                Task {
                                    if await appState.save(recipe) { saved = true }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "bookmark.fill")
                                    Text("Save to my recipes")
                                }
                            }
                            .buttonStyle(WFPrimaryButtonStyle())
                            .padding(.top, 26)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 38)
                }
            }
            .wfScreenBackground()
            // Let the hero run to the very top of the screen, behind the notch
            .ignoresSafeArea(edges: .top)

            if showRemixSheet {
                WFRemixSheet(
                    dismiss: { showRemixSheet = false },
                    choose: performRemix
                )
                .transition(.opacity)
                .zIndex(4)
            }

            if remixing {
                WFGenerationLoadingView(mode: .remix)
                    .transition(.opacity)
                    .zIndex(5)
            }
        }
    }

    private func hero(showsOverlayButtons: Bool) -> some View {
        ZStack(alignment: .bottomLeading) {
            WFRemoteImage(urlString: recipe.imageURL)
                .frame(height: 300)
                .clipped()
            LinearGradient(colors: [.clear, WFPalette.text.opacity(0.62)], startPoint: .center, endPoint: .bottom)

            if showsOverlayButtons {
                HStack {
                    WFIconButton(systemName: "chevron.left", action: close)
                    Spacer()
                    WFIconButton(
                        systemName: appState.isFavorite(recipe) ? "heart.fill" : "heart",
                        foreground: appState.isFavorite(recipe) ? WFPalette.orange : WFPalette.text,
                        action: { appState.toggleFavorite(recipe) }
                    )
                    WFIconButton(systemName: "square.and.arrow.up", action: { showShare = true })
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 18)
                .padding(.top, 60)
            }
        }
        .frame(height: 300)
    }

    @ViewBuilder private var tags: some View {
        let values = (recipe.tags ?? []).filter { !$0.isEmpty }
        if !values.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(values, id: \.self) { tag in
                        Text(tag)
                            .font(WFFont.body(11.5, weight: .bold))
                            .foregroundColor(WFPalette.selectedText)
                            .padding(.horizontal, 11)
                            .frame(height: 28)
                            .background(WFPalette.selectedBackground)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.top, 18)
        }
    }

    private var metaStrip: some View {
        HStack(spacing: 0) {
            WFMetaItem(label: "PREP", value: recipe.prepTime ?? "—")
            WFMetaDivider()
            WFMetaItem(label: "COOK", value: recipe.cookTime)
            WFMetaDivider()
            WFMetaItem(label: "SERVES", value: "\(servings)")
            WFMetaDivider()
            WFMetaItem(label: "LEVEL", value: recipe.difficulty ?? "Easy")
        }
        .padding(.vertical, 15)
        .background(WFPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(WFPalette.border, lineWidth: 1))
    }

    @ViewBuilder private var nutrition: some View {
        if let cal = recipe.cal {
            VStack(alignment: .leading, spacing: 12) {
                WFSectionTitle(title: "Nutrition")
                HStack(spacing: 9) {
                    WFNutritionCard(label: "kcal", value: cal.totalCalories ?? "—", color: WFPalette.selectedText, background: WFPalette.selectedBackground)
                    WFNutritionCard(label: "carbs", value: cal.carbs, color: Color(red: 0.96, green: 0.50, blue: 0.09), background: Color(red: 1, green: 0.97, blue: 0.88))
                    WFNutritionCard(label: "protein", value: cal.protein, color: Color(red: 0.85, green: 0.26, blue: 0.08), background: Color(red: 0.98, green: 0.91, blue: 0.90))
                    WFNutritionCard(label: "fat", value: cal.fat, color: Color(red: 0.36, green: 0.25, blue: 0.22), background: Color(red: 0.94, green: 0.92, blue: 0.91))
                }
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button { showCookingMode = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill").foregroundColor(WFPalette.amber)
                    Text("Start cooking")
                }
                .font(WFFont.heading(14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(WFPalette.dark)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(WFPressButtonStyle())

            Button { showRemixSheet = true } label: {
                HStack(spacing: 7) {
                    Image(systemName: "arrow.clockwise")
                    Text("Remix")
                }
                .font(WFFont.heading(14, weight: .bold))
                .foregroundColor(WFPalette.orange)
                .frame(width: 116, height: 52)
                .background(WFPalette.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(WFPalette.border, lineWidth: 1.5))
            }
            .buttonStyle(WFPressButtonStyle())
        }
    }

    private var ingredientsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Ingredients")
                    .font(WFFont.heading(17, weight: .bold))
                    .foregroundColor(WFPalette.text)
                Spacer()
                HStack(spacing: 11) {
                    Button { servings = max(1, servings - 1) } label: {
                        Image(systemName: "minus").frame(width: 28, height: 34)
                    }
                    Text("\(servings) serv.")
                        .font(WFFont.body(12.5, weight: .bold))
                        .frame(minWidth: 48)
                    Button { servings = min(12, servings + 1) } label: {
                        Image(systemName: "plus").frame(width: 28, height: 34)
                    }
                }
                .foregroundColor(WFPalette.text)
                .background(WFPalette.background)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(WFPalette.border, lineWidth: 1))
            }
            .padding(16)

            ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                Rectangle().fill(WFPalette.divider).frame(height: 1).padding(.leading, 52)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if checkedIngredients.contains(index) { checkedIngredients.remove(index) }
                    else { checkedIngredients.insert(index) }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(checkedIngredients.contains(index) ? WFPalette.orange : Color.clear)
                                .frame(width: 22, height: 22)
                                .overlay(RoundedRectangle(cornerRadius: 7).stroke(checkedIngredients.contains(index) ? Color.clear : WFPalette.border, lineWidth: 1.5))
                            if checkedIngredients.contains(index) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        Text(WFIngredientScaler.scale(ingredient, from: baseServings, to: servings))
                            .font(WFFont.body(14, weight: .semibold))
                            .foregroundColor(checkedIngredients.contains(index) ? WFPalette.tertiaryText : WFPalette.text)
                            .strikethrough(checkedIngredients.contains(index), color: WFPalette.tertiaryText)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                }
                .buttonStyle(.plain)
            }
        }
        .background(WFPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(WFPalette.border, lineWidth: 1))
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 16) {
            WFSectionTitle(title: "Instructions")
            ForEach(Array(recipe.recipe.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 13) {
                    // Number plus the dashed connector running down to the next step
                    VStack(spacing: 4) {
                        Text("\(index + 1)")
                            .font(WFFont.heading(12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 29, height: 29)
                            .background(WFPalette.orange)
                            .clipShape(Circle())
                        if index < recipe.recipe.count - 1 {
                            WFStepConnector()
                        }
                    }
                    Text(step)
                        .font(WFFont.body(14.5))
                        .foregroundColor(WFPalette.text)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    @ViewBuilder private var allergenBanner: some View {
        let allergens = (recipe.allergens ?? []).filter { !$0.isEmpty && $0.lowercased() != "none" }
        if !allergens.isEmpty {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("Contains: \(allergens.joined(separator: ", "))")
                    .font(WFFont.body(13, weight: .semibold))
                Spacer()
            }
            .foregroundColor(Color(red: 0.48, green: 0.36, blue: 0))
            .padding(15)
            .background(Color(red: 1, green: 0.97, blue: 0.88))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color(red: 1, green: 0.93, blue: 0.70), lineWidth: 1))
            .padding(.top, 24)
        }
    }

    @ViewBuilder private var chefTip: some View {
        if let tip = recipe.tips?.first, !tip.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("CHEF'S TIP")
                }
                .font(WFFont.heading(11, weight: .bold))
                .foregroundColor(WFPalette.selectedText)
                Text(tip)
                    .font(WFFont.body(14, weight: .semibold))
                    .foregroundColor(Color(red: 0.36, green: 0.25, blue: 0.22))
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(17)
            .background(LinearGradient(colors: [WFPalette.selectedBackground, Color(red: 1, green: 0.93, blue: 0.70)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.top, 18)
        }
    }

    private func performRemix(_ twist: String) {
        showRemixSheet = false
        remixing = true
        Task {
            let result = await appState.remix(recipe, twist: twist)
            await MainActor.run {
                if let result {
                    recipe = result
                    servings = Self.parseServings(result.servings)
                    checkedIngredients.removeAll()
                    saved = false
                }
                remixing = false
            }
        }
    }

    private var shareText: String {
        "\(recipe.foodName)\n\nIngredients\n\(recipe.ingredients.joined(separator: "\n"))\n\nInstructions\n\(recipe.recipe.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))"
    }

    private static func parseServings(_ text: String?) -> Int {
        guard let text else { return 2 }
        let digits = text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return min(12, max(1, Int(digits) ?? 2))
    }
}

private struct WFMetaItem: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 5) {
            Text(label)
                .font(WFFont.body(9.5, weight: .bold))
                .foregroundColor(WFPalette.secondaryText)
            Text(value)
                .font(WFFont.heading(11.5, weight: .bold))
                .foregroundColor(WFPalette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WFMetaDivider: View {
    var body: some View { Rectangle().fill(WFPalette.divider).frame(width: 1, height: 31) }
}

/// Dashed vertical rule linking one instruction number to the next.
private struct WFStepConnector: View {
    var body: some View {
        WFVerticalLine()
            .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
            .foregroundColor(WFPalette.orange.opacity(0.4))
            .frame(width: 2)
            .frame(maxHeight: .infinity)
    }
}

private struct WFVerticalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

private struct WFNutritionCard: View {
    let label: String
    let value: String
    let color: Color
    let background: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(WFFont.heading(13, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(label.uppercased())
                .font(WFFont.body(8.5, weight: .bold))
                .opacity(0.76)
        }
        .foregroundColor(color)
        .frame(maxWidth: .infinity)
        .frame(height: 66)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Still SwiftUI; hosted from the UIKit detail screen during the migration.
struct WFCookingModeView: View {
    let steps: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                WFIconButton(systemName: "xmark", action: { dismiss() })
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(WFPalette.border).frame(height: 6)
                        Capsule().fill(WFPalette.orange)
                            .frame(width: proxy.size.width * CGFloat(index + 1) / CGFloat(max(1, steps.count)), height: 6)
                            .animation(.easeOut(duration: 0.25), value: index)
                    }
                }
                .frame(height: 6)
                Text("\(index + 1) / \(max(1, steps.count))")
                    .font(WFFont.body(12.5, weight: .bold))
                    .foregroundColor(WFPalette.secondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer()
            Text("\(index + 1)")
                .font(WFFont.heading(21, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(WFPalette.orange)
                .clipShape(Circle())
            Text(steps.indices.contains(index) ? steps[index] : "Enjoy your meal!")
                .font(WFFont.heading(24, weight: .semibold))
                .foregroundColor(WFPalette.text)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, 30)
                .padding(.top, 24)
            Spacer()

            HStack(spacing: 10) {
                Button("Back") {
                    guard index > 0 else { return }
                    index -= 1
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                .font(WFFont.heading(14, weight: .bold))
                .foregroundColor(WFPalette.text)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(WFPalette.card)
                .clipShape(RoundedRectangle(cornerRadius: 17))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(WFPalette.border, lineWidth: 1.5))
                .opacity(index == 0 ? 0.4 : 1)
                .disabled(index == 0)

                Button(index == steps.count - 1 ? "Done — looks delicious" : "Next step") {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if index >= steps.count - 1 { dismiss() } else { index += 1 }
                }
                .buttonStyle(WFPrimaryButtonStyle())
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .wfScreenBackground()
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

private struct WFRemixSheet: View {
    let dismiss: () -> Void
    let choose: (String) -> Void

    private let options = [
        ("leaf.fill", "Make it vegan", "Swap in satisfying plant-based alternatives."),
        ("flame.fill", "Make it spicier", "Build layered chili heat without losing balance."),
        ("timer", "20-minute version", "Streamline the method for a busy evening.")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            WFPalette.text.opacity(0.45).ignoresSafeArea().onTapGesture(perform: dismiss)
            VStack(alignment: .leading, spacing: 0) {
                Capsule().fill(WFPalette.tertiaryText).frame(width: 38, height: 5)
                    .frame(maxWidth: .infinity).padding(.top, 10)
                Text("Remix this recipe")
                    .font(WFFont.heading(22, weight: .bold))
                    .padding(.top, 18)
                Text("The AI will rewrite it around your twist.")
                    .font(WFFont.body(13))
                    .foregroundColor(WFPalette.secondaryText)
                    .padding(.top, 4)
                    .padding(.bottom, 14)
                ForEach(options, id: \.1) { option in
                    Button { choose(option.1) } label: {
                        HStack(spacing: 13) {
                            Image(systemName: option.0)
                                .foregroundColor(WFPalette.selectedText)
                                .frame(width: 38, height: 38)
                                .background(WFPalette.selectedBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(option.1)
                                    .font(WFFont.heading(14.5, weight: .semibold))
                                    .foregroundColor(WFPalette.text)
                                Text(option.2)
                                    .font(WFFont.body(11.5))
                                    .foregroundColor(WFPalette.secondaryText)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(WFPalette.tertiaryText)
                        }
                        .padding(.vertical, 11)
                    }
                    .buttonStyle(WFPressButtonStyle())
                }
                Button("Cancel", action: dismiss)
                    .font(WFFont.body(14, weight: .semibold))
                    .foregroundColor(WFPalette.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 10)
            .background(WFPalette.background)
            .clipShape(WFRoundedCorners(radius: 26, corners: [.topLeft, .topRight]))
            .shadow(color: WFPalette.text.opacity(0.2), radius: 24, y: -8)
        }
    }
}

/// Shared by the SwiftUI and UIKit recipe screens during the migration.
enum WFIngredientScaler {
    static func scale(_ text: String, from baseServings: Int, to servings: Int) -> String {
        guard baseServings > 0, baseServings != servings else { return text }
        let parts = text.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard let first = parts.first, let amount = parse(String(first)) else { return text }
        let scaled = amount * Double(servings) / Double(baseServings)
        let remainder = parts.count > 1 ? " " + String(parts[1]) : ""
        return format(scaled) + remainder
    }

    private static func parse(_ token: String) -> Double? {
        let fractions: [String: Double] = ["¼": 0.25, "½": 0.5, "¾": 0.75, "⅓": 1.0 / 3.0, "⅔": 2.0 / 3.0]
        if let exact = fractions[token] { return exact }
        if token.contains("/") {
            let values = token.split(separator: "/").compactMap { Double($0) }
            if values.count == 2, values[1] != 0 { return values[0] / values[1] }
        }
        for (symbol, fraction) in fractions where token.hasSuffix(symbol) {
            let whole = Double(token.dropLast()) ?? 0
            return whole + fraction
        }
        return Double(token.replacingOccurrences(of: ",", with: "."))
    }

    private static func format(_ value: Double) -> String {
        let quarters = (value * 4).rounded() / 4
        let whole = Int(quarters)
        let remainder = quarters - Double(whole)
        let fraction: String
        switch remainder {
        case 0.25: fraction = "¼"
        case 0.5: fraction = "½"
        case 0.75: fraction = "¾"
        default: fraction = ""
        }
        if whole == 0, !fraction.isEmpty { return fraction }
        if fraction.isEmpty { return "\(whole)" }
        return "\(whole)\(fraction)"
    }
}
