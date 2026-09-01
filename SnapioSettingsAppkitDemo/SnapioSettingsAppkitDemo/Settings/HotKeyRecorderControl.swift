import AppKit

@MainActor
public final class HotKeyRecorderControl: NSControl {
    public enum ValidationMode {
        case global
        case local
    }
    public private(set) var recordedShortcut: KeyboardShortcut?
    public var validationMode: ValidationMode = .global
    
    private let label = NSTextField(labelWithString: "Click to record")
    private var isRecording = false
    public var recordingDidChange: ((Bool) -> Void)?

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        buildView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var acceptsFirstResponder: Bool { true }

    public override func becomeFirstResponder() -> Bool {
        setRecording(true)
        return true
    }

    public override func resignFirstResponder() -> Bool {
        setRecording(false)
        needsDisplay = true
        return true
    }

    public override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    public override func keyDown(with event: NSEvent) {
        recordShortcut(from: event)
    }

    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isRecording else {
            return super.performKeyEquivalent(with: event)
        }
        guard event.type == .keyDown else { return false }
        recordShortcut(from: event)
        return true
    }

    private func recordShortcut(from event: NSEvent) {
        if event.keyCode == 53 {
            window?.makeFirstResponder(nil)
            return
        }

        let shortcut = KeyboardShortcut(
            keyCode: event.keyCode,
            modifiers: Self.modifiers(from: event.modifierFlags)
        )
        guard isValid(shortcut) else {
            NSSound.beep()
            return
        }

        recordedShortcut = shortcut
        isRecording = false
        updateLabel()
        sendAction(action, to: target)
        window?.makeFirstResponder(nil)
    }
    
    private func setRecording(_ recording: Bool) {
        guard isRecording != recording else { return }
        isRecording = recording
        recordingDidChange?(recording)
        updateLabel()
        needsDisplay = true
    }

    public func display(_ shortcut: KeyboardShortcut?) {
        recordedShortcut = shortcut
        updateLabel()
        needsDisplay = true
    }

    public override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            xRadius: 7,
            yRadius: 7
        )
        NSColor.controlBackgroundColor.setFill()
        path.fill()
        (isRecording ? NSColor.controlAccentColor : NSColor.separatorColor)
            .setStroke()
        path.lineWidth = isRecording ? 2 : 1
        path.stroke()
    }

    public override func drawFocusRingMask() {
        NSBezierPath(
            roundedRect: bounds.insetBy(dx: 1, dy: 1),
            xRadius: 6,
            yRadius: 6
        ).fill()
    }

    public override var focusRingMaskBounds: NSRect { bounds }

    private func buildView() {
        translatesAutoresizingMaskIntoConstraints = false
        focusRingType = .exterior
        setAccessibilityRole(.button)
        setAccessibilityLabel("Global shortcut recorder")
        setAccessibilityHelp("Click, then press the shortcut you want Snapio to use.")
        toolTip = "Click, then press the shortcut you want Snapio to use"

        label.alignment = .center
        label.font = .monospacedSystemFont(
            ofSize: NSFont.systemFontSize,
            weight: .medium
        )
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(greaterThanOrEqualToConstant: 170),
            heightAnchor.constraint(equalToConstant: 30),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        updateLabel()
    }

    private func updateLabel() {
        if isRecording {
            label.stringValue = "Press a shortcut…"
            label.textColor = .controlAccentColor
        } else if let recordedShortcut {
            label.stringValue = Self.displayString(for: recordedShortcut)
            label.textColor = .labelColor
        } else {
            label.stringValue = "Click to record"
            label.textColor = .secondaryLabelColor
        }
        setAccessibilityValue(label.stringValue)
    }

    private static func modifiers(
        from flags: NSEvent.ModifierFlags
    ) -> ShortcutModifiers {
        let flags = flags.intersection(.deviceIndependentFlagsMask)
        var result = ShortcutModifiers()
        if flags.contains(.command) { result.insert(.command) }
        if flags.contains(.option) { result.insert(.option) }
        if flags.contains(.control) { result.insert(.control) }
        if flags.contains(.shift) { result.insert(.shift) }
        return result
    }

    private static func displayString(
        for shortcut: KeyboardShortcut
    ) -> String {
        var result = ""
        if shortcut.modifiers.contains(.control) { result += "⌃" }
        if shortcut.modifiers.contains(.option) { result += "⌥" }
        if shortcut.modifiers.contains(.shift) { result += "⇧" }
        if shortcut.modifiers.contains(.command) { result += "⌘" }
        result += keyNames[shortcut.keyCode] ?? "Key \(shortcut.keyCode)"
        return result
    }

    private static func isReservedMenuShortcut(
        _ shortcut: KeyboardShortcut
    ) -> Bool {
        guard shortcut.modifiers == .command else { return false }
        return [4, 12, 13, 35, 43, 46].contains(shortcut.keyCode)
    }

    private func isValid(_ shortcut: KeyboardShortcut) -> Bool {
        switch validationMode {
        case .global:
            return shortcut.isStructurallyValid
                && !Self.isReservedMenuShortcut(shortcut)
        case .local:
            return shortcut.keyCode <= 127
                && !Self.isReservedMenuShortcut(shortcut)
        }
    }
    
    private static let keyNames: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G",
        6: "Z", 7: "X", 8: "C", 9: "V", 11: "B", 12: "Q",
        13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1",
        19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=",
        25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]",
        31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "↩",
        37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\",
        43: ",", 44: "/", 45: "N", 46: "M", 47: ".", 48: "⇥",
        49: "Space", 50: "`", 51: "⌫", 53: "Esc", 123: "←", 124: "→",
        125: "↓", 126: "↑"
    ]
}
