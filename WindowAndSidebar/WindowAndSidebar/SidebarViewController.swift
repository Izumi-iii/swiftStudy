import AppKit

protocol SidebarViewControllerDelegate: AnyObject {
    func sidebarViewController(_ controller: SidebarViewController, didSelect item: SidebarItem)
}

final class SidebarViewController: NSViewController {
    weak var delegate: SidebarViewControllerDelegate?

    private let outlineView = NSOutlineView()
    private let scrollView = NSScrollView()
    private lazy var sections = makeSections()
    private var isSelectingProgrammatically = false

    override func loadView() {
        let visualView = NSVisualEffectView()
        visualView.material = .sidebar
        visualView.blendingMode = .behindWindow
        visualView.state = .active
        view = visualView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        outlineView.headerView = nil
        outlineView.floatsGroupRows = false
        outlineView.rowHeight = 34
        outlineView.indentationPerLevel = 0
        outlineView.style = .sourceList
        outlineView.backgroundColor = .clear
        outlineView.delegate = self
        outlineView.dataSource = self

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("SidebarColumn"))
        column.resizingMask = .autoresizingMask
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column

        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])

        outlineView.reloadData()
        sections.forEach { outlineView.expandItem($0) }
    }

    func select(url: URL) {
        for section in sections {
            guard let item = section.items.first(where: {
                $0.url?.standardizedFileURL == url.standardizedFileURL
            }) else { continue }
            let row = outlineView.row(forItem: item)
            if row >= 0 {
                isSelectingProgrammatically = true
                outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                isSelectingProgrammatically = false
                return
            }
        }
        outlineView.deselectAll(nil)
    }

    func select(named name: String) {
        for section in sections {
            guard let item = section.items.first(where: { $0.title == name }) else { continue }
            let row = outlineView.row(forItem: item)
            guard row >= 0 else { continue }
            isSelectingProgrammatically = true
            outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            isSelectingProgrammatically = false
            delegate?.sidebarViewController(self, didSelect: item)
            return
        }
    }

    private func makeSections() -> [SidebarSection] {
        let manager = FileManager.default
        let home = manager.homeDirectoryForCurrentUser

        func directory(_ directory: FileManager.SearchPathDirectory) -> URL? {
            manager.urls(for: directory, in: .userDomainMask).first
        }

        return [
            SidebarSection(title: nil, items: [
                .location(title: "Recents", symbol: "clock", url: home),
                .location(title: "AirDrop", symbol: "airplayaudio", url: home),
                .location(title: "Shared", symbol: "folder.badge.person.crop", url: home)
            ]),
            SidebarSection(title: "Favorites", items: [
                .location(title: "Applications", symbol: "a.square", url: directory(.applicationDirectory)),
                .location(title: "Desktop", symbol: "macwindow", url: directory(.desktopDirectory)),
                .location(title: "Documents", symbol: "doc", url: directory(.documentDirectory)),
                .location(title: "Downloads", symbol: "arrow.down.circle", url: directory(.downloadsDirectory)),
                .location(title: "Movies", symbol: "film", url: directory(.moviesDirectory)),
                .location(title: "Music", symbol: "music.note", url: directory(.musicDirectory)),
                .location(title: "Pictures", symbol: "photo", url: directory(.picturesDirectory))
            ]),
            SidebarSection(title: "Locations", items: [
                .location(
                    title: "iCloud Drive",
                    symbol: "icloud",
                    url: manager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
                ),
                .location(
                    title: Host.current().localizedName ?? "This Mac",
                    symbol: "desktopcomputer",
                    url: URL(fileURLWithPath: "/")
                )
            ])
        ]
    }
}

extension SidebarViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil { return sections.count }
        if let section = item as? SidebarSection { return section.items.count }
        return 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil { return sections[index] }
        return (item as! SidebarSection).items[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        item is SidebarSection
    }
}

extension SidebarViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        item is SidebarSection
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        item is SidebarItem
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if let section = item as? SidebarSection {
            return section.title == nil ? 8 : 32
        }
        return 34
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let section = item as? SidebarSection {
            guard let title = section.title else { return NSView() }
            let identifier = NSUserInterfaceItemIdentifier("SidebarHeader")
            let cell = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
                ?? NSTableCellView()
            cell.identifier = identifier

            let label = cell.textField ?? NSTextField(labelWithString: "")
            if label.superview == nil {
                label.translatesAutoresizingMaskIntoConstraints = false
                label.font = .systemFont(ofSize: 12, weight: .semibold)
                label.textColor = .secondaryLabelColor
                cell.textField = label
                cell.addSubview(label)
                NSLayoutConstraint.activate([
                    label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 10),
                    label.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -3)
                ])
            }
            label.stringValue = title
            return cell
        }

        guard let item = item as? SidebarItem else { return nil }
        let identifier = NSUserInterfaceItemIdentifier("SidebarItem")
        let cell = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
            ?? makeSidebarCell(identifier: identifier)
        cell.textField?.stringValue = item.title
        cell.imageView?.image = NSImage(systemSymbolName: item.symbolName, accessibilityDescription: item.title)
        cell.imageView?.contentTintColor = .labelColor
        return cell
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard !isSelectingProgrammatically else { return }
        let row = outlineView.selectedRow
        guard row >= 0, let item = outlineView.item(atRow: row) as? SidebarItem else { return }
        delegate?.sidebarViewController(self, didSelect: item)
    }

    private func makeSidebarCell(identifier: NSUserInterfaceItemIdentifier) -> NSTableCellView {
        let cell = NSTableCellView()
        cell.identifier = identifier

        let icon = NSImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.imageScaling = .scaleProportionallyDown

        let label = NSTextField(labelWithString: "")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.lineBreakMode = .byTruncatingTail

        cell.imageView = icon
        cell.textField = label
        cell.addSubview(icon)
        cell.addSubview(label)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 10),
            icon.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 20),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }
}
