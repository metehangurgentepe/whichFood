import UIKit
import ImageIO

/// The app's colour palette, and the single source of truth for both the UIKit
/// screens and the remaining SwiftUI ones.
///
/// Every value is a dynamic colour, so light and dark mode are handled by the
/// system rather than by branching at each call site.
enum WFUIPalette {

    private static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traits in traits.userInterfaceStyle == .dark ? dark : light }
    }

    private static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> UIColor {
        UIColor(red: r, green: g, blue: b, alpha: 1)
    }

    // MARK: Brand — near-identical in both modes, nudged lighter on dark so it
    // doesn't vibrate against a dark background.

    static let orange = dynamic(
        light: rgb(1.00, 0.341, 0.133),
        dark: rgb(1.00, 0.435, 0.239)
    )
    static let pressedOrange = dynamic(
        light: rgb(0.902, 0.290, 0.098),
        dark: rgb(0.851, 0.353, 0.176)
    )
    static let lightOrange = dynamic(
        light: rgb(1.00, 0.439, 0.263),
        dark: rgb(1.00, 0.522, 0.373)
    )
    static let amber = dynamic(
        light: rgb(1.00, 0.757, 0.027),
        dark: rgb(1.00, 0.796, 0.204)
    )

    /// Secondary accent — a fresh herb green that pairs with the orange so the
    /// UI reads as a deliberate two-colour system rather than all-orange.
    static let green = dynamic(
        light: rgb(0.176, 0.643, 0.404),
        dark: rgb(0.267, 0.769, 0.510)
    )
    static let greenBackground = dynamic(
        light: rgb(0.902, 0.965, 0.933),
        dark: rgb(0.106, 0.220, 0.169)
    )
    static let greenText = dynamic(
        light: rgb(0.098, 0.478, 0.318),
        dark: rgb(0.443, 0.851, 0.616)
    )

    // MARK: Surfaces

    static let background = dynamic(
        light: rgb(1.00, 0.984, 0.961),
        dark: rgb(0.071, 0.063, 0.059)
    )
    static let card = dynamic(
        light: .white,
        dark: rgb(0.133, 0.122, 0.114)
    )
    /// Deliberately-dark surface (cook button, review bar). In dark mode it has
    /// to go *lighter* than the background to stay legible as a raised surface.
    static let dark = dynamic(
        light: rgb(0.102, 0.082, 0.071),
        dark: rgb(0.212, 0.196, 0.180)
    )

    // MARK: Text

    static let text = dynamic(
        light: rgb(0.102, 0.082, 0.071),
        dark: rgb(0.976, 0.965, 0.953)
    )
    static let secondaryText = dynamic(
        light: rgb(0.541, 0.498, 0.463),
        dark: rgb(0.686, 0.655, 0.624)
    )
    static let tertiaryText = dynamic(
        light: rgb(0.788, 0.741, 0.694),
        dark: rgb(0.478, 0.451, 0.427)
    )
    static let inactive = dynamic(
        light: rgb(0.690, 0.647, 0.600),
        dark: rgb(0.545, 0.514, 0.482)
    )

    // MARK: Lines

    static let border = dynamic(
        light: rgb(0.941, 0.902, 0.863),
        dark: rgb(0.235, 0.216, 0.200)
    )
    static let divider = dynamic(
        light: rgb(0.969, 0.941, 0.910),
        dark: rgb(0.196, 0.180, 0.169)
    )

    // MARK: Selection

    static let selectedBackground = dynamic(
        light: rgb(1.00, 0.953, 0.878),
        dark: rgb(0.243, 0.184, 0.098)
    )
    static let selectedText = dynamic(
        light: rgb(0.902, 0.318, 0),
        dark: rgb(1.00, 0.588, 0.310)
    )

    /// Pill sitting directly on a photo (favourite button, badges) — always a
    /// light chip, since the photo behind it is arbitrary in both modes.
    static let onPhotoChip = UIColor.white.withAlphaComponent(0.92)
    static let onPhotoChipText = rgb(0.102, 0.082, 0.071)

    // MARK: Nutrition macros (foreground / tinted background pairs)

    static let macroCarbsText = dynamic(light: rgb(0.96, 0.50, 0.09), dark: rgb(1.00, 0.647, 0.298))
    static let macroCarbsBackground = dynamic(light: rgb(1.00, 0.97, 0.88), dark: rgb(0.243, 0.184, 0.078))
    static let macroProteinText = dynamic(light: rgb(0.85, 0.26, 0.08), dark: rgb(1.00, 0.478, 0.322))
    static let macroProteinBackground = dynamic(light: rgb(0.98, 0.91, 0.90), dark: rgb(0.251, 0.145, 0.125))
    static let macroFatText = dynamic(light: rgb(0.36, 0.25, 0.22), dark: rgb(0.804, 0.706, 0.663))
    static let macroFatBackground = dynamic(light: rgb(0.94, 0.92, 0.91), dark: rgb(0.204, 0.184, 0.176))
}

/// The app ships Montserrat and Open Sans as *variable* fonts, so their weights
/// can't be addressed by PostScript name. Resolve them through a family
/// descriptor instead, falling back to the system font if registration failed.
enum WFUIFont {
    static func heading(_ size: CGFloat, weight: UIFont.Weight = .bold) -> UIFont {
        font(family: "Montserrat", size: size, weight: weight)
    }

    static func body(_ size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        font(family: "Open Sans", size: size, weight: weight)
    }

    private static func font(family: String, size: CGFloat, weight: UIFont.Weight) -> UIFont {
        guard UIFont.familyNames.contains(family) else {
            return .systemFont(ofSize: size, weight: weight)
        }

        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: family,
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: size)
    }
}

// MARK: - Appearance

/// App-wide light / dark / system override, applied to every window.
enum WFAppearanceMode: Int, CaseIterable {
    case system, light, dark

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }

    var titleKey: String {
        switch self {
        case .system: return "appearance_system"
        case .light: return "appearance_light"
        case .dark: return "appearance_dark"
        }
    }

    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

enum WFAppearanceManager {
    private static let key = "wf.appearanceMode"

    static var current: WFAppearanceMode {
        get { WFAppearanceMode(rawValue: UserDefaults.standard.integer(forKey: key)) ?? .system }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
            apply()
        }
    }

    /// Push the stored preference onto every live window.
    static func apply() {
        let style = current.interfaceStyle
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}

// MARK: - Shared components

/// Rounded, bordered container used for every card on the redesigned screens.
final class WFUICardView: UIView {
    init(cornerRadius: CGFloat = 18) {
        super.init(frame: .zero)
        backgroundColor = WFUIPalette.card
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = WFUIPalette.border.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previous) else { return }
        // CGColors are resolved once and don't follow the trait change
        layer.borderColor = WFUIPalette.border.cgColor
    }
}

final class WFUISectionTitleLabel: UILabel {
    init(_ title: String) {
        super.init(frame: .zero)
        text = title
        font = WFUIFont.heading(17, weight: .bold)
        textColor = WFUIPalette.text
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Primary filled action button (`WFPrimaryButtonStyle`).
final class WFUIPrimaryButton: UIButton {
    init(title: String, systemImage: String? = nil) {
        super.init(frame: .zero)

        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = WFUIPalette.orange
        config.baseForegroundColor = .white
        config.cornerStyle = .fixed
        config.background.cornerRadius = 18
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        config.imagePadding = 8
        if let systemImage {
            config.image = UIImage(systemName: systemImage)
        }
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = WFUIFont.heading(16, weight: .bold)
            return outgoing
        }
        configuration = config

        layer.shadowColor = WFUIPalette.orange.cgColor
        layer.shadowOpacity = 0.28
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 8)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Async image view backing the recipe hero, mirroring `WFRemoteImage`.
final class WFUIRemoteImageView: UIImageView {
    /// Shared across every instance so rebuilding a grid (e.g. after a favourite
    /// toggle) shows cached images instantly instead of re-fetching and
    /// flickering. Keyed by "url|width×height" since we downsample per frame.
    private static let cache = NSCache<NSString, UIImage>()

    private let spinner = UIActivityIndicatorView(style: .medium)
    private var task: URLSessionDataTask?
    private var currentURL: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .scaleAspectFill
        clipsToBounds = true
        backgroundColor = WFUIPalette.selectedBackground

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = WFUIPalette.orange
        addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func load(urlString: String?) {
        guard currentURL != urlString else { return }
        currentURL = urlString

        task?.cancel()
        image = nil

        guard let urlString, let url = URL(string: urlString) else {
            spinner.stopAnimating()
            return
        }

        // Serve from cache synchronously — no spinner, no flicker on rebuild
        let cacheKey = Self.cacheKey(urlString, size: bounds.size)
        if let cached = Self.cache.object(forKey: cacheKey) {
            spinner.stopAnimating()
            image = cached
            return
        }

        spinner.startAnimating()
        let targetSize = bounds.size
        task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self else { return }
            let loaded = data.flatMap { Self.downsample($0, to: targetSize) }
            if let loaded {
                Self.cache.setObject(loaded, forKey: cacheKey)
            }
            DispatchQueue.main.async {
                // A newer load may have started while this one was in flight
                guard self.currentURL == urlString else { return }
                self.spinner.stopAnimating()
                self.image = loaded
            }
        }
        task?.resume()
    }

    private static func cacheKey(_ urlString: String, size: CGSize) -> NSString {
        "\(urlString)|\(Int(size.width))×\(Int(size.height))" as NSString
    }

    /// Decodes at the size actually being displayed. Handing UIImageView a
    /// multi-megapixel photo to squeeze into a small frame gives harsh,
    /// aliased edges.
    private static func downsample(_ data: Data, to size: CGSize) -> UIImage? {
        guard size.width > 0, size.height > 0,
              let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary)
        else {
            return UIImage(data: data)
        }

        let maxPixel = max(size.width, size.height) * UIScreen.main.scale
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: thumbnail)
    }
}

/// Dashed vertical rule connecting instruction step numbers.
final class WFUIStepConnectorView: UIView {
    private let shapeLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        shapeLayer.strokeColor = WFUIPalette.orange.withAlphaComponent(0.4).cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.lineDashPattern = [4, 4]
        layer.addSublayer(shapeLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let path = UIBezierPath()
        path.move(to: CGPoint(x: bounds.midX, y: 0))
        path.addLine(to: CGPoint(x: bounds.midX, y: bounds.height))
        shapeLayer.path = path.cgPath
        shapeLayer.frame = bounds
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previous) else { return }
        shapeLayer.strokeColor = WFUIPalette.orange.withAlphaComponent(0.4).cgColor
    }
}

/// Lays its subviews out left-to-right, wrapping onto new rows — the UIKit
/// equivalent of `LazyVGrid(columns: [GridItem(.adaptive(...))])`.
final class WFUIWrapView: UIView {
    var horizontalSpacing: CGFloat = 10
    var verticalSpacing: CGFloat = 10

    private var contentHeight: CGFloat = 0

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: contentHeight)
    }

    func setItems(_ items: [UIView]) {
        subviews.forEach { $0.removeFromSuperview() }
        items.forEach {
            // This view lays out by frame, so items must opt back into
            // autoresizing rather than fighting Auto Layout.
            $0.translatesAutoresizingMaskIntoConstraints = true
            addSubview($0)
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let maxWidth = bounds.width
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for item in subviews {
            // systemLayoutSizeFitting honours the item's own constraints;
            // intrinsicContentSize ignores them and collapses to content size.
            var size = item.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            if size.height <= 0 {
                size.height = item.intrinsicContentSize.height
            }
            size.width = min(size.width, maxWidth)

            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }

            item.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }

        let newHeight = y + rowHeight
        if abs(newHeight - contentHeight) > 0.5 {
            contentHeight = newHeight
            invalidateIntrinsicContentSize()
        }
    }
}

extension UIStackView {
    /// Convenience for the many small stacks these screens are built from.
    static func wf(
        axis: NSLayoutConstraint.Axis,
        spacing: CGFloat = 0,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill,
        views: [UIView] = []
    ) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = axis
        stack.spacing = spacing
        stack.alignment = alignment
        stack.distribution = distribution
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }
}
