//
//  PaywallView.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 13.01.2025.
//

import Foundation
import SwiftUI
import RevenueCat

struct SwiftUIColors {
    static let primary = Color(UIColor(hex: 0xFF5722))
    static let accent = Color(UIColor(hex: 0xFFC107))
    static let secondprimary = Color(UIColor(hex: 0x916400))
    static let secondary = Color(UIColor(hex: 0x916400))
    static let crownColor = Color(UIColor(hex: 0xffbb48))
    static let text = Color.black
    static let opacWhite = Color(UIColor(hex: 0xfffbf5))
    static let containerBackground = Color(UIColor(hex: 0x878a87))
}

struct Feature {
    let icon: String
    let title: String
    let description: String
}

struct SubscriptionView: View {
    @StateObject private var viewModel = PaywallViewModel()
    @State private var selectedPlan: PlanType = .yearly
    @Environment(\.dismiss) private var dismiss
    
    let features = [
        Feature(icon: "chef-hat-fill",
                title: LocaleKeys.Paywall.aiRecipeTitle.rawValue.locale(),
                description: LocaleKeys.Paywall.aiRecipeDesc.rawValue.locale()),
        Feature(icon: "fork-knife-fill",
                title: LocaleKeys.Paywall.photoRecipeTitle.rawValue.locale(),
                description: LocaleKeys.Paywall.photoRecipeDesc.rawValue.locale())
    ]
    
    enum PlanType {
        case yearly
        case monthly
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Add close button overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray)
                            .padding(.trailing, 16)
                            .padding(.top, 16)
                    }
                }
                Spacer()
            }
            .zIndex(1) // Ensure button stays on top
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image("splash_logo")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 100, height: 100)
                    }
                    .padding(.top, 40)

                    // What's Inside Section - Moved up
                    VStack(spacing: 20) {
                        Text(LocaleKeys.Paywall.whatsInside.rawValue.locale())
                            .font(.system(size: 28, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Features List
                        VStack(spacing: 20) {
                            ForEach(features, id: \.title) { feature in
                                FeatureRow(feature: feature)
                            }
                        }
                    }
                    .padding(.vertical, 20)

                    // Subscription Plans Section
                    if let offering = viewModel.currentOffering {
                        VStack(spacing: 16) {
                            if let annual = offering.annual {
                                PlanCard(
                                    isSelected: selectedPlan == .yearly,
                                    title: "plan_yearly".locale(),
                                    price: annual.localizedPriceString,
                                    monthlyPrice: viewModel.calculateSavings(for: annual),
                                    isPopular: true,
                                    isBestOffer: true
                                )
                                .onTapGesture {
                                    selectedPlan = .yearly
                                    viewModel.selectedPackage = annual
                                }
                            }

                            if let monthly = offering.monthly {
                                PlanCard(
                                    isSelected: selectedPlan == .monthly,
                                    title: "plan_monthly".locale(),
                                    price: monthly.localizedPriceString,
                                    monthlyPrice: nil,
                                    isPopular: false,
                                    isBestOffer: false
                                )
                                .onTapGesture {
                                    selectedPlan = .monthly
                                    viewModel.selectedPackage = monthly
                                }
                            }
                        }
                    }
                    
                    Color.clear.frame(height: 200)
                }
                .padding(.horizontal)
            }
            .background(Color(UIColor.systemBackground))
            
            // Update Footer section
            VStack(spacing: 16) {
                if let selectedPackage = viewModel.selectedPackage {
                    Text(String(format: "plan_subscribe_terms".locale(),
                              selectedPackage.localizedPriceString,
                              selectedPackage.packageType == .annual ? 
                                "plan_per_year".locale() : 
                                "plan_per_week".locale()))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    if let package = viewModel.selectedPackage {
                        viewModel.purchase(package: package)
                    }
                }) {
                    if viewModel.isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(LocaleKeys.Paywall.subscribeNow.rawValue.locale())
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(SwiftUIColors.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(viewModel.isPurchasing)
                
                
                HStack(spacing: 16) {
                    Link("settings_terms_of_service".locale(),
                         destination: URL(string: Constants.Links.termsOfService.rawValue)!)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    
                    Button(action: {
                        viewModel.restorePurchases()
                    }) {
                        HStack {
                            Image("lock-key-fill")
                                .foregroundColor(.secondary)
                            Text(LocaleKeys.Paywall.restorePurchases.rawValue.locale())
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link("settings_privacy_policy".locale(),
                         destination: URL(string: Constants.Links.privacyPolicy.rawValue)!)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 40)
            .background(
                Color(UIColor.systemBackground)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
            )
        }
        .edgesIgnoringSafeArea(.bottom)
        .alert(LocaleKeys.Paywall.errorTitle.rawValue.locale(),
               isPresented: .constant(viewModel.errorMessage != nil)) {
            Button(LocaleKeys.Paywall.ok.rawValue.locale()) {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
    }
}

struct FeatureRow: View {
    let feature: Feature
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Circle
            ZStack {
                Circle()
                    .fill(SwiftUIColors.primary.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(feature.icon)
                    .foregroundColor(SwiftUIColors.primary)
                    .font(.system(size: 20))
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 20, weight: .bold))
                
                Text(feature.description)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PlanCard: View {
    let isSelected: Bool
    let title: String
    let price: String
    let monthlyPrice: String?
    let isPopular: Bool
    let isBestOffer: Bool
    
    var body: some View {
        ZStack(alignment: .top) {
            if isPopular {
                Text("plan_most_popular".locale())
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(SwiftUIColors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .offset(y: -20)
                    .zIndex(1)
                    .padding(.top,4)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        if isBestOffer {
                            Text("plan_best_offer".locale())
                                .font(.subheadline)
                                .foregroundColor(SwiftUIColors.primary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(price)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        if let monthlyPrice = monthlyPrice {
                            Text(monthlyPrice)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? SwiftUIColors.primary : Color.gray.opacity(0.2), lineWidth: 2)
                    )
            )
        }
    }
}

#Preview {
    SubscriptionView()
}
