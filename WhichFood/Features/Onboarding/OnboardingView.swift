import SwiftUI
import UserNotifications

struct OnboardingView: View {
    let completion: () -> Void

    @State private var showingWelcome = true
    @State private var step = 0
    @State private var skill: String?
    @State private var equipment = Set<String>()
    @State private var dietary = Set<String>()
    @State private var servingChoice: String?
    @State private var notificationChoice: String?

    private let totalSteps = 5

    var body: some View {
        Group {
            if showingWelcome {
                welcome
                    .transition(.opacity)
            } else {
                questionFlow
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.28), value: showingWelcome)
    }

    private var welcome: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                ZStack {
                    WFPalette.heroGradient
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundColor(WFPalette.orange)
                            .frame(width: 88, height: 88)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: WFPalette.text.opacity(0.14), radius: 18, y: 8)
                        Text("WhichFood")
                            .font(WFFont.heading(34, weight: .heavy))
                            .foregroundColor(.white)
                        Text("Your personal AI chef")
                            .font(WFFont.body(15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.86))
                    }
                }
                .frame(height: proxy.size.height * 0.53)
                .clipShape(WFRoundedCorners(radius: 36, corners: [.bottomLeft, .bottomRight]))

                VStack(alignment: .leading, spacing: 14) {
                    Text("Turn what's in your kitchen into tonight's dinner.")
                        .font(WFFont.heading(26, weight: .bold))
                        .foregroundColor(WFPalette.text)
                        .lineSpacing(3)
                    Text("Pick your ingredients — or snap a photo of a dish — and get a complete, personalized recipe in seconds.")
                        .font(WFFont.body(15))
                        .foregroundColor(WFPalette.secondaryText)
                        .lineSpacing(4)
                    Spacer(minLength: 8)
                    Button("Let's get cooking") {
                        showingWelcome = false
                    }
                    .buttonStyle(WFPrimaryButtonStyle())
                    Button("I've been here before") {
                        finish()
                    }
                    .font(WFFont.body(14, weight: .semibold))
                    .foregroundColor(WFPalette.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 38)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 18)
            }
            .wfScreenBackground()
        }
    }

    private var questionFlow: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                WFIconButton(systemName: "chevron.left") {
                    if step == 0 { showingWelcome = true } else { step -= 1 }
                }
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(WFPalette.border).frame(height: 6)
                        Capsule().fill(WFPalette.orange)
                            .frame(width: proxy.size.width * CGFloat(step + 1) / CGFloat(totalSteps), height: 6)
                            .animation(.easeOut(duration: 0.25), value: step)
                    }
                }
                .frame(height: 6)
                Button("Skip", action: finish)
                    .font(WFFont.body(13, weight: .bold))
                    .foregroundColor(WFPalette.secondaryText)
            }
            .padding(.bottom, 20)

            Text(title)
                .font(WFFont.heading(25, weight: .bold))
                .foregroundColor(WFPalette.text)
                .lineSpacing(3)
            Text(subtitle)
                .font(WFFont.body(14))
                .foregroundColor(WFPalette.secondaryText)
                .lineSpacing(3)
                .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(options, id: \.label) { option in
                        WFOnboardingOptionCard(
                            option: option,
                            selected: isSelected(option.label),
                            action: { select(option.label) }
                        )
                    }
                }
                .padding(.vertical, 22)
            }

            Button(step == totalSteps - 1 ? "Let's cook" : "Continue") {
                if step == totalSteps - 1 { finish() }
                else { step += 1 }
            }
            .buttonStyle(WFPrimaryButtonStyle(enabled: canContinue))
            .disabled(!canContinue)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 30)
        .wfScreenBackground()
    }

    private var title: String {
        [
            "How confident are you in the kitchen?",
            "What can you cook with?",
            "Any dietary needs?",
            "How many are you cooking for?",
            "When should we inspire you?"
        ][step]
    }

    private var subtitle: String {
        [
            "We'll match the detail and difficulty to your experience.",
            "Choose everything you have — you can update this later.",
            "Select all that apply so every suggestion feels right.",
            "We'll set recipe quantities to your usual table.",
            "Choose a helpful time for fresh meal ideas."
        ][step]
    }

    private var options: [WFOnboardingOption] {
        switch step {
        case 0:
            return [
                .init(label: "Just starting out", description: "I like clear, detailed guidance."),
                .init(label: "Home cook", description: "I'm comfortable with everyday recipes."),
                .init(label: "Confident chef", description: "Give me technique and room to improvise.")
            ]
        case 1:
            return ["Stovetop", "Oven", "Microwave", "Blender", "Air fryer", "Slow cooker"].map { .init(label: $0) }
        case 2:
            return ["No restrictions", "Vegetarian", "Vegan", "Gluten-free", "Dairy-free", "Nut allergy"].map { .init(label: $0) }
        case 3:
            return [
                .init(label: "Just me", description: "One serving"),
                .init(label: "2 people", description: "A meal for two"),
                .init(label: "3–4 people", description: "Family-sized recipes"),
                .init(label: "5 or more", description: "A full table")
            ]
        default:
            return [
                .init(label: "Morning", description: "Plan the day over breakfast"),
                .init(label: "Around noon", description: "A nudge before lunch"),
                .init(label: "Evening", description: "Ideas in time for dinner"),
                .init(label: "No thanks", description: "Keep notifications off")
            ]
        }
    }

    private var canContinue: Bool {
        switch step {
        case 0: return skill != nil
        case 1: return !equipment.isEmpty
        case 2: return !dietary.isEmpty
        case 3: return servingChoice != nil
        default: return notificationChoice != nil
        }
    }

    private func isSelected(_ label: String) -> Bool {
        switch step {
        case 0: return skill == label
        case 1: return equipment.contains(label)
        case 2: return dietary.contains(label)
        case 3: return servingChoice == label
        default: return notificationChoice == label
        }
    }

    private func select(_ label: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch step {
        case 0: skill = label
        case 1:
            if equipment.contains(label) { equipment.remove(label) } else { equipment.insert(label) }
        case 2:
            if label == "No restrictions" { dietary = [label] }
            else {
                dietary.remove("No restrictions")
                if dietary.contains(label) { dietary.remove(label) } else { dietary.insert(label) }
            }
        case 3: servingChoice = label
        default: notificationChoice = label
        }
    }

    private func finish() {
        let defaults = UserDefaults.standard
        defaults.set(skill ?? "Home cook", forKey: "userCookingSkill")
        defaults.set(Array(equipment), forKey: "userKitchenTools")
        defaults.set(Array(dietary), forKey: "userDietaryRestrictions")
        defaults.set(servingCount, forKey: "userPeopleCount")
        defaults.set(notificationChoice ?? "No thanks", forKey: "userNotificationPreference")
        defaults.set(true, forKey: "hasCompletedOnboarding")
        if notificationChoice != nil, notificationChoice != "No thanks" {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        completion()
    }

    private var servingCount: Int {
        switch servingChoice {
        case "Just me": return 1
        case "2 people": return 2
        case "3–4 people": return 4
        case "5 or more": return 6
        default: return 2
        }
    }
}

private struct WFOnboardingOption: Hashable {
    let label: String
    var description: String? = nil
}

private struct WFOnboardingOptionCard: View {
    let option: WFOnboardingOption
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(option.label)
                        .font(WFFont.heading(15.5, weight: .semibold))
                        .foregroundColor(WFPalette.text)
                    if let description = option.description {
                        Text(description)
                            .font(WFFont.body(12.5))
                            .foregroundColor(WFPalette.secondaryText)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(selected ? WFPalette.orange : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(selected ? WFPalette.orange : WFPalette.border, lineWidth: 2))
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(selected ? WFPalette.selectedBackground : WFPalette.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selected ? WFPalette.orange : WFPalette.border, lineWidth: selected ? 2 : 1.5)
            )
        }
        .buttonStyle(WFPressButtonStyle())
        .animation(.easeOut(duration: 0.15), value: selected)
    }
}
