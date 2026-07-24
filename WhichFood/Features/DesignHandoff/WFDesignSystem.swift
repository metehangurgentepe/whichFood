import SwiftUI
import UIKit

/// Thin SwiftUI wrapper over `WFUIPalette`. Keeping one source of truth means
/// light/dark values can't drift between the two stacks; `Color(UIColor)`
/// preserves the dynamic behaviour.
enum WFPalette {
    static let orange = Color(WFUIPalette.orange)
    static let pressedOrange = Color(WFUIPalette.pressedOrange)
    static let lightOrange = Color(WFUIPalette.lightOrange)
    static let amber = Color(WFUIPalette.amber)
    static let background = Color(WFUIPalette.background)
    static let card = Color(WFUIPalette.card)
    static let text = Color(WFUIPalette.text)
    static let secondaryText = Color(WFUIPalette.secondaryText)
    static let tertiaryText = Color(WFUIPalette.tertiaryText)
    static let inactive = Color(WFUIPalette.inactive)
    static let border = Color(WFUIPalette.border)
    static let divider = Color(WFUIPalette.divider)
    static let selectedBackground = Color(WFUIPalette.selectedBackground)
    static let selectedText = Color(WFUIPalette.selectedText)
    static let dark = Color(WFUIPalette.dark)
    static let green = Color(WFUIPalette.green)
    static let greenBackground = Color(WFUIPalette.greenBackground)
    static let greenText = Color(WFUIPalette.greenText)

    static let primaryGradient = LinearGradient(
        colors: [lightOrange, orange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = RadialGradient(
        colors: [amber, lightOrange, orange],
        center: UnitPoint(x: 0.28, y: 0.2),
        startRadius: 10,
        endRadius: 420
    )
}

enum WFFont {
    static func heading(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom("Montserrat", size: size).weight(weight)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Open Sans", size: size).weight(weight)
    }
}

struct WFPrimaryButtonStyle: ButtonStyle {
    var enabled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(WFFont.heading(16, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(enabled ? WFPalette.orange : WFPalette.orange.opacity(0.42))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: enabled ? WFPalette.orange.opacity(0.28) : .clear,
                    radius: configuration.isPressed ? 5 : 12,
                    y: configuration.isPressed ? 3 : 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct WFIconButton: View {
    let systemName: String
    var foreground = WFPalette.text
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(foreground)
                .frame(width: 38, height: 38)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(WFPalette.border, lineWidth: 1)
                )
        }
        .buttonStyle(WFPressButtonStyle())
    }
}

struct WFPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct WFChip: View {
    let title: String
    var selected = false
    var darkSelection = false
    var leadingSystemImage: String?
    var action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 6) {
                if let leadingSystemImage {
                    Image(systemName: leadingSystemImage)
                        .font(.system(size: 11, weight: .bold))
                }
                Text(title)
                    .font(WFFont.body(13, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(selected ? .white : WFPalette.text)
            .padding(.horizontal, 15)
            .frame(minHeight: 38)
            .background(selected ? (darkSelection ? WFPalette.dark : WFPalette.orange) : WFPalette.card)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(selected ? Color.clear : WFPalette.border, lineWidth: 1.5)
            )
        }
        .buttonStyle(WFPressButtonStyle())
        .animation(.easeOut(duration: 0.15), value: selected)
    }
}

struct WFSearchField: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(WFPalette.secondaryText)
            TextField(placeholder, text: $text)
                .font(WFFont.body(14))
                .foregroundColor(WFPalette.text)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(WFPalette.tertiaryText)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(WFPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(WFPalette.border, lineWidth: 1.5)
        )
    }
}

struct WFSectionTitle: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(WFFont.heading(17, weight: .bold))
                .foregroundColor(WFPalette.text)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(WFFont.body(12.5, weight: .semibold))
                    .foregroundColor(WFPalette.secondaryText)
            }
        }
    }
}

struct WFRemoteImage: View {
    let urlString: String?
    var cornerRadius: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [WFPalette.selectedBackground, WFPalette.amber.opacity(0.55), WFPalette.lightOrange.opacity(0.82)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if let urlString, let url = URL(string: urlString), !urlString.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        ProgressView().tint(WFPalette.orange)
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var placeholder: some View {
        Image(systemName: "fork.knife")
            .font(.system(size: 30, weight: .medium))
            .foregroundColor(.white.opacity(0.9))
    }
}

struct WFEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var dashed = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(WFPalette.lightOrange)
                .frame(width: 64, height: 64)
                .background(
                    LinearGradient(colors: [WFPalette.selectedBackground, WFPalette.amber.opacity(0.25)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .clipShape(Circle())
            Text(title)
                .font(WFFont.heading(16, weight: .bold))
                .foregroundColor(WFPalette.text)
            Text(message)
                .font(WFFont.body(13))
                .foregroundColor(WFPalette.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 24)
        .background(WFPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(WFPalette.border, style: StrokeStyle(lineWidth: 1.5, dash: dashed ? [7, 6] : []))
        )
    }
}

extension View {
    func wfScreenBackground() -> some View {
        background(WFPalette.background.ignoresSafeArea())
    }
}
