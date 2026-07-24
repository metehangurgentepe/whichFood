import SwiftUI
import UIKit

private struct WFRecipeDetailRoute: Identifiable {
    let id = UUID()
    let recipe: RecipeResponseModel
    let isSaved: Bool
}

struct WhichFoodMainView: View {
    @StateObject private var appState = WhichFoodAppState()
    @State private var selectedTab = 0
    @State private var creationMode: WFRecipeCreationMode = .ingredients
    @State private var showCreation = false
    @State private var detailRoute: WFRecipeDetailRoute?
    @State private var showPhotoSource = false
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

    let isPremium: Bool

    init(isPremium: Bool = false) {
        self.isPremium = isPremium
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 1, green: 0.984, blue: 0.961, alpha: 0.97)
        appearance.shadowColor = UIColor(red: 0.941, green: 0.902, blue: 0.863, alpha: 1)
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                WFHomeHost(
                    appState: appState,
                    createFromIngredients: {
                        creationMode = .ingredients
                        showCreation = true
                    },
                    createFromPhoto: { showPhotoSource = true },
                    openRecipe: openSavedRecipe
                )
                .ignoresSafeArea(edges: .bottom)
                .tabItem { Label("Home", systemImage: "house") }
                .tag(0)

                WFFavoritesView(appState: appState, openRecipe: openSavedRecipe)
                    .tabItem { Label("Favorites", systemImage: "heart") }
                    .tag(1)

                WFDiscoverView(appState: appState, openRecipe: openSavedRecipe)
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
                    .tag(2)

                WFSettingsHandoffView(appState: appState, premiumFromLaunch: isPremium)
                    .tabItem { Label("Settings", systemImage: "gearshape") }
                    .tag(3)
            }
            .accentColor(WFPalette.orange)

            if showPhotoSource {
                WFPhotoSourceSheet(
                    dismiss: { showPhotoSource = false },
                    choose: { source in
                        showPhotoSource = false
                        imagePickerSource = source
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            showImagePicker = true
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(3)
            }
        }
        .task { await appState.loadAll() }
        .fullScreenCover(isPresented: $showCreation, onDismiss: {
            Task { await appState.loadLibrary() }
        }) {
            WFRecipeCreationFlow(mode: creationMode, appState: appState)
        }
        .fullScreenCover(item: $detailRoute) { route in
            WFRecipeDetailHost(
                recipe: route.recipe,
                isSaved: route.isSaved,
                appState: appState,
                close: { detailRoute = nil }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showImagePicker) {
            WFImagePicker(sourceType: imagePickerSource) { image in
                showImagePicker = false
                guard let image else { return }
                creationMode = .photo(image)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showCreation = true
                }
            }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { appState.errorMessage = nil }
        } message: {
            Text(appState.errorMessage ?? "Please try again.")
        }
    }

    private func openSavedRecipe(_ recipe: RecipeResponseModel) {
        detailRoute = WFRecipeDetailRoute(recipe: recipe, isSaved: true)
    }
}

private struct WFHomeView: View {
    @ObservedObject var appState: WhichFoodAppState
    let createFromIngredients: () -> Void
    let createFromPhoto: () -> Void
    let openRecipe: (RecipeResponseModel) -> Void

    @State private var selectedFilter = "All"
    private let filters = ["All", "Meaty", "Vegetarian", "Dessert"]

    private var filteredRecipes: [Recipe] {
        guard selectedFilter != "All" else { return appState.savedRecipes }
        let target: String
        switch selectedFilter {
        case "Meaty": target = "meat"
        case "Vegetarian": target = "vegetable"
        default: target = "dessert"
        }
        return appState.savedRecipes.filter { $0.type?.lowercased() == target }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting)
                            .font(WFFont.body(13.5, weight: .semibold))
                            .foregroundColor(WFPalette.secondaryText)
                        Text("Let's cook something great.")
                            .font(WFFont.heading(24, weight: .bold))
                            .foregroundColor(WFPalette.text)
                    }

                    HStack(spacing: 12) {
                        WFHomeActionCard(
                            title: "From Ingredients",
                            subtitle: "Use what you already have",
                            icon: "basket",
                            primary: true,
                            action: createFromIngredients
                        )
                        WFHomeActionCard(
                            title: "From Photo",
                            subtitle: "Snap a dish, get the recipe",
                            icon: "camera",
                            primary: false,
                            action: createFromPhoto
                        )
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        WFSectionTitle(title: "Your recipes", trailing: "\(appState.savedRecipes.count) saved")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(filters, id: \.self) { filter in
                                    WFChip(title: filter, selected: selectedFilter == filter, darkSelection: true) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                        }

                        if appState.isLoadingLibrary && appState.savedRecipes.isEmpty {
                            WFRecipeGridSkeleton()
                        } else if filteredRecipes.isEmpty {
                            WFEmptyState(
                                icon: "fork.knife.circle",
                                title: selectedFilter == "All" ? "Your cookbook is empty" : "No \(selectedFilter.lowercased()) recipes yet",
                                message: selectedFilter == "All"
                                    ? "Create a recipe from your ingredients or a food photo to get started."
                                    : "Try another filter or create something new.",
                                dashed: true
                            )
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible())], spacing: 14) {
                                ForEach(filteredRecipes, id: \.id) { recipe in
                                    let response = RecipeResponseModel.fromRecipe(recipe)
                                    WFRecipeCard(
                                        recipe: response,
                                        favorite: appState.isFavorite(response),
                                        toggleFavorite: { appState.toggleFavorite(response) },
                                        open: { openRecipe(response) }
                                    )
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            Task { await appState.delete(recipe) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .wfScreenBackground()
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
}

private struct WFHomeActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let primary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 25, weight: .medium))
                    .foregroundColor(primary ? .white : WFPalette.lightOrange)
                Spacer(minLength: 12)
                Text(title)
                    .font(WFFont.heading(15, weight: .bold))
                    .foregroundColor(primary ? .white : WFPalette.text)
                Text(subtitle)
                    .font(WFFont.body(11.5))
                    .foregroundColor(primary ? .white.opacity(0.85) : WFPalette.secondaryText)
                    .lineLimit(2)
                    .padding(.top, 3)
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .padding(16)
            .background(primary ? AnyShapeStyle(WFPalette.primaryGradient) : AnyShapeStyle(WFPalette.card))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(primary ? Color.clear : WFPalette.border, lineWidth: 1.5)
            )
            .shadow(color: primary ? WFPalette.orange.opacity(0.22) : .clear, radius: 10, y: 7)
        }
        .buttonStyle(WFPressButtonStyle())
    }
}

struct WFRecipeCard: View {
    let recipe: RecipeResponseModel
    let favorite: Bool
    let toggleFavorite: () -> Void
    let open: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: open) {
                VStack(alignment: .leading, spacing: 0) {
                    WFRemoteImage(urlString: recipe.imageURL)
                        .frame(height: 110)
                        .clipped()
                VStack(alignment: .leading, spacing: 5) {
                    Text(recipe.foodName)
                        .font(WFFont.heading(13.5, weight: .semibold))
                        .foregroundColor(WFPalette.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text("\(recipe.totalTime ?? recipe.cookTime) · \(recipe.difficulty ?? "Easy")")
                        .font(WFFont.body(11.5, weight: .semibold))
                        .foregroundColor(WFPalette.secondaryText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                }
                .background(WFPalette.card)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(WFPalette.border, lineWidth: 1))
                .shadow(color: WFPalette.text.opacity(0.04), radius: 4, y: 2)
            }
            .buttonStyle(WFPressButtonStyle())

            Button(action: toggleFavorite) {
                Image(systemName: favorite ? "heart.fill" : "heart")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(favorite ? WFPalette.orange : WFPalette.text)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Circle())
            }
            .buttonStyle(WFPressButtonStyle())
            .padding(8)
        }
    }
}

struct WFFavoritesView: View {
    @ObservedObject var appState: WhichFoodAppState
    let openRecipe: (RecipeResponseModel) -> Void

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Favorites".locale())
                        .font(WFFont.heading(24, weight: .bold))
                        .foregroundColor(WFPalette.text)

                    if appState.favoriteRecipes.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "heart")
                                .font(.system(size: 44, weight: .light))
                                .foregroundColor(WFPalette.border)
                            Text("No favorites yet".locale())
                                .font(WFFont.heading(16, weight: .bold))
                            Text("Tap the heart on any recipe to keep it close at hand.".locale())
                                .font(WFFont.body(13))
                                .foregroundColor(WFPalette.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 70)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible())], spacing: 14) {
                            ForEach(appState.favoriteRecipes, id: \.wfIdentifier) { recipe in
                                WFRecipeCard(
                                    recipe: recipe,
                                    favorite: true,
                                    toggleFavorite: { appState.toggleFavorite(recipe) },
                                    open: { openRecipe(recipe) }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .wfScreenBackground()
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .onAppear { Task { await appState.loadFavorites() } }
    }
}

struct WFDiscoverView: View {
    @ObservedObject var appState: WhichFoodAppState
    let openRecipe: (RecipeResponseModel) -> Void
    @State private var query = ""

    private var results: [Recipe] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return appState.catalogRecipes }
        return appState.catalogRecipes.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            ($0.keywords ?? []).contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    /// TheMealDB results; empty unless the app is running in English.
    private var externalResults: [RecipeResponseModel] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return appState.externalRecipes }
        return appState.externalRecipes.filter {
            $0.foodName.localizedCaseInsensitiveContains(query) ||
            ($0.tags ?? []).contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Discover")
                        .font(WFFont.heading(24, weight: .bold))
                        .foregroundColor(WFPalette.text)
                    WFSearchField(text: $query, placeholder: "Search recipes…")

                    if results.isEmpty && externalResults.isEmpty {
                        WFEmptyState(
                            icon: "magnifyingglass",
                            title: "Nothing found",
                            message: "Try a different keyword — or create it from your ingredients instead."
                        )
                        .padding(.top, 44)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible())], spacing: 14) {
                            ForEach(results, id: \.id) { item in
                                let recipe = RecipeResponseModel.fromRecipe(item)
                                WFRecipeCard(
                                    recipe: recipe,
                                    favorite: appState.isFavorite(recipe),
                                    toggleFavorite: { appState.toggleFavorite(recipe) },
                                    open: { openRecipe(recipe) }
                                )
                            }
                        }
                        .padding(.top, 4)

                        if !externalResults.isEmpty {
                            WFSectionTitle(title: "From around the web")
                                .padding(.top, 22)

                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible())], spacing: 14) {
                                ForEach(externalResults, id: \.wfIdentifier) { recipe in
                                    WFRecipeCard(
                                        recipe: recipe,
                                        favorite: appState.isFavorite(recipe),
                                        toggleFavorite: { appState.toggleFavorite(recipe) },
                                        open: { openRecipe(recipe) }
                                    )
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .wfScreenBackground()
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
}

struct WFSettingsHandoffView: View {
    @ObservedObject var appState: WhichFoodAppState
    let premiumFromLaunch: Bool
    @State private var showPremium = false
    @State private var shareApp = false
    @State private var showAppearancePicker = false
    @State private var appearance = WFAppearanceManager.current
    @Environment(\.openURL) private var openURL

    private var appearanceTitle: String {
        appearance.titleKey.locale()
    }

    private var rows: [(String, String, String, () -> Void)] {
        [
            ("Account".locale(), "", "person", {}),
            ("Premium".locale(), appState.effectiveIsPremium || premiumFromLaunch ? "Active".locale() : "Free".locale(), "crown", { showPremium = true }),
            ("Recipes created".locale(), "\(appState.currentUser?.numberOfUsageApi ?? 0)", "sparkles", {}),
            ("Language".locale(), Locale.current.localizedString(forLanguageCode: Bundle.main.preferredLocalizations.first ?? "en") ?? "English", "globe", { openSystemSettings() }),
            ("Appearance".locale(), appearanceTitle, appearance.iconName, { showAppearancePicker = true }),
            ("Send feedback".locale(), "", "envelope", { openURL(URL(string: "mailto:\(Constants.Links.email.rawValue)")!) }),
            ("Rate WhichFood".locale(), "", "star", { openURL(URL(string: Constants.Links.appStoreLink.rawValue)!) }),
            ("Share the app".locale(), "", "square.and.arrow.up", { shareApp = true })
        ]
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Settings".locale())
                        .font(WFFont.heading(24, weight: .bold))
                        .foregroundColor(WFPalette.text)

                    HStack(spacing: 14) {
                        Text("W")
                            .font(WFFont.heading(18, weight: .bold))
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.22))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Your kitchen".locale())
                                .font(WFFont.heading(15, weight: .bold))
                            Text(appState.effectiveIsPremium || premiumFromLaunch
                                 ? "Premium plan · Unlimited AI recipes".locale()
                                 : String(format: "Free plan · %d AI recipes left".locale(), appState.generationsLeft))
                                .font(WFFont.body(12))
                                .foregroundColor(.white.opacity(0.86))
                        }
                        Spacer()
                        if !(appState.effectiveIsPremium || premiumFromLaunch) {
                            Button("Go Premium".locale()) { showPremium = true }
                                .font(WFFont.heading(11.5, weight: .bold))
                                .foregroundColor(WFPalette.text)
                                .padding(.horizontal, 12)
                                .frame(height: 34)
                                .background(WFPalette.amber)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(18)
                    .background(WFPalette.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                            Button(action: row.3) {
                                HStack(spacing: 12) {
                                    Image(systemName: row.2)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(WFPalette.orange)
                                        .frame(width: 24)
                                    Text(row.0)
                                        .font(WFFont.body(14, weight: .semibold))
                                        .foregroundColor(WFPalette.text)
                                    Spacer()
                                    if !row.1.isEmpty {
                                        Text(row.1)
                                            .font(WFFont.body(12.5, weight: .semibold))
                                            .foregroundColor(WFPalette.secondaryText)
                                            .lineLimit(1)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(WFPalette.tertiaryText)
                                }
                                .padding(.horizontal, 16)
                                .frame(minHeight: 54)
                            }
                            if index < rows.count - 1 {
                                Rectangle().fill(WFPalette.divider).frame(height: 1).padding(.leading, 52)
                            }
                        }
                    }
                    .background(WFPalette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(WFPalette.border, lineWidth: 1))

                    #if DEBUG
                    Toggle(isOn: $appState.debugPremiumOverride) {
                        HStack(spacing: 12) {
                            Image(systemName: "hammer")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(WFPalette.green)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Debug: Premium".locale())
                                    .font(WFFont.body(14, weight: .semibold))
                                    .foregroundColor(WFPalette.text)
                                Text("Bypass the AI generation limit".locale())
                                    .font(WFFont.body(11.5))
                                    .foregroundColor(WFPalette.secondaryText)
                            }
                        }
                    }
                    .tint(WFPalette.green)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 56)
                    .background(WFPalette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(WFPalette.border, lineWidth: 1))
                    #endif

                    HStack(spacing: 6) {
                        Text("WhichFood 1.0 ·")
                        Button("Terms".locale()) { openURL(URL(string: Constants.Links.termsOfService.rawValue)!) }
                        Text("·")
                        Button("Privacy".locale()) { openURL(URL(string: Constants.Links.privacyPolicy.rawValue)!) }
                    }
                    .font(WFFont.body(12, weight: .semibold))
                    .foregroundColor(WFPalette.tertiaryText)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .wfScreenBackground()
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showPremium) { SubscriptionView() }
        .sheet(isPresented: $shareApp) {
            WFActivityView(items: [Constants.Links.appStoreLink.rawValue])
        }
        .confirmationDialog("appearance_title".locale(), isPresented: $showAppearancePicker, titleVisibility: .visible) {
            ForEach(WFAppearanceMode.allCases, id: \.rawValue) { mode in
                Button(mode.titleKey.locale()) {
                    appearance = mode
                    WFAppearanceManager.current = mode
                }
            }
            Button("cancel".locale(), role: .cancel) {}
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

private struct WFRecipeGridSkeleton: View {
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible())], spacing: 14) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 18)
                    .fill(WFPalette.border.opacity(0.7))
                    .frame(height: 180)
                    .redacted(reason: .placeholder)
            }
        }
    }
}

private struct WFPhotoSourceSheet: View {
    let dismiss: () -> Void
    let choose: (UIImagePickerController.SourceType) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            WFPalette.text.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(perform: dismiss)
            VStack(spacing: 0) {
                Capsule().fill(WFPalette.tertiaryText).frame(width: 38, height: 5).padding(.top, 10)
                Text("Recipe from a photo")
                    .font(WFFont.heading(20, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                WFPhotoSourceRow(icon: "camera", title: "Take a photo") { choose(.camera) }
                WFPhotoSourceRow(icon: "photo", title: "Choose from library") { choose(.photoLibrary) }
                Button("Cancel", action: dismiss)
                    .font(WFFont.body(15, weight: .semibold))
                    .foregroundColor(WFPalette.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .padding(.bottom, 10)
            }
            .background(WFPalette.background)
            .clipShape(WFRoundedCorners(radius: 26, corners: [.topLeft, .topRight]))
            .shadow(color: WFPalette.text.opacity(0.2), radius: 24, y: -8)
        }
        .animation(.easeOut(duration: 0.28), value: true)
    }
}

private struct WFPhotoSourceRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .foregroundColor(WFPalette.orange)
                    .frame(width: 38, height: 38)
                    .background(WFPalette.selectedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text(title).font(WFFont.body(15, weight: .semibold)).foregroundColor(WFPalette.text)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(WFPalette.tertiaryText)
            }
            .padding(.horizontal, 24)
            .frame(minHeight: 62)
        }
        .buttonStyle(WFPressButtonStyle())
    }
}

struct WFImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let completion: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (UIImage?) -> Void
        init(completion: @escaping (UIImage?) -> Void) { self.completion = completion }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            completion(info[.originalImage] as? UIImage)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { completion(nil) }
    }
}

struct WFActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct WFRoundedCorners: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                          cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}
