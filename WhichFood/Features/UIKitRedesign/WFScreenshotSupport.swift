//
//  WFScreenshotSupport.swift
//  WhichFood
//
//  DEBUG-only harness that renders the app with fixed, localized mock data so
//  App Store screenshots can be captured deterministically without hitting the
//  live AI backend or the network for recipe generation.
//
//  Activated via launch arguments (see scripts/screenshots.sh):
//    -UITEST_SCREENSHOT YES     enables this mode
//    -UITEST_SCREEN <name>      home | favorites | detail
//    -AppleLanguages (tr)       standard iOS language override
//

#if DEBUG
import UIKit
import FirebaseFirestore

enum WFScreenshotSupport {

    /// Whether the app was launched in screenshot capture mode.
    static var isActive: Bool {
        UserDefaults.standard.bool(forKey: "UITEST_SCREENSHOT")
    }

    /// Which screen to present: "home", "favorites" or "detail".
    static var screen: String {
        UserDefaults.standard.string(forKey: "UITEST_SCREEN") ?? "home"
    }

    /// The active language code, resolved from the standard iOS override.
    private static var languageCode: String {
        let preferred = Bundle.main.preferredLocalizations.first ?? "en"
        // Normalise regional variants down to the base language we have copy for.
        if preferred.hasPrefix("zh") { return "zh-Hans" }
        return String(preferred.prefix(2))
    }

    // MARK: - Root

    /// Builds the fully-populated root view controller for the requested screen.
    @MainActor
    static func makeRoot() -> UIViewController {
        let state = makeMockState()
        let tabBar = WFMainTabBarController(isPremium: true, screenshotState: state)

        switch screen {
        case "favorites":
            tabBar.selectedIndex = 1
        case "detail":
            tabBar.selectedIndex = 0
            if let hero = state.savedRecipes.first {
                tabBar.pendingScreenshotDetail = RecipeResponseModel.fromRecipe(hero)
            }
        default:
            tabBar.selectedIndex = 0
        }

        return tabBar
    }

    /// An app state pre-filled with localized mock recipes.
    @MainActor
    static func makeMockState() -> WhichFoodAppState {
        let state = WhichFoodAppState()
        state.isScreenshotSeeded = true
        let recipes = MockRecipes.recipes(for: languageCode)
        state.savedRecipes = recipes
        state.catalogRecipes = recipes
        state.favoriteRecipes = recipes.prefix(2).map { RecipeResponseModel.fromRecipe($0) }
        state.isPremium = true
        return state
    }
}

// MARK: - Localized mock recipe content

private enum MockRecipes {

    // Stable, public food photos. The simulator uses the host network so these
    // load like any other remote image; if offline they fall back to the
    // in-app gradient placeholder.
    private static let heroImage   = "https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=1000&q=80"
    private static let salmonImage = "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=1000&q=80"
    private static let cakeImage   = "https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=1000&q=80"
    private static let saladImage  = "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=1000&q=80"

    static func recipes(for language: String) -> [Recipe] {
        let copy = content[language] ?? content["en"]!
        let now = Timestamp(date: Date())

        let hero = Recipe(
            id: "mock-hero",
            name: copy.heroName,
            recipe: copy.heroSteps,
            ingredients: copy.heroIngredients,
            description: copy.heroDescription,
            cookTime: copy.heroCook,
            userId: "screenshot",
            createdAt: now,
            type: "dinner",
            imageUrl: heroImage,
            language: language,
            keywords: [],
            prepTime: copy.heroPrep,
            totalTime: copy.heroTotal,
            difficulty: copy.easy,
            servings: "4",
            cuisine: copy.cuisine,
            tags: copy.heroTags,
            cal: CalorieInfo(carbs: "62 g", fat: "18 g", protein: "24 g", totalCalories: "520 kcal"),
            nutritionalInfo: NutritionalInfo(sugar: "9 g", fiber: "6 g", sodium: "480 mg", cholesterol: "35 mg"),
            allergens: copy.heroAllergens,
            tips: copy.heroTips
        )

        let extras: [(String, String, String, String)] = [
            (copy.salmonName, copy.min(30), "lunch", salmonImage),
            (copy.cakeName,   copy.min(45), "dessert", cakeImage),
            (copy.saladName,  copy.min(15), "lunch", saladImage)
        ]

        let supporting = extras.enumerated().map { index, item -> Recipe in
            Recipe(
                id: "mock-\(index)",
                name: item.0,
                recipe: [copy.heroSteps.first ?? ""],
                ingredients: copy.heroIngredients,
                description: item.0,
                cookTime: item.1,
                userId: "screenshot",
                createdAt: now,
                type: item.2,
                imageUrl: item.3,
                language: language,
                prepTime: copy.min(10),
                totalTime: item.1,
                difficulty: copy.easy,
                servings: "2",
                cuisine: copy.cuisine,
                tags: copy.heroTags,
                cal: CalorieInfo(carbs: "40 g", fat: "12 g", protein: "20 g", totalCalories: "380 kcal")
            )
        }

        return [hero] + supporting
    }

    // MARK: Content model

    struct Copy {
        let heroName: String
        let heroDescription: String
        let heroIngredients: [String]
        let heroSteps: [String]
        let heroTips: [String]
        let heroTags: [String]
        let heroAllergens: [String]
        let cuisine: String
        let easy: String
        let heroCook: String
        let heroPrep: String
        let heroTotal: String
        let salmonName: String
        let cakeName: String
        let saladName: String
        /// Builds a localized "N <minutes>" string.
        let minuteUnit: String
        func min(_ n: Int) -> String { "\(n) \(minuteUnit)" }
    }

    static let content: [String: Copy] = [
        "en": Copy(
            heroName: "Creamy Tomato Basil Pasta",
            heroDescription: "Silky tomato sauce with fresh basil and parmesan, tossed with al dente pasta. A weeknight classic that comes together in half an hour.",
            heroIngredients: ["300 g pasta", "2 cups tomato passata", "3 cloves garlic", "1 cup fresh basil", "½ cup cream", "50 g parmesan"],
            heroSteps: ["Cook the pasta in salted water until al dente.", "Sauté the garlic in olive oil until fragrant.", "Add the passata and simmer for 10 minutes.", "Stir in the cream and half of the basil.", "Toss the pasta with the sauce and finish with parmesan."],
            heroTips: ["Reserve a little pasta water to loosen the sauce.", "Add the basil off the heat to keep it bright."],
            heroTags: ["Vegetarian", "Quick", "Comfort"],
            heroAllergens: ["Gluten", "Dairy"],
            cuisine: "Italian", easy: "Easy",
            heroCook: "25 min", heroPrep: "10 min", heroTotal: "35 min",
            salmonName: "Grilled Salmon Bowl", cakeName: "Berry Pancake Stack", saladName: "Garden Caprese Salad",
            minuteUnit: "min"),

        "tr": Copy(
            heroName: "Kremalı Domates Fesleğen Makarna",
            heroDescription: "Taze fesleğen ve parmesanla ipeksi domates sosu, al dente makarnayla harmanlandı. Yarım saatte hazırlanan bir hafta içi klasiği.",
            heroIngredients: ["300 g makarna", "2 su bardağı domates sosu", "3 diş sarımsak", "1 su bardağı taze fesleğen", "½ su bardağı krema", "50 g parmesan"],
            heroSteps: ["Makarnayı tuzlu suda al dente olana kadar haşlayın.", "Sarımsağı zeytinyağında kokusu çıkana kadar kavurun.", "Domates sosunu ekleyip 10 dakika pişirin.", "Kremayı ve fesleğenin yarısını karıştırın.", "Makarnayı sosla harmanlayıp parmesanla tamamlayın."],
            heroTips: ["Sosu açmak için biraz makarna suyu ayırın.", "Fesleğeni ocaktan aldıktan sonra ekleyin."],
            heroTags: ["Vejetaryen", "Pratik", "Doyurucu"],
            heroAllergens: ["Gluten", "Süt ürünü"],
            cuisine: "İtalyan", easy: "Kolay",
            heroCook: "25 dk", heroPrep: "10 dk", heroTotal: "35 dk",
            salmonName: "Izgara Somon Kâsesi", cakeName: "Meyveli Pankek", saladName: "Bahçe Caprese Salatası",
            minuteUnit: "dk"),

        "de": Copy(
            heroName: "Cremige Tomaten-Basilikum-Pasta",
            heroDescription: "Seidige Tomatensauce mit frischem Basilikum und Parmesan, vermengt mit bissfester Pasta. Ein Klassiker für den Feierabend in nur einer halben Stunde.",
            heroIngredients: ["300 g Pasta", "2 Tassen Tomatenpassata", "3 Knoblauchzehen", "1 Tasse frisches Basilikum", "½ Tasse Sahne", "50 g Parmesan"],
            heroSteps: ["Die Pasta in Salzwasser bissfest kochen.", "Den Knoblauch in Olivenöl anbraten, bis er duftet.", "Die Passata zugeben und 10 Minuten köcheln lassen.", "Sahne und die Hälfte des Basilikums unterrühren.", "Die Pasta mit der Sauce vermengen und mit Parmesan verfeinern."],
            heroTips: ["Etwas Nudelwasser aufbewahren, um die Sauce zu lockern.", "Das Basilikum vom Herd genommen zugeben."],
            heroTags: ["Vegetarisch", "Schnell", "Herzhaft"],
            heroAllergens: ["Gluten", "Milch"],
            cuisine: "Italienisch", easy: "Einfach",
            heroCook: "25 Min", heroPrep: "10 Min", heroTotal: "35 Min",
            salmonName: "Gegrillte Lachs-Bowl", cakeName: "Beeren-Pfannkuchen", saladName: "Caprese-Salat",
            minuteUnit: "Min"),

        "es": Copy(
            heroName: "Pasta Cremosa de Tomate y Albahaca",
            heroDescription: "Salsa de tomate sedosa con albahaca fresca y parmesano, mezclada con pasta al dente. Un clásico entre semana listo en media hora.",
            heroIngredients: ["300 g de pasta", "2 tazas de passata de tomate", "3 dientes de ajo", "1 taza de albahaca fresca", "½ taza de nata", "50 g de parmesano"],
            heroSteps: ["Cocina la pasta en agua con sal hasta que esté al dente.", "Sofríe el ajo en aceite de oliva hasta que aromatice.", "Añade la passata y cocina a fuego lento 10 minutos.", "Incorpora la nata y la mitad de la albahaca.", "Mezcla la pasta con la salsa y termina con parmesano."],
            heroTips: ["Reserva un poco de agua de la pasta para aligerar la salsa.", "Añade la albahaca fuera del fuego."],
            heroTags: ["Vegetariano", "Rápido", "Reconfortante"],
            heroAllergens: ["Gluten", "Lácteos"],
            cuisine: "Italiana", easy: "Fácil",
            heroCook: "25 min", heroPrep: "10 min", heroTotal: "35 min",
            salmonName: "Bol de Salmón a la Parrilla", cakeName: "Tortitas con Frutos Rojos", saladName: "Ensalada Caprese",
            minuteUnit: "min"),

        "fr": Copy(
            heroName: "Pâtes Crémeuses Tomate-Basilic",
            heroDescription: "Sauce tomate onctueuse au basilic frais et parmesan, mêlée à des pâtes al dente. Un classique de la semaine prêt en une demi-heure.",
            heroIngredients: ["300 g de pâtes", "2 tasses de passata de tomate", "3 gousses d'ail", "1 tasse de basilic frais", "½ tasse de crème", "50 g de parmesan"],
            heroSteps: ["Cuire les pâtes dans l'eau salée jusqu'à al dente.", "Faire revenir l'ail dans l'huile d'olive jusqu'à ce qu'il embaume.", "Ajouter la passata et laisser mijoter 10 minutes.", "Incorporer la crème et la moitié du basilic.", "Mélanger les pâtes à la sauce et finir avec le parmesan."],
            heroTips: ["Réserver un peu d'eau de cuisson pour détendre la sauce.", "Ajouter le basilic hors du feu."],
            heroTags: ["Végétarien", "Rapide", "Réconfortant"],
            heroAllergens: ["Gluten", "Produits laitiers"],
            cuisine: "Italienne", easy: "Facile",
            heroCook: "25 min", heroPrep: "10 min", heroTotal: "35 min",
            salmonName: "Bol de Saumon Grillé", cakeName: "Pancakes aux Fruits Rouges", saladName: "Salade Caprese",
            minuteUnit: "min"),

        "it": Copy(
            heroName: "Pasta Cremosa Pomodoro e Basilico",
            heroDescription: "Vellutata salsa di pomodoro con basilico fresco e parmigiano, mantecata con pasta al dente. Un classico infrasettimanale pronto in mezz'ora.",
            heroIngredients: ["300 g di pasta", "2 tazze di passata di pomodoro", "3 spicchi d'aglio", "1 tazza di basilico fresco", "½ tazza di panna", "50 g di parmigiano"],
            heroSteps: ["Cuoci la pasta in acqua salata fino ad al dente.", "Rosola l'aglio nell'olio d'oliva finché non profuma.", "Aggiungi la passata e fai sobbollire 10 minuti.", "Incorpora la panna e metà del basilico.", "Manteca la pasta con la salsa e completa col parmigiano."],
            heroTips: ["Tieni da parte un po' d'acqua di cottura per la salsa.", "Aggiungi il basilico a fuoco spento."],
            heroTags: ["Vegetariano", "Veloce", "Confortante"],
            heroAllergens: ["Glutine", "Latticini"],
            cuisine: "Italiana", easy: "Facile",
            heroCook: "25 min", heroPrep: "10 min", heroTotal: "35 min",
            salmonName: "Bowl di Salmone alla Griglia", cakeName: "Pancake ai Frutti di Bosco", saladName: "Insalata Caprese",
            minuteUnit: "min"),

        "ja": Copy(
            heroName: "クリーミートマトバジルパスタ",
            heroDescription: "フレッシュバジルとパルメザンを効かせた濃厚なトマトソースを、アルデンテのパスタに絡めた一皿。30分で作れる平日の定番です。",
            heroIngredients: ["パスタ 300g", "トマトパッサータ 2カップ", "にんにく 3片", "フレッシュバジル 1カップ", "生クリーム ½カップ", "パルメザン 50g"],
            heroSteps: ["塩を加えた湯でパスタをアルデンテに茹でる。", "オリーブオイルでにんにくを香りが立つまで炒める。", "パッサータを加えて10分煮込む。", "生クリームとバジルの半量を混ぜる。", "パスタをソースと和え、パルメザンで仕上げる。"],
            heroTips: ["ソースをのばすため茹で汁を少し取っておく。", "バジルは火を止めてから加える。"],
            heroTags: ["ベジタリアン", "時短", "定番"],
            heroAllergens: ["小麦", "乳"],
            cuisine: "イタリアン", easy: "かんたん",
            heroCook: "25分", heroPrep: "10分", heroTotal: "35分",
            salmonName: "グリルサーモンボウル", cakeName: "ベリーパンケーキ", saladName: "カプレーゼサラダ",
            minuteUnit: "分"),

        "ko": Copy(
            heroName: "크리미 토마토 바질 파스타",
            heroDescription: "신선한 바질과 파르메산을 곁들인 부드러운 토마토 소스를 알덴테 파스타에 버무린 요리. 30분이면 완성되는 평일 클래식입니다.",
            heroIngredients: ["파스타 300g", "토마토 파사타 2컵", "마늘 3쪽", "신선한 바질 1컵", "생크림 ½컵", "파르메산 50g"],
            heroSteps: ["소금물에 파스타를 알덴테로 삶는다.", "올리브유에 마늘을 향이 날 때까지 볶는다.", "파사타를 넣고 10분간 끓인다.", "생크림과 바질 절반을 섞는다.", "파스타를 소스에 버무리고 파르메산으로 마무리한다."],
            heroTips: ["소스 농도 조절을 위해 면수를 조금 남겨두세요.", "바질은 불을 끄고 넣으세요."],
            heroTags: ["채식", "간편", "든든"],
            heroAllergens: ["글루텐", "유제품"],
            cuisine: "이탈리안", easy: "쉬움",
            heroCook: "25분", heroPrep: "10분", heroTotal: "35분",
            salmonName: "구운 연어 볼", cakeName: "베리 팬케이크", saladName: "카프레제 샐러드",
            minuteUnit: "분"),

        "zh-Hans": Copy(
            heroName: "奶油番茄罗勒意面",
            heroDescription: "顺滑的番茄酱汁搭配新鲜罗勒和帕玛森芝士，与弹牙的意面拌匀。半小时即可完成的工作日经典。",
            heroIngredients: ["意面 300 克", "番茄酱 2 杯", "大蒜 3 瓣", "新鲜罗勒 1 杯", "淡奶油 ½ 杯", "帕玛森芝士 50 克"],
            heroSteps: ["在盐水中将意面煮至弹牙。", "用橄榄油炒香大蒜。", "加入番茄酱煮 10 分钟。", "拌入淡奶油和一半罗勒。", "将意面与酱汁拌匀，撒上帕玛森芝士。"],
            heroTips: ["留一点煮面水用来稀释酱汁。", "罗勒在关火后再加入。"],
            heroTags: ["素食", "快手", "暖心"],
            heroAllergens: ["麸质", "乳制品"],
            cuisine: "意大利", easy: "简单",
            heroCook: "25 分钟", heroPrep: "10 分钟", heroTotal: "35 分钟",
            salmonName: "烤三文鱼碗", cakeName: "莓果松饼", saladName: "卡普雷塞沙拉",
            minuteUnit: "分钟"),

        "ru": Copy(
            heroName: "Сливочная паста с томатами и базиликом",
            heroDescription: "Шелковистый томатный соус со свежим базиликом и пармезаном, смешанный с пастой аль денте. Классика будних дней всего за полчаса.",
            heroIngredients: ["300 г пасты", "2 стакана томатной пассаты", "3 зубчика чеснока", "1 стакан свежего базилика", "½ стакана сливок", "50 г пармезана"],
            heroSteps: ["Отварите пасту в подсоленной воде до аль денте.", "Обжарьте чеснок в оливковом масле до аромата.", "Добавьте пассату и тушите 10 минут.", "Вмешайте сливки и половину базилика.", "Смешайте пасту с соусом и посыпьте пармезаном."],
            heroTips: ["Оставьте немного воды от пасты, чтобы разбавить соус.", "Добавляйте базилик, сняв с огня."],
            heroTags: ["Вегетарианское", "Быстро", "Уютно"],
            heroAllergens: ["Глютен", "Молочное"],
            cuisine: "Итальянская", easy: "Легко",
            heroCook: "25 мин", heroPrep: "10 мин", heroTotal: "35 мин",
            salmonName: "Боул с лососем гриль", cakeName: "Панкейки с ягодами", saladName: "Салат Капрезе",
            minuteUnit: "мин"),

        "pt": Copy(
            heroName: "Massa Cremosa de Tomate e Manjericão",
            heroDescription: "Molho de tomate aveludado com manjericão fresco e parmesão, envolvido em massa al dente. Um clássico de dias de semana pronto em meia hora.",
            heroIngredients: ["300 g de massa", "2 chávenas de passata de tomate", "3 dentes de alho", "1 chávena de manjericão fresco", "½ chávena de natas", "50 g de parmesão"],
            heroSteps: ["Coza a massa em água com sal até ficar al dente.", "Refogue o alho em azeite até libertar aroma.", "Junte a passata e deixe cozinhar 10 minutos.", "Envolva as natas e metade do manjericão.", "Misture a massa com o molho e finalize com parmesão."],
            heroTips: ["Reserve um pouco de água da massa para soltar o molho.", "Junte o manjericão fora do lume."],
            heroTags: ["Vegetariano", "Rápido", "Reconfortante"],
            heroAllergens: ["Glúten", "Lacticínios"],
            cuisine: "Italiana", easy: "Fácil",
            heroCook: "25 min", heroPrep: "10 min", heroTotal: "35 min",
            salmonName: "Bowl de Salmão Grelhado", cakeName: "Panquecas de Frutos Vermelhos", saladName: "Salada Caprese",
            minuteUnit: "min")
    ]
}
#endif
