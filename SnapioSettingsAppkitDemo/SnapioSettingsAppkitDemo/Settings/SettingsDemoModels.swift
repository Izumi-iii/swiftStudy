import Foundation

public struct ShortcutModifiers: OptionSet, Hashable, Codable, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let command = Self(rawValue: 1 << 0)
    public static let option = Self(rawValue: 1 << 1)
    public static let control = Self(rawValue: 1 << 2)
    public static let shift = Self(rawValue: 1 << 3)

    public static let registrationModifiers: Self = [
        .command,
        .option,
        .control
    ]
}

public struct KeyboardShortcut: Equatable, Hashable, Codable, Sendable {
    public let keyCode: UInt16
    public let modifiers: ShortcutModifiers

    public init(keyCode: UInt16, modifiers: ShortcutModifiers) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public var isStructurallyValid: Bool {
        keyCode <= 127
            && !modifiers.intersection(.registrationModifiers).isEmpty
    }
}

public enum ShortcutError: Error, Equatable, Sendable {
    case invalidCombination
    case alreadyRegistered
    case systemRejected
    case persistenceFailed
}

public struct DirectoryReference: Equatable, Codable, Sendable {
    public let bookmarkData: Data
    public let displayPath: String

    public init(bookmarkData: Data, displayPath: String) {
        self.bookmarkData = bookmarkData
        self.displayPath = displayPath
    }
}

public enum DirectoryStatus: Equatable, Sendable {
    case unset
    case valid(DirectoryReference)
    case stale(DirectoryReference)
}

public enum SettingsError: Error, Equatable, Sendable {
    case loadFailed
    case saveFailed
    case invalidDirectoryGrant
}

public enum PermissionStatus: Equatable, Sendable {
    case unknown
    case missing
    case granted
}

public struct PermissionSnapshot: Equatable, Sendable {
    public let screenCapture: PermissionStatus

    public init(screenCapture: PermissionStatus) {
        self.screenCapture = screenCapture
    }

    public static let unknown = PermissionSnapshot(screenCapture: .unknown)
}

public struct OutputOptions: Equatable, Codable, Sendable {
    public var fileNameTemplate: String
    public var showsSaveNotification: Bool

    public init(
        fileNameTemplate: String = Self.defaultFileNameTemplate,
        showsSaveNotification: Bool = true
    ) {
        self.fileNameTemplate = fileNameTemplate
        self.showsSaveNotification = showsSaveNotification
    }

    public static let defaultFileNameTemplate =
        "Snapio_$yyyy-MM-dd_HH-mm-ss$.png"
    public static let `default` = OutputOptions()

    public func suggestedFileName(date: Date = Date()) -> String {
        let expanded = Self.expandDateTokens(
            in: fileNameTemplate,
            date: date
        )
        let sanitized = Self.sanitizeFileName(expanded)
        return sanitized.hasSuffix(".png") ? sanitized : "\(sanitized).png"
    }

    public static func previewFileName(
        template: String,
        date: Date = Date()
    ) -> String {
        OutputOptions(fileNameTemplate: template)
            .suggestedFileName(date: date)
    }

    private static func expandDateTokens(
        in template: String,
        date: Date
    ) -> String {
        var result = ""
        var remainder = template[...]

        while let start = remainder.firstIndex(of: "$"),
              let end = remainder[remainder.index(after: start)...]
                .firstIndex(of: "$") {
            result += String(remainder[..<start])
            let format = String(remainder[remainder.index(after: start)..<end])
            result += formatted(date, with: format)
            remainder = remainder[remainder.index(after: end)...]
        }

        result += String(remainder)
        return result
    }

    private static func formatted(_ date: Date, with format: String) -> String {
        guard !format.isEmpty else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    private static func sanitizeFileName(_ fileName: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:")
            .union(.newlines)
            .union(.controlCharacters)
        let cleanedScalars = fileName.unicodeScalars.map { scalar in
            invalidCharacters.contains(scalar) ? "-" : Character(scalar)
        }
        let cleaned = String(cleanedScalars)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Snapio.png" : cleaned
    }
}

public enum AnnotationShortcutAction: String, CaseIterable, Codable, Sendable {
    case arrowTool
    case rectangleTool
    case textTool
    case brushTool
    case highlightTool
    case mosaicTool
    case copy
    case save
    case pin
    case undo
    case redo
    case delete
    case cancel
    case confirm
}

public struct AnnotationKeyboardShortcuts: Equatable, Codable, Sendable {
    public var arrowTool: KeyboardShortcut
    public var rectangleTool: KeyboardShortcut
    public var textTool: KeyboardShortcut
    public var brushTool: KeyboardShortcut
    public var highlightTool: KeyboardShortcut
    public var mosaicTool: KeyboardShortcut
    public var copy: KeyboardShortcut
    public var save: KeyboardShortcut
    public var pin: KeyboardShortcut
    public var undo: KeyboardShortcut
    public var redo: KeyboardShortcut
    public var delete: KeyboardShortcut
    public var cancel: KeyboardShortcut
    public var confirm: KeyboardShortcut

    public init(
        arrowTool: KeyboardShortcut = KeyboardShortcut(keyCode: 18, modifiers: []),
        rectangleTool: KeyboardShortcut = KeyboardShortcut(keyCode: 19, modifiers: []),
        textTool: KeyboardShortcut = KeyboardShortcut(keyCode: 20, modifiers: []),
        brushTool: KeyboardShortcut = KeyboardShortcut(keyCode: 21, modifiers: []),
        highlightTool: KeyboardShortcut = KeyboardShortcut(keyCode: 23, modifiers: []),
        mosaicTool: KeyboardShortcut = KeyboardShortcut(keyCode: 22, modifiers: []),
        copy: KeyboardShortcut = KeyboardShortcut(keyCode: 8, modifiers: .command),
        save: KeyboardShortcut = KeyboardShortcut(keyCode: 1, modifiers: .command),
        pin: KeyboardShortcut = KeyboardShortcut(keyCode: 20, modifiers: .command),
        undo: KeyboardShortcut = KeyboardShortcut(keyCode: 6, modifiers: .command),
        redo: KeyboardShortcut = KeyboardShortcut(keyCode: 6, modifiers: [.command, .shift]),
        delete: KeyboardShortcut = KeyboardShortcut(keyCode: 51, modifiers: []),
        cancel: KeyboardShortcut = KeyboardShortcut(keyCode: 53, modifiers: []),
        confirm: KeyboardShortcut = KeyboardShortcut(keyCode: 36, modifiers: [])
    ) {
        self.arrowTool = arrowTool
        self.rectangleTool = rectangleTool
        self.textTool = textTool
        self.brushTool = brushTool
        self.highlightTool = highlightTool
        self.mosaicTool = mosaicTool
        self.copy = copy
        self.save = save
        self.pin = pin
        self.undo = undo
        self.redo = redo
        self.delete = delete
        self.cancel = cancel
        self.confirm = confirm
    }

    public static let `default` = AnnotationKeyboardShortcuts()

    public subscript(action: AnnotationShortcutAction) -> KeyboardShortcut {
        switch action {
        case .arrowTool: return arrowTool
        case .rectangleTool: return rectangleTool
        case .textTool: return textTool
        case .brushTool: return brushTool
        case .highlightTool: return highlightTool
        case .mosaicTool: return mosaicTool
        case .copy: return copy
        case .save: return save
        case .pin: return pin
        case .undo: return undo
        case .redo: return redo
        case .delete: return delete
        case .cancel: return cancel
        case .confirm: return confirm
        }
    }
}
