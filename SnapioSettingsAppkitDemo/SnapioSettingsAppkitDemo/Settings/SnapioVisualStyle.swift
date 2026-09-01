import AppKit

enum SnapioVisualMetrics {
    static let panelCornerRadius: CGFloat = 12
    static let contentPadding: CGFloat = 14
    static let sectionSpacing: CGFloat = 12
    static let compactSpacing: CGFloat = 6
    static let controlHeight: CGFloat = 28
    static let compactControlHeight: CGFloat = 24
    static let thumbnailCornerRadius: CGFloat = 8
}

enum SnapioButtonEmphasis {
    case primary
    case standard
    case quiet
}

enum SnapioControlDensity {
    case regular
    case compact
}

enum SnapioButtonPresentation {
    case titleAndIcon
    case iconOnly
}

@MainActor
enum SnapioVisualStyle {
    static func hudShadow() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
        shadow.shadowBlurRadius = 10
        shadow.shadowOffset = NSSize(width: 0, height: -2)
        return shadow
    }

    static func mosaicCheckerboardImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.lockFocus()

        let bounds = NSRect(x: 1, y: 1, width: 14, height: 14)
        NSColor.black.setStroke()
        let border = NSBezierPath(rect: bounds)
        border.lineWidth = 1.25
        border.stroke()

        NSColor.black.setFill()
        NSBezierPath(
            rect: NSRect(x: 1, y: 8, width: 7, height: 7)
        ).fill()
        NSBezierPath(
            rect: NSRect(x: 8, y: 1, width: 7, height: 7)
        ).fill()

        image.unlockFocus()
        image.isTemplate = true
        image.accessibilityDescription = "Mosaic checkerboard"
        return image
    }

    static func configureButton(
        _ button: NSButton,
        symbolName: String,
        emphasis: SnapioButtonEmphasis = .standard,
        density: SnapioControlDensity = .regular,
        presentation: SnapioButtonPresentation = .titleAndIcon,
        toolTip: String,
        accessibilityLabel: String? = nil
    ) {
        button.bezelStyle = .rounded
        let isCompact = density == .compact
        button.controlSize = isCompact ? .small : .regular
        button.font = .systemFont(
            ofSize: isCompact
                ? NSFont.smallSystemFontSize
                : NSFont.systemFontSize,
            weight: emphasis == .primary ? .medium : .regular
        )
        if presentation == .iconOnly {
            button.image = NSImage(
                systemSymbolName: symbolName,
                accessibilityDescription: accessibilityLabel ?? button.title
            )
            button.imagePosition = .imageOnly
        } else {
            button.image = nil
            button.imagePosition = .noImage
        }
        button.imageScaling = .scaleProportionallyDown
        button.toolTip = toolTip
        button.setAccessibilityLabel(accessibilityLabel ?? button.title)
        button.heightAnchor.constraint(
            greaterThanOrEqualToConstant: isCompact
                ? SnapioVisualMetrics.compactControlHeight
                : SnapioVisualMetrics.controlHeight
        ).isActive = true
        if presentation == .iconOnly {
            button.widthAnchor.constraint(
                greaterThanOrEqualToConstant: isCompact
                    ? SnapioVisualMetrics.compactControlHeight
                    : SnapioVisualMetrics.controlHeight
            ).isActive = true
        }

        switch emphasis {
        case .primary:
            button.bezelColor = nil
            button.contentTintColor = nil
        case .standard:
            button.bezelColor = nil
            button.contentTintColor = .labelColor
        case .quiet:
            button.bezelColor = nil
            button.contentTintColor = .labelColor
        }
    }
}
