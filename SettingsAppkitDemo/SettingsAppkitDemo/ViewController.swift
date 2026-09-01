import Cocoa

final class ViewController: NSViewController {
    private enum SidebarRow {
        case account
        case update
        case item(SettingsItem)

        var title: String {
            switch self {
            case .account:
                "王杰"
            case .update:
                "今晚安装软件更新"
            case .item(let item):
                item.title
            }
        }

        var isSelectable: Bool {
            if case .item = self {
                return true
            }

            return false
        }
    }

    fileprivate struct SettingsItem {
        let title: String
        let symbolName: String
        let color: NSColor
    }

    private let itemRows: [SettingsItem] = [
        SettingsItem(title: "Wi-Fi", symbolName: "wifi", color: .systemBlue),
        SettingsItem(title: "蓝牙", symbolName: "bolt.horizontal.fill", color: .systemBlue),
        SettingsItem(title: "网络", symbolName: "network", color: .systemBlue),
        SettingsItem(title: "能耗", symbolName: "bolt.fill", color: .systemGreen),
        SettingsItem(title: "通用", symbolName: "gearshape.fill", color: .systemGray),
        SettingsItem(title: "菜单栏", symbolName: "switch.2", color: .systemGray),
        SettingsItem(title: "辅助功能", symbolName: "accessibility", color: .systemBlue),
        SettingsItem(title: "聚焦", symbolName: "magnifyingglass", color: .systemBlue),
        SettingsItem(title: "墙纸", symbolName: "atom", color: .systemTeal),
        SettingsItem(title: "外观", symbolName: "circle.lefthalf.filled", color: .black),
        SettingsItem(title: "显示器", symbolName: "display", color: .systemBlue),
        SettingsItem(title: "桌面与程序坞", symbolName: "dock.rectangle", color: .black),
        SettingsItem(title: "Apple 智能与 Siri", symbolName: "sparkles", color: .systemPink)
    ]

    private lazy var rows: [SidebarRow] = [.account, .update] + itemRows.map { .item($0) }
    private let tableView = NSTableView()
    private let detailStackView = NSStackView()
    private let detailTitleLabel = NSTextField(labelWithString: "外观")

    override func loadView() {
        let splitView = FloatingSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        view = splitView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let splitView = view as? NSSplitView else {
            return
        }

        let sidebarView = makeSidebar()
        let detailView = makeDetail()

        splitView.addArrangedSubview(sidebarView)
        splitView.addArrangedSubview(detailView)

        NSLayoutConstraint.activate([
            sidebarView.widthAnchor.constraint(equalToConstant: 230)
        ])

        if let appearanceIndex = rows.firstIndex(where: { $0.title == "外观" }) {
            tableView.selectRowIndexes(IndexSet(integer: appearanceIndex), byExtendingSelection: false)
        }
    }

    private func makeSidebar() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.clear.cgColor
        container.layer?.masksToBounds = false

        let shadowPanel = SidebarPanelShadowView()
        shadowPanel.translatesAutoresizingMaskIntoConstraints = false

        let contentPanel = SidebarPanelContentView()
        contentPanel.translatesAutoresizingMaskIntoConstraints = false

        let searchField = NSSearchField()
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholderString = "搜索"

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("SidebarColumn"))
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .none
        tableView.intercellSpacing = NSSize(width: 0, height: 3)
        tableView.dataSource = self
        tableView.delegate = self

        scrollView.documentView = tableView

        container.addSubview(shadowPanel)
        shadowPanel.addSubview(contentPanel)
        contentPanel.addSubview(searchField)
        contentPanel.addSubview(scrollView)

        NSLayoutConstraint.activate([
            shadowPanel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            shadowPanel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),
            shadowPanel.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            shadowPanel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),

            contentPanel.leadingAnchor.constraint(equalTo: shadowPanel.leadingAnchor, constant: 8),
            contentPanel.trailingAnchor.constraint(equalTo: shadowPanel.trailingAnchor, constant: -8),
            contentPanel.topAnchor.constraint(equalTo: shadowPanel.topAnchor, constant: 8),
            contentPanel.bottomAnchor.constraint(equalTo: shadowPanel.bottomAnchor, constant: -8),

            searchField.leadingAnchor.constraint(equalTo: contentPanel.leadingAnchor, constant: 12),
            searchField.trailingAnchor.constraint(equalTo: contentPanel.trailingAnchor, constant: -12),
            searchField.topAnchor.constraint(equalTo: contentPanel.topAnchor, constant: 60),

            scrollView.leadingAnchor.constraint(equalTo: contentPanel.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: contentPanel.trailingAnchor, constant: -8),
            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            scrollView.bottomAnchor.constraint(equalTo: contentPanel.bottomAnchor, constant: -10)
        ])

        return container
    }

    private func makeDetail() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor(calibratedWhite: 0.985, alpha: 1).cgColor

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder

        let documentView = FlippedView()
        documentView.translatesAutoresizingMaskIntoConstraints = false

        detailStackView.translatesAutoresizingMaskIntoConstraints = false
        detailStackView.orientation = .vertical
        detailStackView.alignment = .leading
        detailStackView.spacing = 20

        detailTitleLabel.font = NSFont.systemFont(ofSize: 22, weight: .semibold)

        detailStackView.addArrangedSubview(detailTitleLabel)
        rebuildAppearancePage()

        documentView.addSubview(detailStackView)
        scrollView.documentView = documentView
        container.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            documentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),

            detailStackView.leadingAnchor.constraint(equalTo: documentView.leadingAnchor, constant: 6),
            detailStackView.topAnchor.constraint(equalTo: documentView.topAnchor, constant: 20),
            detailStackView.widthAnchor.constraint(equalToConstant: 460),
            detailStackView.bottomAnchor.constraint(lessThanOrEqualTo: documentView.bottomAnchor, constant: -36)
        ])

        return container
    }

    private func rebuildAppearancePage() {
        while detailStackView.arrangedSubviews.count > 1 {
            let view = detailStackView.arrangedSubviews[1]
            detailStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        detailStackView.addArrangedSubview(makeGroup(rows: [
            makeSettingsRow(title: "外观", control: makeSegmentedControl(items: ["自动", "浅色", "深色"], selected: 1)),
            makeSettingsRow(title: "Liquid Glass", subtitle: "选取喜欢的 Liquid Glass 外观。", control: makeSegmentedControl(items: ["透明", "色调"], selected: 0))
        ]))

        detailStackView.addArrangedSubview(makeSectionTitle("主题"))
        detailStackView.addArrangedSubview(makeGroup(rows: [
            makeSettingsRow(title: "颜色", control: makeAccentDots()),
            makeSettingsRow(title: "文本高亮标记颜色", control: makePopup(items: ["自动", "蓝色", "紫色"])),
            makeSettingsRow(title: "图标与小组件样式", control: makeIconPreviews())
        ]))

        detailStackView.addArrangedSubview(makeSectionTitle("窗口"))
        detailStackView.addArrangedSubview(makeGroup(rows: [
            makeSettingsRow(title: "边栏图标大小", control: makePopup(items: ["小", "中", "大"], selected: 1)),
            makeToggleRow()
        ]))
    }

    private func showPlaceholderPage(title: String) {
        while detailStackView.arrangedSubviews.count > 1 {
            let view = detailStackView.arrangedSubviews[1]
            detailStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let label = NSTextField(labelWithString: "这一页后面再补。")
        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = .secondaryLabelColor
        detailStackView.addArrangedSubview(label)
        detailTitleLabel.stringValue = title
    }

    private func makeSectionTitle(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func makeGroup(rows: [NSView]) -> NSView {
        let container = RoundedGroupView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 0

        for (index, row) in rows.enumerated() {
            stack.addArrangedSubview(row)
            if index < rows.count - 1 {
                stack.addArrangedSubview(makeDivider())
            }
        }

        container.addSubview(stack)

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 460),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
        ])

        return container
    }

    private func makeSettingsRow(title: String, subtitle: String? = nil, control: NSView) -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let labelStack = NSStackView()
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        labelStack.orientation = .vertical
        labelStack.alignment = .leading
        labelStack.spacing = 2

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 13)
        labelStack.addArrangedSubview(titleLabel)

        if let subtitle {
            let subtitleLabel = NSTextField(labelWithString: subtitle)
            subtitleLabel.font = NSFont.systemFont(ofSize: 11)
            subtitleLabel.textColor = .secondaryLabelColor
            labelStack.addArrangedSubview(subtitleLabel)
        }

        control.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(labelStack)
        row.addSubview(control)

        labelStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        control.setContentHuggingPriority(.required, for: .horizontal)
        control.setContentCompressionResistancePriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            row.widthAnchor.constraint(equalToConstant: 436),
            row.heightAnchor.constraint(equalToConstant: subtitle == nil ? 38 : 56),

            labelStack.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            labelStack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            labelStack.trailingAnchor.constraint(lessThanOrEqualTo: control.leadingAnchor, constant: -16),

            control.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            control.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }

    private func makeToggleRow() -> NSView {
        let toggle = NSSwitch()
        toggle.state = .on

        return makeSettingsRow(title: "基于墙纸颜色调整窗口背景色调", control: toggle)
    }

    private func makeDivider() -> NSBox {
        let divider = NSBox()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.boxType = .separator
        divider.widthAnchor.constraint(equalToConstant: 436).isActive = true
        return divider
    }

    private func makeSegmentedControl(items: [String], selected: Int) -> NSSegmentedControl {
        let control = NSSegmentedControl(labels: items, trackingMode: .selectOne, target: nil, action: nil)
        control.selectedSegment = selected
        control.controlSize = .small
        return control
    }

    private func makePopup(items: [String], selected: Int = 0) -> NSPopUpButton {
        let popup = NSPopUpButton()
        popup.controlSize = .small
        popup.addItems(withTitles: items)
        popup.selectItem(at: selected)
        return popup
    }

    private func makeAccentDots() -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 13

        let colors: [NSColor] = [.systemBlue, .systemPurple, .systemPink, .systemRed, .systemOrange, .systemYellow, .systemGreen, .systemGray]
        stack.addArrangedSubview(ColorDotView(color: .clear, selected: true, multicolor: true))
        colors.forEach { stack.addArrangedSubview(ColorDotView(color: $0)) }

        return stack
    }

    private func makeIconPreviews() -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 12

        [
            ("默认", "sun.max.fill", true),
            ("深色", "moon.fill", false),
            ("透明", "cloud.fill", false),
            ("色调", "cloud.sun.fill", false)
        ].forEach { title, symbolName, selected in
            stack.addArrangedSubview(IconPreviewView(title: title, symbolName: symbolName, selected: selected))
        }

        return stack
    }
}

extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        rows.count
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        switch rows[row] {
        case .account:
            50
        case .update:
            38
        case .item:
            30
        }
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        rows[row].isSelectable
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        SidebarRowView()
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch rows[row] {
        case .account:
            return AccountCellView()
        case .update:
            return UpdateCellView()
        case .item(let item):
            return SidebarItemCellView(item: item)
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard rows.indices.contains(row) else {
            return
        }

        let title = rows[row].title
        detailTitleLabel.stringValue = title

        if title == "外观" {
            rebuildAppearancePage()
        } else {
            showPlaceholderPage(title: title)
        }
    }
}

private final class SidebarRowView: NSTableRowView {
    override var isSelected: Bool {
        didSet {
            needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        if isSelected {
            drawSelection(in: dirtyRect)
        } else {
            super.draw(dirtyRect)
        }
    }

    override func drawSelection(in dirtyRect: NSRect) {
        guard isSelected else {
            return
        }

        let selectionRect = bounds.insetBy(dx: 2, dy: 1)
        NSColor.controlAccentColor.setFill()
        NSBezierPath(roundedRect: selectionRect, xRadius: 7, yRadius: 7).fill()
    }
}

private final class FloatingSplitView: NSSplitView {
    override var dividerThickness: CGFloat {
        0
    }

    override func drawDivider(in rect: NSRect) {
    }
}

private final class SidebarPanelShadowView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.masksToBounds = false
    }

    override func layout() {
        super.layout()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let panelRect = bounds.insetBy(dx: 8, dy: 8)

        for step in 0..<7 {
            let outset = CGFloat(step)
            let alpha = CGFloat(0.075 - Double(step) * 0.008)
            let shadowRect = panelRect.insetBy(dx: -outset, dy: -outset)
            NSColor.black.withAlphaComponent(max(alpha, 0.012)).setStroke()

            let path = NSBezierPath(roundedRect: shadowRect, xRadius: 14 + outset, yRadius: 14 + outset)
            path.lineWidth = 1
            path.stroke()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class SidebarPanelContentView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.backgroundColor = NSColor(calibratedWhite: 0.955, alpha: 0.98).cgColor
        layer?.cornerRadius = 14
        layer?.borderWidth = 0.5
        layer?.borderColor = NSColor.white.withAlphaComponent(0.85).cgColor
        layer?.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class RoundedGroupView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.backgroundColor = NSColor(calibratedWhite: 0.965, alpha: 1).cgColor
        layer?.cornerRadius = 10
        layer?.borderWidth = 0.5
        layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.35).cgColor
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.08
        layer?.shadowRadius = 10
        layer?.shadowOffset = NSSize(width: 0, height: -2)
        layer?.masksToBounds = false
    }

    override var isFlipped: Bool {
        true
    }

    override func layout() {
        super.layout()
        layer?.shadowPath = CGPath(roundedRect: bounds, cornerWidth: 10, cornerHeight: 10, transform: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class FlippedView: NSView {
    override var isFlipped: Bool {
        true
    }
}

private final class SidebarItemCellView: NSTableCellView {
    private let iconView: SidebarIconView
    private let titleLabel: NSTextField

    init(item: ViewController.SettingsItem) {
        iconView = SidebarIconView(symbolName: item.symbolName, color: item.color)
        titleLabel = NSTextField(labelWithString: item.title)
        super.init(frame: .zero)

        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = NSFont.systemFont(ofSize: 13)
        titleLabel.lineBreakMode = .byTruncatingTail

        addSubview(iconView)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override func viewWillDraw() {
        super.viewWillDraw()

        let selected = enclosingScrollView?.documentView.flatMap { documentView in
            (documentView as? NSTableView)?.row(for: self)
        }.map { row in
            (enclosingScrollView?.documentView as? NSTableView)?.isRowSelected(row) == true
        } ?? false

        titleLabel.textColor = selected ? .white : .labelColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class SidebarIconView: NSView {
    private let color: NSColor

    init(symbolName: String, color: NSColor) {
        self.color = color
        super.init(frame: .zero)
        wantsLayer = true

        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        imageView.image?.isTemplate = true
        imageView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        imageView.contentTintColor = .white
        imageView.imageScaling = .scaleProportionallyDown

        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }

    override func draw(_ dirtyRect: NSRect) {
        color.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 5, yRadius: 5).fill()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class AccountCellView: NSTableCellView {
    init() {
        super.init(frame: .zero)

        let iconView = NSImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = NSImage(systemSymbolName: "person.crop.circle.fill", accessibilityDescription: "Apple 账户")
        iconView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 32, weight: .regular)
        iconView.contentTintColor = .secondaryLabelColor

        let nameLabel = NSTextField(labelWithString: "王杰")
        nameLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)

        let accountLabel = NSTextField(labelWithString: "Apple 账户")
        accountLabel.font = NSFont.systemFont(ofSize: 11)
        accountLabel.textColor = .secondaryLabelColor

        let labels = NSStackView(views: [nameLabel, accountLabel])
        labels.translatesAutoresizingMaskIntoConstraints = false
        labels.orientation = .vertical
        labels.alignment = .leading
        labels.spacing = 1

        addSubview(iconView)
        addSubview(labels)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 34),

            labels.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            labels.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            labels.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class UpdateCellView: NSTableCellView {
    init() {
        super.init(frame: .zero)

        let label = NSTextField(labelWithString: "今晚安装软件更新")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.systemFont(ofSize: 13)

        let badge = BadgeView(text: "1")
        badge.translatesAutoresizingMaskIntoConstraints = false

        addSubview(label)
        addSubview(badge)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),

            badge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            badge.centerYAnchor.constraint(equalTo: centerYAnchor),
            badge.widthAnchor.constraint(equalToConstant: 18),
            badge.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class BadgeView: NSView {
    private let text: String

    init(text: String) {
        self.text = text
        super.init(frame: .zero)
        wantsLayer = true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.systemRed.setFill()
        NSBezierPath(ovalIn: bounds).fill()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let size = text.size(withAttributes: attributes)
        let rect = NSRect(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
        text.draw(in: rect, withAttributes: attributes)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class ColorDotView: NSView {
    private let color: NSColor
    private let selected: Bool
    private let multicolor: Bool

    init(color: NSColor, selected: Bool = false, multicolor: Bool = false) {
        self.color = color
        self.selected = selected
        self.multicolor = multicolor
        super.init(frame: NSRect(x: 0, y: 0, width: 30, height: 30))
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 30),
            heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    override func draw(_ dirtyRect: NSRect) {
        let dotRect = bounds.insetBy(dx: 3, dy: 3)

        if multicolor {
            drawMulticolorDot(in: dotRect)
        } else {
            color.setFill()
            NSBezierPath(ovalIn: dotRect).fill()
        }

        if selected {
            NSColor.controlAccentColor.setStroke()
            let ring = NSBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1))
            ring.lineWidth = 3
            ring.stroke()
        }
    }

    private func drawMulticolorDot(in rect: NSRect) {
        let colors: [NSColor] = [.systemRed, .systemYellow, .systemGreen, .systemBlue, .systemPurple]
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let radius = rect.width / 2

        for index in colors.indices {
            colors[index].setFill()
            let path = NSBezierPath()
            path.move(to: center)
            path.appendArc(
                withCenter: center,
                radius: radius,
                startAngle: CGFloat(index) * 72,
                endAngle: CGFloat(index + 1) * 72
            )
            path.close()
            path.fill()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class IconPreviewView: NSStackView {
    init(title: String, symbolName: String, selected: Bool) {
        super.init(frame: .zero)

        orientation = .vertical
        alignment = .centerX
        spacing = 4

        let imageBox = IconImageBox(symbolName: symbolName, selected: selected)
        let label = NSTextField(labelWithString: title)
        label.font = NSFont.systemFont(ofSize: 11)
        label.textColor = selected ? .labelColor : .secondaryLabelColor

        addArrangedSubview(imageBox)
        addArrangedSubview(label)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class IconImageBox: NSView {
    private let symbolName: String
    private let selected: Bool

    init(symbolName: String, selected: Bool) {
        self.symbolName = symbolName
        self.selected = selected
        super.init(frame: NSRect(x: 0, y: 0, width: 36, height: 36))
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 36),
            heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlAccentColor.withAlphaComponent(selected ? 0.18 : 0.08).setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8).fill()

        if selected {
            NSColor.controlAccentColor.setStroke()
            let outline = NSBezierPath(roundedRect: bounds.insetBy(dx: 1.5, dy: 1.5), xRadius: 8, yRadius: 8)
            outline.lineWidth = 3
            outline.stroke()
        }

        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        image?.draw(in: bounds.insetBy(dx: 8, dy: 8))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
