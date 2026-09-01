import AppKit

public struct SettingsViewState: Equatable {
    public let activeShortcut: KeyboardShortcut?
    public let currentDisplayShortcut: KeyboardShortcut?
    public let shortcutError: ShortcutError?
    public let directoryStatus: DirectoryStatus
    public let settingsError: SettingsError?
    public let annotationShortcuts: AnnotationKeyboardShortcuts
    public let permissionSnapshot: PermissionSnapshot
    public let isCheckingPermissions: Bool
    public let outputOptions: OutputOptions
    
    public init(
        activeShortcut: KeyboardShortcut?,
        currentDisplayShortcut: KeyboardShortcut?,
        shortcutError: ShortcutError?,
        directoryStatus: DirectoryStatus,
        settingsError: SettingsError?,
        annotationShortcuts: AnnotationKeyboardShortcuts,
        permissionSnapshot: PermissionSnapshot,
        isCheckingPermissions: Bool,
        outputOptions: OutputOptions
    ) {
        self.activeShortcut = activeShortcut
        self.currentDisplayShortcut = currentDisplayShortcut
        self.shortcutError = shortcutError
        self.directoryStatus = directoryStatus
        self.settingsError = settingsError
        self.annotationShortcuts = annotationShortcuts
        self.permissionSnapshot = permissionSnapshot
        self.isCheckingPermissions = isCheckingPermissions
        self.outputOptions = outputOptions
    }
}

enum SettingsPage: Int, CaseIterable, Hashable {
    case general
    case shortcuts
    case output
    
    var title: String {
        switch self {
        case .general:
            return "General"
        case .shortcuts:
            return "Shortcuts"
        case .output:
            return "Output"
        }
    }
    
    var symbolName: String {
        switch self {
        case .general:
            return "gearshape"
        case .shortcuts:
            return "keyboard"
        case .output:
            return "folder"
        }
    }
}

@MainActor
final class SettingsSidebarViewController:
    NSViewController,
    NSTableViewDataSource,
    NSTableViewDelegate {
    var selectionHandler: ((SettingsPage) -> Void)?

    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let backgroundWash = SettingsSidebarWashView()
    private var isSelectingProgrammatically = false

    override func loadView() {
        let visualView = NSVisualEffectView()
        visualView.material = .sidebar
        visualView.blendingMode = .withinWindow
        visualView.state = .active
        view = visualView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("SettingsPage"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.style = .sourceList
        tableView.rowHeight = 32
        tableView.intercellSpacing = .zero
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        backgroundWash.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundWash, positioned: .below, relativeTo: scrollView)

        NSLayoutConstraint.activate([
            backgroundWash.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundWash.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundWash.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundWash.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 72),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])

        tableView.reloadData()
        select(.general)
    }

    func select(_ page: SettingsPage) {
        isSelectingProgrammatically = true
        tableView.selectRowIndexes(
            IndexSet(integer: page.rawValue),
            byExtendingSelection: false
        )
        isSelectingProgrammatically = false
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        SettingsPage.allCases.count
    }

    func tableView(
        _ tableView: NSTableView,
        heightOfRow row: Int
    ) -> CGFloat {
        32
    }

    func tableView(
        _ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?,
        row: Int
    ) -> NSView? {
        guard row < SettingsPage.allCases.count else { return nil }

        let page = SettingsPage.allCases[row]
        let identifier = NSUserInterfaceItemIdentifier("SettingsSidebarItem")
        let cell = tableView.makeView(withIdentifier: identifier, owner: self)
            as? NSTableCellView ?? makeSidebarCell(identifier: identifier)

        cell.textField?.stringValue = page.title

        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard !isSelectingProgrammatically else { return }
        let row = tableView.selectedRow
        guard row >= 0, row < SettingsPage.allCases.count else { return }
        selectionHandler?(SettingsPage.allCases[row])
    }

    private func makeSidebarCell(
        identifier: NSUserInterfaceItemIdentifier
    ) -> NSTableCellView {
        let cell = NSTableCellView()
        cell.identifier = identifier

        let label = NSTextField(labelWithString: "")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.lineBreakMode = .byTruncatingTail

        cell.textField = label
        cell.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])

        return cell
    }
}

private final class SettingsSidebarWashView: NSView {
    override var isFlipped: Bool { true }
    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.systemSettingsSidebarWash.setFill()
        dirtyRect.fill()
    }
}

private final class FlippedDocumentView: NSView {
    override var isFlipped: Bool { true }
}

private final class RoundedBackgroundView: NSView {
    var fillColor: NSColor = .controlBackgroundColor {
        didSet { needsDisplay = true }
    }
    var cornerRadius: CGFloat = 10 {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        fillColor.setFill()
        NSBezierPath(
            roundedRect: bounds,
            xRadius: cornerRadius,
            yRadius: cornerRadius
        ).fill()
    }
}

private final class SettingsDetailBackgroundView: NSView {
    override var isFlipped: Bool { true }
    override var isOpaque: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.systemSettingsContentBackground.setFill()
        dirtyRect.fill()
    }
}

private extension NSColor {
    static var systemSettingsSidebarWash: NSColor {
        NSColor(name: nil) { appearance in
            let bestMatch = appearance.bestMatch(from: [.darkAqua, .aqua])
            if bestMatch == .darkAqua {
                return NSColor.black.withAlphaComponent(0.08)
            }
            return NSColor.white.withAlphaComponent(0.62)
        }
    }

    static var systemSettingsContentBackground: NSColor {
        NSColor(name: nil) { appearance in
            let bestMatch = appearance.bestMatch(from: [.darkAqua, .aqua])
            if bestMatch == .darkAqua {
                return NSColor.windowBackgroundColor
            }
            return NSColor(calibratedWhite: 0.985, alpha: 1)
        }
    }

    static var systemSettingsGroupBackground: NSColor {
        NSColor(name: nil) { appearance in
            let bestMatch = appearance.bestMatch(from: [.darkAqua, .aqua])
            if bestMatch == .darkAqua {
                return NSColor.white.withAlphaComponent(0.08)
            }
            return NSColor.white
        }
    }
}

@MainActor
public protocol SettingsViewDelegate: AnyObject {
    func settingsView(
        _ view: SettingsView,
        didRecord shortcut: KeyboardShortcut
    )
    func settingsView(
        _ view: SettingsView,
        didRecordAnnotationShortcut shortcut: KeyboardShortcut,
        for action: AnnotationShortcutAction
    )
    func settingsViewDidRequestDirectory(_ view: SettingsView)
    func settingsViewDidRequestDirectoryValidation(_ view: SettingsView)
    func settingsViewDidRequestDirectoryReveal(_ view: SettingsView)
    func settingsViewDidRequestPermissionGrant(_ view: SettingsView)
    func settingsView(
        _ view: SettingsView,
        didChangeOutputOptions outputOptions: OutputOptions
    )
    func settingsView(
        _ view: SettingsView,
        didRecordCurrentDisplayShortcut shortcut: KeyboardShortcut
    )
    func settingsView(
        _ view: SettingsView,
        didChangeShortcutRecording isRecording: Bool
    )
}

@MainActor
public final class SettingsView:
    NSView,
    NSTextFieldDelegate {
    private static let minimumSize = NSSize(width: 500, height: 520)

    public weak var delegate: SettingsViewDelegate?
    public override var isOpaque: Bool { false }
    
    private var selectedPage: SettingsPage = .general
    
    private let detailContainer = SettingsDetailBackgroundView()
    private var currentDetailView: NSView?
    
    private var generalPageView: NSView?
    private var shortcutsPageView: NSView?
    private var outputPageView: NSView?
    
    private var headerRowView: NSView?
    private var shortcutSectionView: NSView?
    private var annotationShortcutSectionView: NSView?
    private var directorySectionView: NSView?
    private var fileNamingSectionView: NSView?
    private var formatSectionView: NSView?
    private var appInfoSectionView: NSView?
    private var privacySectionView: NSView?

    private let headerIcon = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "General")
    private let subtitleLabel = NSTextField(
        wrappingLabelWithString: "Manage Snapio capture permissions and application behavior."
    )
    private let recorder = HotKeyRecorderControl(frame: .zero)
    private let currentDisplayRecorder = HotKeyRecorderControl(frame: .zero)
    private let annotationShortcutStack = NSStackView()
    private var annotationShortcutRecorders = [HotKeyRecorderControl: AnnotationShortcutAction]()
    private let directoryPath = NSTextField(labelWithString: "Not configured")
    private let directoryStatusIcon = NSImageView()
    private let chooseDirectoryButton = NSButton(
        title: "Choose Folder…",
        target: nil,
        action: nil
    )
    private let validateDirectoryButton = NSButton(
        title: "Check Access",
        target: nil,
        action: nil
    )
    private let revealDirectoryButton = NSButton(
        title: "Open Folder",
        target: nil,
        action: nil
    )
    private let saveNotificationCheckbox = NSButton(
        checkboxWithTitle: "Show notification after saving",
        target: nil,
        action: nil
    )
    private let quickSavePreview = NSTextField(labelWithString: "")
    private let fileNameTemplateField = NSTextField(string: "")
    private let fileNamePreview = NSTextField(labelWithString: "")
    private let restoreFileNameTemplateButton = NSButton(
        title: "Restore Default",
        target: nil,
        action: nil
    )
    private let settingsErrorBox = NSBox()
    private let settingsErrorIcon = NSImageView()
    private let settingsErrorLabel = NSTextField(labelWithString: "")

    private let permissionStatus = NSTextField(labelWithString: "Checking...")
    private let permissionStatusIcon = NSImageView()
    private let grantPermissionButton = NSButton(
        title: "Continue", target: nil, action: nil
    )
    private let permissionProgressIndicator = NSProgressIndicator()
    private var renderedOutputOptions = OutputOptions.default
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        buildView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func render(_ state: SettingsViewState) {
        recorder.display(state.activeShortcut)
        for (control, action) in annotationShortcutRecorders {
            control.display(state.annotationShortcuts[action])
        }

        switch state.directoryStatus {
        case .unset:
            directoryPath.stringValue = "No default folder"
            directoryPath.textColor = .secondaryLabelColor
            quickSavePreview.stringValue = "Preview: \(state.outputOptions.suggestedFileName())"
            validateDirectoryButton.isEnabled = false
            revealDirectoryButton.isEnabled = false
            updateStatusIcon(
                directoryStatusIcon,
                symbolName: "minus.circle",
                color: .secondaryLabelColor
            )
        case .valid(let reference):
            directoryPath.stringValue = reference.displayPath
            directoryPath.textColor = .labelColor
            quickSavePreview.stringValue = quickSavePreviewText(
                directoryPath: reference.displayPath,
                options: state.outputOptions
            )
            validateDirectoryButton.isEnabled = true
            revealDirectoryButton.isEnabled = true
            updateStatusIcon(
                directoryStatusIcon,
                symbolName: "checkmark.circle.fill",
                color: .systemGreen
            )
        case .stale(let reference):
            directoryPath.stringValue = "Access expired: \(reference.displayPath)"
            directoryPath.textColor = .systemOrange
            quickSavePreview.stringValue = quickSavePreviewText(
                directoryPath: reference.displayPath,
                options: state.outputOptions
            )
            validateDirectoryButton.isEnabled = true
            revealDirectoryButton.isEnabled = true
            updateStatusIcon(
                directoryStatusIcon,
                symbolName: "exclamationmark.circle.fill",
                color: .systemOrange
            )
        }

        if let error = state.settingsError {
            settingsErrorLabel.stringValue = message(for: error)
            settingsErrorBox.isHidden = false
        } else {
            settingsErrorLabel.stringValue = ""
            settingsErrorBox.isHidden = true
        }
        
        renderPermission(
            snapshot: state.permissionSnapshot,
            isChecking: state.isCheckingPermissions
        )
        renderOutputOptions(state.outputOptions)
        
        currentDisplayRecorder.display(state.currentDisplayShortcut)
    }

    func selectPage(_ page: SettingsPage) {
        selectedPage = page
        showPage(page)
    }

    public override func draw(_ dirtyRect: NSRect) {
        NSColor.systemSettingsContentBackground.setFill()
        dirtyRect.fill()
    }

    private func buildView() {
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel("Snapio settings")

        headerIcon.image = NSImage(
            systemSymbolName: "gearshape",
            accessibilityDescription: "Settings"
        )
        headerIcon.contentTintColor = .secondaryLabelColor
        headerIcon.imageScaling = .scaleProportionallyUpOrDown
        headerIcon.setAccessibilityLabel("Settings")
        headerIcon.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.alignment = .left
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.maximumNumberOfLines = 2
        subtitleLabel.alignment = .left

        recorder.target = self
        recorder.action = #selector(shortcutRecorded)
        recorder.recordingDidChange = { [weak self] isRecording in
            guard let self = self else { return }
            self.delegate?.settingsView(self, didChangeShortcutRecording: isRecording)
        }
        configureStatusIcon(directoryStatusIcon)

        chooseDirectoryButton.target = self
        chooseDirectoryButton.action = #selector(chooseDirectory)
        SnapioVisualStyle.configureButton(
            chooseDirectoryButton,
            symbolName: "folder.badge.plus",
            density: .compact,
            toolTip: "Choose the default folder for quick PNG saves"
        )
        validateDirectoryButton.target = self
        validateDirectoryButton.action = #selector(validateDirectory)
        SnapioVisualStyle.configureButton(
            validateDirectoryButton,
            symbolName: "checkmark.shield",
            emphasis: .quiet,
            density: .compact,
            toolTip: "Check whether Snapio can still write to this folder"
        )
        revealDirectoryButton.target = self
        revealDirectoryButton.action = #selector(revealDirectory)
        SnapioVisualStyle.configureButton(
            revealDirectoryButton,
            symbolName: "arrow.up.forward.app",
            emphasis: .quiet,
            density: .compact,
            toolTip: "Open the quick save folder in Finder"
        )
        grantPermissionButton.target = self
        grantPermissionButton.action = #selector(grantPermission)
        SnapioVisualStyle.configureButton(
            grantPermissionButton,
            symbolName: "checkmark.circle",
            emphasis: .primary,
            density: .compact,
            toolTip: "Continue to Screen Capture permission",
            accessibilityLabel: "Continue to Screen Capture permission"
        )
        grantPermissionButton.image = nil
        grantPermissionButton.imagePosition = .noImage

        saveNotificationCheckbox.target = self
        saveNotificationCheckbox.action = #selector(outputNotificationChanged)
        quickSavePreview.textColor = .secondaryLabelColor
        quickSavePreview.font = .systemFont(ofSize: 11)
        quickSavePreview.lineBreakMode = .byTruncatingMiddle
        quickSavePreview.maximumNumberOfLines = 1
        fileNameTemplateField.target = self
        fileNameTemplateField.action = #selector(fileNameTemplateCommitted)
        fileNameTemplateField.delegate = self
        fileNameTemplateField.placeholderString =
            OutputOptions.defaultFileNameTemplate
        fileNameTemplateField.lineBreakMode = .byTruncatingMiddle
        fileNameTemplateField.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )
        fileNamePreview.textColor = .secondaryLabelColor
        fileNamePreview.lineBreakMode = .byTruncatingMiddle
        fileNamePreview.maximumNumberOfLines = 1
        restoreFileNameTemplateButton.target = self
        restoreFileNameTemplateButton.action = #selector(restoreFileNameTemplate)
        SnapioVisualStyle.configureButton(
            restoreFileNameTemplateButton,
            symbolName: "arrow.counterclockwise",
            emphasis: .quiet,
            density: .compact,
            toolTip: "Restore the default PNG file name template"
        )

        currentDisplayRecorder.target = self
        currentDisplayRecorder.action = #selector(currentDisplayShortcutRecorded)
        currentDisplayRecorder.recordingDidChange = { [weak self] isRecording in
            guard let self = self else { return }
            self.delegate?.settingsView(self, didChangeShortcutRecording: isRecording)
        }

        directoryPath.lineBreakMode = .byTruncatingMiddle
        directoryPath.maximumNumberOfLines = 1
        directoryPath.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )
        settingsErrorLabel.textColor = .systemRed
        settingsErrorLabel.font = .systemFont(ofSize: 11)
        settingsErrorLabel.maximumNumberOfLines = 2

        settingsErrorIcon.image = NSImage(
            systemSymbolName: "exclamationmark.triangle.fill",
            accessibilityDescription: nil
        )
        settingsErrorIcon.contentTintColor = .systemRed
        settingsErrorIcon.setAccessibilityElement(false)
        settingsErrorIcon.translatesAutoresizingMaskIntoConstraints = false
        settingsErrorBox.boxType = .custom
        settingsErrorBox.titlePosition = .noTitle
        settingsErrorBox.fillColor = NSColor.systemRed.withAlphaComponent(0.08)
        settingsErrorBox.borderColor = NSColor.systemRed.withAlphaComponent(0.25)
        settingsErrorBox.borderWidth = 1
        settingsErrorBox.cornerRadius = 8
        settingsErrorBox.isHidden = true
        settingsErrorBox.translatesAutoresizingMaskIntoConstraints = false


        let interactiveShortcutRow = makeGlobalShortcutRow(
            title: "Interactive Screenshot",
            recorder: recorder
        )

        let currentDisplayShortcutRow = makeGlobalShortcutRow(
            title: "Current Display",
            recorder: currentDisplayRecorder
        )

        let shortcutControl = NSStackView(
            views: [interactiveShortcutRow, currentDisplayShortcutRow]
        )
        shortcutControl.orientation = .vertical
        shortcutControl.alignment = .leading
        shortcutControl.spacing = 6

        annotationShortcutStack.orientation = .vertical
        annotationShortcutStack.alignment = .leading
        annotationShortcutStack.spacing = 8
        
        let annotationShortcutRows = AnnotationShortcutAction.allCases.map {
            makeAnnotationShortcutRow(action: $0)
        }
        annotationShortcutRows.forEach{
            annotationShortcutStack.addArrangedSubview($0)
        }
        
        let directoryButtons = NSStackView(
            views: [
                revealDirectoryButton,
                chooseDirectoryButton,
                validateDirectoryButton
            ]
        )
        directoryButtons.orientation = .horizontal
        directoryButtons.alignment = .centerY
        directoryButtons.spacing = 6

        let directoryStatusRow = NSStackView(
            views: [directoryStatusIcon, directoryPath]
        )
        directoryStatusRow.orientation = .horizontal
        directoryStatusRow.alignment = .centerY
        directoryStatusRow.spacing = 4
        directoryStatusRow.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )

        let directoryControl = NSStackView(
            views: [
                directoryStatusRow,
                quickSavePreview,
                saveNotificationCheckbox,
                directoryButtons
            ]
        )
        directoryControl.orientation = .vertical
        directoryControl.alignment = .leading
        directoryControl.spacing = 6
        directoryControl.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )

        let fileNamingControl = makeFileNamingControl()
        let formatControl = makeCenteredReadOnlyValue("PNG")

        let headerText = NSStackView(views: [headerIcon, titleLabel, subtitleLabel])
        headerText.orientation = .vertical
        headerText.alignment = .centerX
        headerText.spacing = 7
        let headerRow = makePageHeader(content: headerText)

        let shortcutSection = makeVerticalSection(
            symbolName: "keyboard",
            accessibilityLabel: "Global shortcut settings",
            title: "Global Shortcuts",
            detail: "Start screenshots while Snapio is in the background.",
            control: shortcutControl
        )

        let annotationShortcutSection = makeVerticalSection(
            symbolName: "command",
            accessibilityLabel: "Annotation shortcut settings",
            title: "Annotation Shortcuts",
            detail: "Customize shortcuts used while editing annotations.",
            control: annotationShortcutStack
        )
        let directorySection = makeOutputSection(
            symbolName: "folder",
            accessibilityLabel: "Default folder setting",
            title: "Quick Save",
            detail: "Save PNG files to the selected folder without replacing existing files.",
            control: directoryControl,
            centersControl: true
        )
        let fileNamingSection = makeOutputSection(
            symbolName: "textformat",
            accessibilityLabel: "File naming setting",
            title: "File Naming",
            detail: "Use date tokens wrapped in dollar signs, such as $yyyy-MM-dd_HH-mm-ss$.",
            control: fileNamingControl,
            centersControl: true
        )
        let formatSection = makeOutputSection(
            symbolName: "photo",
            accessibilityLabel: "Output format setting",
            title: "Format",
            detail: "Transparent PNG output is used for copy and save.",
            control: formatControl
        )
        let appInfoSection = makeSection(
            symbolName: "info.circle",
            accessibilityLabel: "Application information",
            title: "Application",
            detail: "Snapio runs as a local macOS screenshot utility.",
            control: makeReadOnlyValue(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
        )
        let privacySection = makeSection(
            symbolName: "lock.shield",
            accessibilityLabel: "Screen Capture permission",
            title: "Screen Capture",
            detail: "Required before Snapio can read screen pixels for screenshots.",
            control: makePermissionControl()
        )
        headerRowView = headerRow
        appInfoSectionView = appInfoSection
        privacySectionView = privacySection
        shortcutSectionView = shortcutSection
        annotationShortcutSectionView = annotationShortcutSection
        directorySectionView = directorySection
        fileNamingSectionView = fileNamingSection
        formatSectionView = formatSection

        let errorRow = NSStackView(
            views: [settingsErrorIcon, settingsErrorLabel]
        )
        errorRow.orientation = .horizontal
        errorRow.alignment = .centerY
        errorRow.spacing = 8
        errorRow.translatesAutoresizingMaskIntoConstraints = false
        settingsErrorBox.addSubview(errorRow)

        generalPageView = makeDetailPage(
            headerRow: makePageHeader(for: .general),
            sections: [
                makeGroupedList(sections: [
                    [appInfoSection, privacySection]
                ])
            ]
        )
        shortcutsPageView = makeDetailPage(
            headerRow: makePageHeader(for: .shortcuts),
            sections: [
                makeGroupedList(sections: [
                    [shortcutSection],
                    [annotationShortcutSection]
                ])
            ]
        )
        outputPageView = makeDetailPage(
            headerRow: makePageHeader(for: .output),
            sections: [
                makeGroupedList(sections: [
                    [directorySection],
                    [fileNamingSection],
                    [formatSection]
                ])
            ]
        )

        detailContainer.translatesAutoresizingMaskIntoConstraints = false
        detailContainer.wantsLayer = true
        detailContainer.layer?.backgroundColor = NSColor.systemSettingsContentBackground.cgColor
        detailContainer.addSubview(settingsErrorBox)

        addSubview(detailContainer)

        NSLayoutConstraint.activate([
            detailContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            detailContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            detailContainer.topAnchor.constraint(equalTo: topAnchor),
            detailContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            widthAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumSize.width),
            heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumSize.height)
        ])

        NSLayoutConstraint.activate([
            errorRow.leadingAnchor.constraint(
                equalTo: settingsErrorBox.leadingAnchor,
                constant: 12
            ),
            errorRow.trailingAnchor.constraint(
                equalTo: settingsErrorBox.trailingAnchor,
                constant: -12
            ),
            errorRow.topAnchor.constraint(
                equalTo: settingsErrorBox.topAnchor,
                constant: 9
            ),
            errorRow.bottomAnchor.constraint(
                equalTo: settingsErrorBox.bottomAnchor,
                constant: -9
            ),
            settingsErrorIcon.widthAnchor.constraint(equalToConstant: 16),
            settingsErrorIcon.heightAnchor.constraint(equalToConstant: 16),
            settingsErrorBox.leadingAnchor.constraint(
                equalTo: detailContainer.leadingAnchor,
                constant: 24
            ),
            settingsErrorBox.trailingAnchor.constraint(
                equalTo: detailContainer.trailingAnchor,
                constant: -24
            ),
            settingsErrorBox.bottomAnchor.constraint(
                equalTo: detailContainer.bottomAnchor,
                constant: -20
            )
        ])

        showPage(.general)
    }

    private func makeGroupedList(sections: [[NSView]]) -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .width
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        for rows in sections {
            let group = RoundedBackgroundView()
            group.fillColor = .systemSettingsGroupBackground
            group.cornerRadius = 12
            group.translatesAutoresizingMaskIntoConstraints = false
            group.setContentHuggingPriority(.required, for: .vertical)

            let groupStack = NSStackView()
            groupStack.orientation = .vertical
            groupStack.alignment = .width
            groupStack.spacing = 0
            groupStack.translatesAutoresizingMaskIntoConstraints = false
            group.addSubview(groupStack)

            for (index, row) in rows.enumerated() {
                groupStack.addArrangedSubview(row)
                if index < rows.count - 1 {
                    groupStack.addArrangedSubview(makeDivider())
                }
            }

            NSLayoutConstraint.activate([
                groupStack.leadingAnchor.constraint(equalTo: group.leadingAnchor),
                groupStack.trailingAnchor.constraint(equalTo: group.trailingAnchor),
                groupStack.topAnchor.constraint(equalTo: group.topAnchor),
                groupStack.bottomAnchor.constraint(equalTo: group.bottomAnchor)
            ])

            stack.addArrangedSubview(group)
        }

        return stack
    }

    private func makeSettingsRow(
        symbolName: String,
        accessibilityLabel: String,
        content: NSView,
        showsChevron: Bool = false
    ) -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.setContentHuggingPriority(.required, for: .vertical)

        let iconBackground = RoundedBackgroundView()
        iconBackground.fillColor = .tertiaryLabelColor.withAlphaComponent(0.35)
        iconBackground.cornerRadius = 5
        iconBackground.translatesAutoresizingMaskIntoConstraints = false

        let icon = NSImageView()
        icon.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: accessibilityLabel
        )
        icon.contentTintColor = .white
        icon.imageScaling = .scaleProportionallyDown
        icon.setAccessibilityLabel(accessibilityLabel)
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(icon)

        let chevron = NSImageView()
        chevron.image = NSImage(
            systemSymbolName: "chevron.right",
            accessibilityDescription: nil
        )
        chevron.contentTintColor = .tertiaryLabelColor
        chevron.imageScaling = .scaleProportionallyDown
        chevron.isHidden = !showsChevron
        chevron.translatesAutoresizingMaskIntoConstraints = false

        content.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(iconBackground)
        row.addSubview(content)
        row.addSubview(chevron)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),
            iconBackground.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            iconBackground.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconBackground.widthAnchor.constraint(equalToConstant: 24),
            iconBackground.heightAnchor.constraint(equalToConstant: 24),
            icon.leadingAnchor.constraint(equalTo: iconBackground.leadingAnchor, constant: 4),
            icon.trailingAnchor.constraint(equalTo: iconBackground.trailingAnchor, constant: -4),
            icon.topAnchor.constraint(equalTo: iconBackground.topAnchor, constant: 4),
            icon.bottomAnchor.constraint(equalTo: iconBackground.bottomAnchor, constant: -4),
            content.leadingAnchor.constraint(equalTo: iconBackground.trailingAnchor, constant: 14),
            content.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -10),
            content.topAnchor.constraint(equalTo: row.topAnchor, constant: 10),
            content.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -10),
            chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -12),
            chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 10),
            chevron.heightAnchor.constraint(equalToConstant: 14)
        ])

        return row
    }

    private func makeDivider() -> NSView {
        let divider = NSBox()
        divider.boxType = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])
        return divider
    }

    private func makeAnnotationShortcutRow(
        action: AnnotationShortcutAction
    ) -> NSView {
        let titleLabel = NSTextField(labelWithString: title(for: action))
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.alignment = .right
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let recorder = HotKeyRecorderControl(frame: .zero)
        recorder.validationMode = .local
        recorder.target = self
        recorder.action = #selector(annotationShortcutRecorded(_:))
        recorder.recordingDidChange = { [weak self] isRecording in
            guard let self = self else { return }
            self.delegate?.settingsView(self, didChangeShortcutRecording: isRecording)
        }

        annotationShortcutRecorders[recorder] = action

        let row = NSStackView(views: [titleLabel, recorder])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(equalToConstant: 150),
            recorder.widthAnchor.constraint(equalToConstant: 170),
            row.widthAnchor.constraint(greaterThanOrEqualToConstant: 340)
        ])

        return row
    }
    
    private func makeVerticalSection(
        symbolName: String,
        accessibilityLabel: String,
        title: String,
        detail: String,
        control: NSView
    ) -> NSView {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)

        let detailLabel = NSTextField(wrappingLabelWithString: detail)
        detailLabel.font = .systemFont(ofSize: 11)
        detailLabel.textColor = .secondaryLabelColor

        let textStack = NSStackView(views: [titleLabel, detailLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 3

        let stack = NSStackView(views: [textStack, control])
        stack.orientation = .vertical
        stack.alignment = .width
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        return makeSettingsRow(
            symbolName: symbolName,
            accessibilityLabel: accessibilityLabel,
            content: stack
        )
    }

    private func makePageHeader(content: NSView) -> NSBox {
        let box = NSBox()
        box.boxType = .custom
        box.titlePosition = .noTitle
        box.fillColor = .clear
        box.borderColor = .clear
        box.borderWidth = 0
        box.cornerRadius = 0

        content.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(content)

        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(
                equalTo: box.leadingAnchor,
                constant: 0
            ),
            content.trailingAnchor.constraint(
                equalTo: box.trailingAnchor,
                constant: 0
            ),
            content.topAnchor.constraint(
                equalTo: box.topAnchor,
                constant: 0
            ),
            content.bottomAnchor.constraint(
                equalTo: box.bottomAnchor,
                constant: -4
            )
        ])

        return box
    }
    
    private func makePageHeader(for page: SettingsPage) -> NSView {
        let container = RoundedBackgroundView()
        container.fillColor = .clear
        container.cornerRadius = 0
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconBackground = RoundedBackgroundView()
        iconBackground.fillColor = .tertiaryLabelColor.withAlphaComponent(0.35)
        iconBackground.cornerRadius = 13
        iconBackground.translatesAutoresizingMaskIntoConstraints = false

        let icon = NSImageView()
        icon.image = NSImage(
            systemSymbolName: page.symbolName,
            accessibilityDescription: page.title
        )
        icon.contentTintColor = .white
        icon.imageScaling = .scaleProportionallyDown
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(icon)

        let title = NSTextField(labelWithString: page.title)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = .systemFont(ofSize: 25, weight: .bold)
        title.alignment = .center

        let subtitle = NSTextField(wrappingLabelWithString: subtitle(for: page))
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = .secondaryLabelColor
        subtitle.alignment = .center
        subtitle.maximumNumberOfLines = 2

        container.addSubview(iconBackground)
        container.addSubview(title)
        container.addSubview(subtitle)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 116),
            iconBackground.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            iconBackground.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconBackground.widthAnchor.constraint(equalToConstant: 54),
            iconBackground.heightAnchor.constraint(equalToConstant: 54),
            icon.leadingAnchor.constraint(equalTo: iconBackground.leadingAnchor, constant: 8),
            icon.trailingAnchor.constraint(equalTo: iconBackground.trailingAnchor, constant: -8),
            icon.topAnchor.constraint(equalTo: iconBackground.topAnchor, constant: 8),
            icon.bottomAnchor.constraint(equalTo: iconBackground.bottomAnchor, constant: -8),
            title.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            title.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            title.topAnchor.constraint(equalTo: iconBackground.bottomAnchor, constant: 8),
            title.heightAnchor.constraint(equalToConstant: 30),
            subtitle.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 28),
            subtitle.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -28),
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 3),
            subtitle.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -8)
        ])

        return container
    }
    
    private func subtitle(for page: SettingsPage) -> String {
        switch page {
        case .general:
            return "Manage Snapio capture permissions and application behavior."
        case .shortcuts:
            return "Configure keyboard shortcuts used for capture and annotation."
        case .output:
            return "Choose where Snapio saves PNG screenshots."
        }
    }
    
    private func makeSection(
        symbolName: String,
        accessibilityLabel: String,
        title: String,
        detail: String,
        control: NSView
    ) -> NSView {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        let detailLabel = NSTextField(wrappingLabelWithString: detail)
        detailLabel.font = .systemFont(ofSize: 11)
        detailLabel.textColor = .secondaryLabelColor
        let textStack = NSStackView(views: [titleLabel, detailLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 3

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let row = NSStackView(views: [textStack, spacer, control])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 245)
        ])

        return makeSettingsRow(
            symbolName: symbolName,
            accessibilityLabel: accessibilityLabel,
            content: row,
            showsChevron: true
        )
    }
    
    private func makeReadOnlyValue(_ value: String) -> NSTextField {
        let label = NSTextField(labelWithString: value)
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabelColor
        label.alignment = .right
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }

    private func makeCenteredReadOnlyValue(_ value: String) -> NSTextField {
        let label = makeReadOnlyValue(value)
        label.alignment = .center
        return label
    }

    private func quickSavePreviewText(
        directoryPath: String,
        options: OutputOptions
    ) -> String {
        "Preview: \(options.suggestedFileName())"
    }

    private func makeOutputSection(
        symbolName: String,
        accessibilityLabel: String,
        title: String,
        detail: String,
        control: NSView,
        centersControl: Bool = false
    ) -> NSView {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        let detailLabel = NSTextField(wrappingLabelWithString: detail)
        detailLabel.font = .systemFont(ofSize: 11)
        detailLabel.textColor = .secondaryLabelColor

        let textStack = NSStackView(views: [titleLabel, detailLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 3
        textStack.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )

        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        textStack.translatesAutoresizingMaskIntoConstraints = false
        control.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textStack)
        contentView.addSubview(control)
        contentView.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )

        var constraints = [
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            control.topAnchor.constraint(equalTo: textStack.bottomAnchor, constant: 10),
            control.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]

        if centersControl {
            constraints.append(
                control.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
            )
            constraints.append(
                control.trailingAnchor.constraint(
                    lessThanOrEqualTo: contentView.trailingAnchor
                )
            )
        } else {
            constraints.append(
                control.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
            )
            constraints.append(
                control.trailingAnchor.constraint(
                    lessThanOrEqualTo: contentView.trailingAnchor
                )
            )
        }

        NSLayoutConstraint.activate(constraints)

        return makeSettingsRow(
            symbolName: symbolName,
            accessibilityLabel: accessibilityLabel,
            content: contentView
        )
    }

    private func makeFileNamingControl() -> NSView {
        let templateLabel = makeOutputFieldLabel("Template")
        let previewLabel = makeOutputFieldLabel("Preview")
        let templateRow = NSStackView(
            views: [templateLabel, fileNameTemplateField]
        )
        templateRow.orientation = .horizontal
        templateRow.alignment = .centerY
        templateRow.spacing = 8

        let previewRow = NSStackView(
            views: [previewLabel, fileNamePreview]
        )
        previewRow.orientation = .horizontal
        previewRow.alignment = .centerY
        previewRow.spacing = 8

        let actionRow = NSStackView(views: [restoreFileNameTemplateButton])
        actionRow.orientation = .horizontal
        actionRow.alignment = .centerY

        let stack = NSStackView(views: [templateRow, previewRow, actionRow])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 7
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            templateLabel.widthAnchor.constraint(equalToConstant: 64),
            previewLabel.widthAnchor.constraint(equalToConstant: 64),
            fileNameTemplateField.widthAnchor.constraint(
                equalToConstant: 300
            ),
            fileNamePreview.widthAnchor.constraint(
                equalTo: fileNameTemplateField.widthAnchor
            )
        ])

        return stack
    }

    private func makeOutputFieldLabel(_ value: String) -> NSTextField {
        let label = NSTextField(labelWithString: value)
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        label.alignment = .right
        return label
    }

    private func renderOutputOptions(_ options: OutputOptions) {
        renderedOutputOptions = options
        if fileNameTemplateField.stringValue != options.fileNameTemplate {
            fileNameTemplateField.stringValue = options.fileNameTemplate
        }
        saveNotificationCheckbox.state = options.showsSaveNotification
            ? .on
            : .off
        fileNamePreview.stringValue = options.suggestedFileName()
    }

    private func configureStatusIcon(_ imageView: NSImageView) {
        imageView.imageScaling = .scaleProportionallyDown
        imageView.setAccessibilityElement(false)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 14),
            imageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }

    private func updateStatusIcon(
        _ imageView: NSImageView,
        symbolName: String,
        color: NSColor
    ) {
        imageView.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: nil
        )
        imageView.contentTintColor = color
    }
    
    private func makePermissionControl() -> NSView {
        permissionProgressIndicator.style = .spinning
        permissionProgressIndicator.controlSize = .small
        permissionProgressIndicator.isDisplayedWhenStopped = false

        permissionStatusIcon.imageScaling = .scaleProportionallyDown
        permissionStatusIcon.translatesAutoresizingMaskIntoConstraints = false

        let statusRow = NSStackView(
            views: [permissionStatusIcon, permissionStatus]
        )
        statusRow.orientation = .horizontal
        statusRow.alignment = .centerY
        statusRow.spacing = 4

        let stack = NSStackView(
            views: [
                statusRow,
                grantPermissionButton,
                permissionProgressIndicator
            ]
        )
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 8

        NSLayoutConstraint.activate([
            permissionStatusIcon.widthAnchor.constraint(equalToConstant: 14),
            permissionStatusIcon.heightAnchor.constraint(equalToConstant: 14)
        ])

        return stack
    }
    
    private func renderPermission(
        snapshot: PermissionSnapshot,
        isChecking: Bool
    ) {
        if isChecking && snapshot.screenCapture == .unknown {
            permissionStatus.stringValue = "Checking…"
            permissionStatus.textColor = .secondaryLabelColor
            updateStatusIcon(
                permissionStatusIcon,
                symbolName: "ellipsis.circle",
                color: .secondaryLabelColor
            )
            grantPermissionButton.isHidden = true
            grantPermissionButton.isEnabled = false
            permissionProgressIndicator.startAnimation(nil)
            return
        }

        permissionProgressIndicator.stopAnimation(nil)

        switch snapshot.screenCapture {
        case .unknown:
            permissionStatus.stringValue = "Not Checked"
            permissionStatus.textColor = .secondaryLabelColor
            updateStatusIcon(
                permissionStatusIcon,
                symbolName: "questionmark.circle",
                color: .secondaryLabelColor
            )
            grantPermissionButton.isHidden = false
            grantPermissionButton.isEnabled = !isChecking

        case .missing:
            permissionStatus.stringValue = "Required"
            permissionStatus.textColor = .systemOrange
            updateStatusIcon(
                permissionStatusIcon,
                symbolName: "exclamationmark.circle.fill",
                color: .systemOrange
            )
            grantPermissionButton.isHidden = false
            grantPermissionButton.isEnabled = true

        case .granted:
            permissionStatus.stringValue = "Enabled"
            permissionStatus.textColor = .systemGreen
            updateStatusIcon(
                permissionStatusIcon,
                symbolName: "checkmark.circle.fill",
                color: .systemGreen
            )
            grantPermissionButton.isHidden = true
            grantPermissionButton.isEnabled = false
        }
    }
    
    private func makeGlobalShortcutRow(
        title: String,
        recorder: HotKeyRecorderControl
    ) -> NSView {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.alignment = .right
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let row = NSStackView(views: [titleLabel, recorder])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(equalToConstant: 150),
            recorder.widthAnchor.constraint(equalToConstant: 170),
            row.widthAnchor.constraint(greaterThanOrEqualToConstant: 340)
        ])

        return row
    }
    
    private func makeDetailPage(
        headerRow: NSView,
        sections: [NSView]
    ) -> NSView {
        let documentView = FlippedDocumentView()
        let scrollView = NSScrollView()
        let stack = NSStackView(views: [headerRow] + sections)

        stack.orientation = .vertical
        stack.alignment = .width
        stack.distribution = .fill
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        ([headerRow] + sections).forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }

        documentView.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(stack)

        scrollView.documentView = documentView
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        NSLayoutConstraint.activate([
            documentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
            documentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.contentView.heightAnchor),

            stack.leadingAnchor.constraint(equalTo: documentView.leadingAnchor, constant: 34),
            stack.trailingAnchor.constraint(equalTo: documentView.trailingAnchor, constant: -34),
            stack.topAnchor.constraint(equalTo: documentView.topAnchor, constant: 70),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: documentView.bottomAnchor, constant: -28)
        ])

        return scrollView
    }
    
    private func showPage(_ page: SettingsPage) {
        let nextView: NSView?

        switch page {
        case .general:
            nextView = generalPageView
        case .shortcuts:
            nextView = shortcutsPageView
        case .output:
            nextView = outputPageView
        }

        guard let nextView else { return }

        currentDetailView?.removeFromSuperview()
        currentDetailView = nextView

        nextView.translatesAutoresizingMaskIntoConstraints = false
        detailContainer.addSubview(
            nextView,
            positioned: .below,
            relativeTo: settingsErrorBox
        )

        NSLayoutConstraint.activate([
            nextView.leadingAnchor.constraint(equalTo: detailContainer.leadingAnchor),
            nextView.trailingAnchor.constraint(equalTo: detailContainer.trailingAnchor),
            nextView.topAnchor.constraint(equalTo: detailContainer.topAnchor),
            nextView.bottomAnchor.constraint(equalTo: detailContainer.bottomAnchor)
        ])
    }
    
    @objc private func shortcutRecorded() {
        guard let shortcut = recorder.recordedShortcut else { return }
        delegate?.settingsView(self, didRecord: shortcut)
    }
    
    @objc private func annotationShortcutRecorded(_ sender: HotKeyRecorderControl) {
        guard let action = annotationShortcutRecorders[sender],
              let shortcut = sender.recordedShortcut else {
            return
        }

        delegate?.settingsView(
            self,
            didRecordAnnotationShortcut: shortcut,
            for: action
        )
    }

    @objc private func chooseDirectory() {
        delegate?.settingsViewDidRequestDirectory(self)
    }

    @objc private func validateDirectory() {
        delegate?.settingsViewDidRequestDirectoryValidation(self)
    }

    @objc private func revealDirectory() {
        delegate?.settingsViewDidRequestDirectoryReveal(self)
    }
    
    @objc private func grantPermission() {
        delegate?.settingsViewDidRequestPermissionGrant(self)
    }

    @objc private func outputNotificationChanged() {
        var updated = renderedOutputOptions
        updated.showsSaveNotification = saveNotificationCheckbox.state == .on
        renderedOutputOptions = updated
        delegate?.settingsView(self, didChangeOutputOptions: updated)
    }

    @objc private func fileNameTemplateCommitted() {
        var updated = renderedOutputOptions
        updated.fileNameTemplate = fileNameTemplateField.stringValue
        renderedOutputOptions = updated
        fileNamePreview.stringValue = updated.suggestedFileName()
        delegate?.settingsView(self, didChangeOutputOptions: updated)
    }

    public func controlTextDidChange(_ notification: Notification) {
        guard notification.object as? NSTextField == fileNameTemplateField else {
            return
        }

        fileNamePreview.stringValue = OutputOptions.previewFileName(
            template: fileNameTemplateField.stringValue
        )
    }

    @objc private func restoreFileNameTemplate() {
        var updated = renderedOutputOptions
        updated.fileNameTemplate = OutputOptions.defaultFileNameTemplate
        renderedOutputOptions = updated
        fileNameTemplateField.stringValue = updated.fileNameTemplate
        fileNamePreview.stringValue = updated.suggestedFileName()
        delegate?.settingsView(self, didChangeOutputOptions: updated)
    }
    
    @objc private func currentDisplayShortcutRecorded() {
        guard let shortcut = currentDisplayRecorder.recordedShortcut else { return }
        delegate?.settingsView(
            self,
            didRecordCurrentDisplayShortcut: shortcut
        )
    }

    private func message(for error: ShortcutError) -> String {
        switch error {
        case .invalidCombination:
            return "Use Command, Option, or Control with another key."
        case .alreadyRegistered:
            return "That shortcut is already in use. The previous shortcut remains active."
        case .systemRejected:
            return "macOS rejected the shortcut. The previous shortcut remains active."
        case .persistenceFailed:
            return "The shortcut could not be saved. The previous shortcut remains active."
        }
    }

    private func message(for error: SettingsError) -> String {
        switch error {
        case .loadFailed:
            return "Settings could not be loaded. Existing defaults are being used."
        case .saveFailed:
            return "Settings could not be saved. The previous values remain active."
        case .invalidDirectoryGrant:
            return "The selected folder could not be authorized. Choose it again."
        }
    }
    
    private func title(for action: AnnotationShortcutAction) -> String {
        switch action {
        case .arrowTool:
            return "Arrow Tool"
        case .rectangleTool:
            return "Rectangle Tool"
        case .textTool:
            return "Text Tool"
        case .brushTool:
            return "Brush Tool"
        case .highlightTool:
            return "Highlight Tool"
        case .mosaicTool:
            return "Mosaic Tool"
        case .copy:
            return "Copy"
        case .save:
            return "Save"
        case .pin:
            return "Pin"
        case .undo:
            return "Undo"
        case .redo:
            return "Redo"
        case .delete:
            return "Delete"
        case .cancel:
            return "Cancel"
        case .confirm:
            return "Confirm"
        }
    }
}
