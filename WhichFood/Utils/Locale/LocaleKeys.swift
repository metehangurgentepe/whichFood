//
//  LocaleKeys.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 12.09.2023.
//

import Foundation
import SwiftUI
import UIKit


struct LocaleKeys {
    enum Tab: String{
        case home = "tabHome"
        case receipes = "tabReceips"
    }
    enum Premium: String{
        case weekButton = "premiumWeekButton"
        case lifetimeButton = "lifetimeButton"
        case continueButton = "continueButton"
        case title1 = "premium_1_title"
        case premium1 = "premium_1"
        case title2 = "premium_2_title"
        case premium2 = "premium_2"
        case title3 = "premium_3_title"
        case premium3 = "premium_3"
        case subscribed = "premium_subscribed"
        case subscribedSubheadline = "premium_subheadline"
        case latestExpirationDate = "premium_expiration"
        case restore = "premium_restore"
    }
    enum ShowFood: String{
        case prompt1 = "show_food_prompt1"
        case prompt2 = "show_food_prompt2"
        case prompt3 = "show_food_prompt3"
        case prompt4 = "show_food_prompt4"
    }
    enum Onboarding: String{
        case feature1 = "feature_1"
        case feature2 = "feature_2"
        case feature3 = "feature_3"
        case feature1Title = "feature_1_title"
        case feature2Ttitle = "feature_2_title"
        case feature3Title = "feature_3_title"
        case footer = "footer"
        case more = "more"
        case button = "feature_button"
        case welcome = "feature_welcome"
    }
    enum DetailRecipe: String {
        case ingredients = "detail_ingredients"
        case recipe = "detail_recipe"
        case savedSuccess = "detail_success"
        case saveButton = "detail_save"
        case success = "detail_success_title"
        case okButton = "detail_ok_button"
        case error = "detail_error_title"
        case errorMessage = "detail_error_message"
        case tryAgain = "detail_try_again"
        case errorOccured = "detail_error_occured"
    }
    enum Settings: String{
        case title = "settings_title"
        case userId = "settings_user"
        case premium = "settings_premium"
        case language = "settings_language"
        case darkMode = "settings_dark_mode"
        case writeMe = "settings_write_me"
        case aboutApp = "settings_about_app"
        case hello = "settings_hello"
        case mailTitleError = "settings_mail_title_error"
        case mailMessageError = "settings_mail_message_error"
        case okButton = "settings_ok_button"
        case selectTheme = "settings_select_theme"
        case lightModeButton = "settings_light_mode"
        case darkModeButton = "settings_dark_mode_button"
        case errorTitle = "settings_error_title"
        case errorMessage = "settings_error_message"
        case closeButton = "settings_close"
        case continueButton = "settings_continue"
    }
    enum Ingredient: String {
        case bread = "ingredients_bread"
        case garlic = "ingredients_garlic"
        case parsley = "ingredients_parsley"
        case tomato = "ingredients_tomato"
        case carrot = "ingredients_carrot"
        case potato = "ingredients_potato"
        case dill = "ingredients_dill"
        case springOnion = "ingredients_spring_onion"
        case pepper = "ingredients_pepper"
        case zucchini = "ingredients_zucchini"
        case eggplant = "ingredients_eggplant"
        case mushroom = "ingredients_mushroom"
        case freshBasil = "ingredients_fresh_basil"
        case lettuce = "ingredients_lettuce"
        case peas = "ingredients_peas"
        case spinach = "ingredients_spinach"
        case freshMint = "ingredients_fresh_mint"
        case celery = "ingredients_celery"
        case thyme = "ingredients_thyme"
        case egg = "ingredients_egg"
        case groundBeef = "ingredients_ground_beef"
        case chicken = "ingredients_chicken"
        case dicedBeef = "ingredients_diced_beef"
        case fish = "ingredients_fish"
        case lamb = "ingredients_lamb"
        case turkey = "ingredients_turkey"
        case beef = "ingredients_beef"
        case sausage = "ingredients_sausage"
        case hotDog = "ingredients_hot_dog"
        case calamari = "ingredients_calamari"
        case pastrami = "ingredients_pastrami"
        case butter = "ingredients_butter"
        case rice = "ingredients_rice"
        case bonito = "ingredients_bonito"
        case chickenNuggets = "ingredients_chicken_nuggets"
        case cheese = "ingredients_cheese"
        case yogurt = "ingredients_yogurt"
        case milk = "ingredients_milk"
        case cream = "ingredients_cream"
        case ricotta = "ingredients_ricotta"
        case lemon = "ingredients_lemon"
        case avocado = "ingredients_avocado"
        case grape = "ingredients_grape"
        case fig = "ingredients_fig"
        case orange = "ingredients_orange"
        case blackOlive = "ingredients_black_olive"
        case greenApple = "ingredients_green_apple"
        case strawberry = "ingredients_strawberry"
        case raspberry = "ingredients_raspberry"
        case blackberry = "ingredients_blackberry"
        case mulberry = "ingredients_mulberry"
        case kiwi = "ingredients_kiwi"
        case apple = "ingredients_apple"
        case pomegranate = "ingredients_pomegranate"
        case quince = "ingredients_quince"
        case walnut = "ingredients_walnut"
        case pineNuts = "ingredients_pine_nuts"
        case pistachio = "ingredients_pistachio"
        case sunDriedTomato = "ingredients_sun_dried_tomato"
        case coconut = "ingredients_coconut"
        case almond = "ingredients_almond"
        case hazelnut = "ingredients_hazelnut"
        case driedApricot = "ingredients_dried_apricot"
    }

    enum FoodCategory: String {
        case healthy = "category_healthy"
        case easy = "category_easy"
        case mid = "category_mid"
        case hard = "category_hard"
        case enjoy = "category_enjoy"
        case hearty = "category_hearty"
        case vegan = "category_vegan"
        case vegetarian = "category_vegetarian"
        case breakfast = "category_breakfast"
        case lunch = "category_lunch"
        case dinner = "category_dinner"
        case dessert = "category_dessert"
    }
    enum AccountScreen: String {
        case date = "account_date"
        case premium = "account_premium"
        case id = "account_id"
        case dateName = "account_last_date"
        case premiumName = "account_premium_name"
        case idName = "account_user_id"
        case copy = "account_copy"
        case title = "account_title"
        case numberOfUsageApi = "account_usage_api"
        
    }
    enum ImageToText: String {
        case info = "image_info"
    }
    enum Home: String {
        case recipe = "home_recipe"
        case button = "home_create_button"
        case noItem = "home_no_item"
        case showAlert = "image_info"
        case takePhoto = "take_photo"
    }
    enum SelectCategory: String{
        case nextButton = "next_button"
        case selectLabel = "select_label"
        case chooseOneOrMore = "choose_label"
    }
    enum SelectFood: String{
        case applyButton = "apply_button"
        case searchFood = "search_food"
    }
    enum Error: String {
        case alert = "error_alert"
        case oocured = "error_occured"
        case okButton = "error_ok_button"
        case backButton = "error_back_button"
        case apiUsageError = "error_api_usage"
    }
}
extension String{
    func locale() -> String {
        return NSLocalizedString(self, comment: "")
    }
}

