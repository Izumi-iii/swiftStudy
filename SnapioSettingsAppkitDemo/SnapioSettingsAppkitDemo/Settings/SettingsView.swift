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

private enum SettingsPage: Int, CaseIterable, Hashable {
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

private final class FlippedDocumentView: NSView {
    override var isFlipped: Bool { true }
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
    NSTextFieldDelegate,
    NSTableViewDataSource,
    NSTableViewDelegate {
    private static let minimumSize = NSSize(width: 800, height: 520)

    public weak var delegate: SettingsViewDelegate?
    public override var isOpaque: Bool { false }
    
    private var selectedPage: SettingsPage = .general
    
    private let splitView = NSSplitView()
    private let sidebarColumn = NSView()
    private let sidebarContainer = NSVisualEffectView()
    private let sidebarScrollView = NSScrollView()
    private let sidebarTableView = NSTableView()
    
    private let detailContainer = NSView()
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

    public override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
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
        headerIcon.contentTintColor = .controlAccentColor
        headerIcon.imageScaling = .scaleProportionallyUpOrDown
        headerIcon.setAccessibilityLabel("Settings")
        headerIcon.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.alignment = .center
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.maximumNumberOfLines = 2
        subtitleLabel.alignment = .center

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
        directoryControl.alignment = .centerX
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

        configureSidebar()

        generalPageView = makeDetailPage(
            headerRow: makePageHeader(for: .general),
            sections: [appInfoSection, privacySection]
        )
        shortcutsPageView = makeDetailPage(
            headerRow: makePageHeader(for: .shortcuts),
            sections: [shortcutSection, annotationShortcutSection]
        )
        outputPageView = makeDetailPage(
            headerRow: makePageHeader(for: .output),
            sections: [directorySection, fileNamingSection, formatSection]
        )

        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.translatesAutoresizingMaskIntoConstraints = false

        sidebarColumn.translatesAutoresizingMaskIntoConstraints = false
        detailContainer.translatesAutoresizingMaskIntoConstraints = false
        detailContainer.addSubview(settingsErrorBox)

        splitView.addArrangedSubview(sidebarColumn)
        splitView.addArrangedSubview(detailContainer)
        addSubview(splitView)

        NSLayoutConstraint.activate([
            splitView.leadingAnchor.constraint(equalTo: leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: trailingAnchor),
            splitView.topAnchor.constraint(equalTo: topAnchor),
            splitView.bottomAnchor.constraint(equalTo: bottomAnchor),

            sidebarColumn.widthAnchor.constraint(equalToConstant: 235),

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
    
    private func configureSidebar() {
        sidebarContainer.material = .sidebar
        sidebarContainer.blendingMode = .behindWindow
        sidebarContainer.state = .active
        sidebarContainer.wantsLayer = true
        sidebarContainer.layer?.cornerRadius = 12
        sidebarContainer.layer?.masksToBounds = true
        sidebarContainer.translatesAutoresizingMaskIntoConstraints = false

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Page"))
        sidebarTableView.addTableColumn(column)
        column.resizingMask = .autoresizingMask
        sidebarTableView.headerView = nil
        sidebarTableView.style = .sourceList
        sidebarTableView.rowHeight = 28
        sidebarTableView.selectionHighlightStyle = .sourceList
        sidebarTableView.dataSource = self
        sidebarTableView.delegate = self
        sidebarTableView.backgroundColor = .clear
        sidebarTableView.intercellSpacing = NSSize(width: 0, height: 2)
        sidebarTableView.translatesAutoresizingMaskIntoConstraints = false

        sidebarScrollView.documentView = sidebarTableView
        sidebarScrollView.hasVerticalScroller = false
        sidebarScrollView.hasHorizontalScroller = false
        sidebarScrollView.drawsBackground = false
        sidebarScrollView.borderType = .noBorder
        sidebarScrollView.translatesAutoresizingMaskIntoConstraints = false

        sidebarColumn.addSubview(sidebarContainer)
        sidebarContainer.addSubview(sidebarScrollView)
        
        NSLayoutConstraint.activate([
            sidebarContainer.leadingAnchor.constraint(equalTo: sidebarColumn.leadingAnchor, constant: 28),
            sidebarContainer.trailingAnchor.constraint(equalTo: sidebarColumn.trailingAnchor, constant: -12),
            sidebarContainer.topAnchor.constraint(equalTo: sidebarColumn.topAnchor, constant: 42),
            sidebarContainer.bottomAnchor.constraint(equalTo: sidebarColumn.bottomAnchor, constant: -8),

            sidebarScrollView.leadingAnchor.constraint(equalTo: sidebarContainer.leadingAnchor, constant: 10),
            sidebarScrollView.trailingAnchor.constraint(equalTo: sidebarContainer.trailingAnchor, constant: -10),
            sidebarScrollView.topAnchor.constraint(equalTo: sidebarContainer.topAnchor, constant: 54),
            sidebarScrollView.bottomAnchor.constraint(equalTo: sidebarContainer.bottomAnchor, constant: -8)
        ])

        sidebarTableView.reloadData()
        sidebarTableView.selectRowIndexes(
            IndexSet(integer: selectedPage.rawValue),
            byExtendingSelection: false
        )
    }

    public func tableView(
        _ tableView: NSTableView,
        heightOfRow row: Int
    ) -> CGFloat {
        28
    }
    
    public func numberOfRows(in tableView: NSTableView) -> Int {
        SettingsPage.allCases.count
    }

    public func tableView(
        _ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?,
        row: Int
    ) -> NSView? {
        guard row < SettingsPage.allCases.count else { return nil }

        let page = SettingsPage.allCases[row]
        let cell = NSTableCellView()
        let label = NSTextField(labelWithString: page.title)

        cell.identifier = NSUserInterfaceItemIdentifier(page.title)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13)

        cell.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -10),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])

        return cell
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        let row = sidebarTableView.selectedRow
        guard row >= 0, row < SettingsPage.allCases.count else { return }

        selectedPage = SettingsPage.allCases[row]
        showPage(selectedPage)
    }

    private func updateHeader() {
        titleLabel.stringValue = selectedPage.title
        headerIcon.image = NSImage(
            systemSymbolName: selectedPage.symbolName,
            accessibilityDescription: selectedPage.title
        )
        switch selectedPage {
        case .general:
            subtitleLabel.stringValue = "Manage Snapio capture permissions and application behavior."
        case .shortcuts:
            subtitleLabel.stringValue = "Configure keyboard shortcuts used for capture and annotation."
        case .output:
            subtitleLabel.stringValue = "Choose where Snapio saves PNG screenshots."
        }
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
    ) -> NSBox {
        let box = NSBox()
        box.boxType = .custom
        box.titlePosition = .noTitle
        box.fillColor = .controlBackgroundColor
        box.borderColor = .separatorColor
        box.borderWidth = 1
        box.cornerRadius = 10

        let icon = NSImageView()
        icon.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: accessibilityLabel
        )
        icon.contentTintColor = .controlAccentColor
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.setAccessibilityLabel(accessibilityLabel)
        icon.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)

        let detailLabel = NSTextField(wrappingLabelWithString: detail)
        detailLabel.font = .systemFont(ofSize: 11)
        detailLabel.textColor = .secondaryLabelColor

        let textStack = NSStackView(views: [titleLabel, detailLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 3

        let header = NSStackView(views: [icon, textStack])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 12

        let stack = NSStackView(views: [header, control])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: box.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -12),
            icon.widthAnchor.constraint(equalToConstant: 30),
            icon.heightAnchor.constraint(equalToConstant: 30),
            control.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])

        return box
    }

    private func makePageHeader(content: NSView) -> NSBox {
        let box = NSBox()
        box.boxType = .custom
        box.titlePosition = .noTitle
        box.fillColor = .controlBackgroundColor
        box.borderColor = .clear
        box.borderWidth = 0
        box.cornerRadius = 12

        content.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(content)

        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(
                equalTo: box.leadingAnchor,
                constant: 24
            ),
            content.trailingAnchor.constraint(
                equalTo: box.trailingAnchor,
                constant: -24
            ),
            content.topAnchor.constraint(
                equalTo: box.topAnchor,
                constant: 24
            ),
            content.bottomAnchor.constraint(
                equalTo: box.bottomAnchor,
                constant: -20
            )
        ])

        return box
    }
    
    private func makePageHeader(for page: SettingsPage) -> NSView {
        let icon = NSImageView()
        icon.image = NSImage(
            systemSymbolName: page.symbolName,
            accessibilityDescription: page.title
        )
        icon.contentTintColor = .controlAccentColor
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.translatesAutoresizingMaskIntoConstraints = false

        let title = NSTextField(labelWithString: page.title)
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        title.alignment = .center

        let subtitle = NSTextField(wrappingLabelWithString: subtitle(for: page))
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = .secondaryLabelColor
        subtitle.alignment = .center
        subtitle.maximumNumberOfLines = 2

        let stack = NSStackView(views: [icon, title, subtitle])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 7

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 50),
            icon.heightAnchor.constraint(equalToConstant: 50)
        ])

        return makePageHeader(content: stack)
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
    ) -> NSBox {
        let box = NSBox()
        box.boxType = .custom
        box.titlePosition = .noTitle
        box.fillColor = .controlBackgroundColor
        box.borderColor = .separatorColor
        box.borderWidth = 1
        box.cornerRadius = 10

        let icon = NSImageView()
        icon.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: accessibilityLabel
        )
        icon.contentTintColor = .controlAccentColor
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.setAccessibilityLabel(accessibilityLabel)
        icon.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        let detailLabel = NSTextField(wrappingLabelWithString: detail)
        detailLabel.font = .systemFont(ofSize: 11)
        detailLabel.textColor = .secondaryLabelColor
        let textStack = NSStackView(views: [titleLabel, detailLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 3

        let leftStack = NSStackView(views: [icon, textStack])
        leftStack.orientation = .horizontal
        leftStack.alignment = .centerY
        leftStack.spacing = 12

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let row = NSStackView(views: [leftStack, spacer, control])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -14),
            row.topAnchor.constraint(equalTo: box.topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -12),
            icon.widthAnchor.constraint(equalToConstant: 30),
            icon.heightAnchor.constraint(equalToConstant: 30),
            textStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 245)
        ])
        return box
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
    ) -> NSBox {
        let box = NSBox()
        box.boxType = .custom
        box.titlePosition = .noTitle
        box.fillColor = .controlBackgroundColor
        box.borderColor = .separatorColor
        box.borderWidth = 1
        box.cornerRadius = 10

        let icon = NSImageView()
        icon.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: accessibilityLabel
        )
        icon.contentTintColor = .controlAccentColor
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.setAccessibilityLabel(accessibilityLabel)
        icon.translatesAutoresizingMaskIntoConstraints = false

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

        let row = NSStackView(views: [icon, contentView])
        row.orientation = .horizontal
        row.alignment = .top
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(row)

        var constraints = [
            row.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -14),
            row.topAnchor.constraint(equalTo: box.topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -12),
            icon.widthAnchor.constraint(equalToConstant: 30),
            icon.heightAnchor.constraint(equalToConstant: 30),
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            control.topAnchor.constraint(equalTo: textStack.bottomAnchor, constant: 10),
            control.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]

        if centersControl {
            constraints.append(
                control.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
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

        return box
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
        stack.alignment = .centerX
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

        documentView.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(stack)

        scrollView.documentView = documentView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        NSLayoutConstraint.activate([
            documentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
            documentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.contentView.heightAnchor),

            stack.leadingAnchor.constraint(equalTo: documentView.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: documentView.trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: documentView.topAnchor, constant: 52),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: documentView.bottomAnchor, constant: -24)
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
