import AppKit

protocol FileListViewControllerDelegate: AnyObject {
    func fileListViewController(_ controller: FileListViewController, didOpen url: URL)
}

final class FileListViewController: NSViewController {
    weak var delegate: FileListViewControllerDelegate?

    private enum Column {
        static let name = NSUserInterfaceItemIdentifier("Name")
        static let dateModified = NSUserInterfaceItemIdentifier("DateModified")
        static let size = NSUserInterfaceItemIdentifier("Size")
        static let kind = NSUserInterfaceItemIdentifier("Kind")
    }

    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let emptyLabel = NSTextField(labelWithString: "")
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        return formatter
    }()

    private(set) var currentURL = FileManager.default.homeDirectoryForCurrentUser
    private var allItems: [FileItem] = []
    private var visibleItems: [FileItem] = []
    private var query = ""
    private var sortKey: FileSortKey = .name
    private var sortAscending = true

    var selectedURL: URL? {
        guard tableView.selectedRow >= 0,
              tableView.selectedRow < visibleItems.count else { return nil }
        return visibleItems[tableView.selectedRow].url
    }

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureEmptyLabel()
    }

    func show(url: URL) {
        currentURL = url
        query = ""
        reloadDirectory()
    }

    func sort(by key: FileSortKey) {
        if sortKey == key {
            sortAscending.toggle()
        } else {
            sortKey = key
            sortAscending = true
        }
        applyFilterAndSort()
    }

    func filter(with query: String) {
        self.query = query
        applyFilterAndSort()
    }

    func createFolder() {
        var candidate = currentURL.appendingPathComponent("New Folder", isDirectory: true)
        var suffix = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = currentURL.appendingPathComponent("New Folder \(suffix)", isDirectory: true)
            suffix += 1
        }

        do {
            try FileManager.default.createDirectory(at: candidate, withIntermediateDirectories: false)
            reloadDirectory()
            if let row = visibleItems.firstIndex(where: { $0.url == candidate }) {
                tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                tableView.scrollRowToVisible(row)
            }
        } catch {
            presentError(error)
        }
    }

    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.rowHeight = 28
        tableView.intercellSpacing = .zero
        tableView.gridStyleMask = []
        tableView.allowsMultipleSelection = true
        tableView.allowsEmptySelection = true
        tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        tableView.doubleAction = #selector(openSelectedItem)
        tableView.target = self

        addColumn(identifier: Column.name, title: "Name", width: 410, minWidth: 230)
        addColumn(identifier: Column.dateModified, title: "Date Modified", width: 250, minWidth: 180)
        addColumn(identifier: Column.size, title: "Size", width: 115, minWidth: 90)
        addColumn(identifier: Column.kind, title: "Kind", width: 160, minWidth: 100)

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12)
        ])
    }

    private func configureEmptyLabel() {
        emptyLabel.font = .systemFont(ofSize: 14)
        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.alignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func addColumn(
        identifier: NSUserInterfaceItemIdentifier,
        title: String,
        width: CGFloat,
        minWidth: CGFloat
    ) {
        let column = NSTableColumn(identifier: identifier)
        column.title = title
        column.width = width
        column.minWidth = minWidth
        column.resizingMask = .userResizingMask
        tableView.addTableColumn(column)
    }

    private func reloadDirectory() {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .contentModificationDateKey,
            .fileSizeKey,
            .localizedTypeDescriptionKey
        ]
        do {
            let urls = try FileManager.default.contentsOfDirectory(
                at: currentURL,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsHiddenFiles]
            )
            allItems = urls.compactMap { url in
                guard let values = try? url.resourceValues(forKeys: keys) else { return nil }
                return FileItem(
                    url: url,
                    name: url.lastPathComponent,
                    isDirectory: values.isDirectory ?? false,
                    modificationDate: values.contentModificationDate,
                    fileSize: values.isDirectory == true ? nil : Int64(values.fileSize ?? 0),
                    kind: values.localizedTypeDescription ?? (values.isDirectory == true ? "Folder" : "File")
                )
            }
            applyFilterAndSort()
        } catch {
            allItems = []
            visibleItems = []
            tableView.reloadData()
            emptyLabel.stringValue = "This location can't be opened"
            emptyLabel.isHidden = false
        }
    }

    private func applyFilterAndSort() {
        if query.isEmpty {
            visibleItems = allItems
        } else {
            visibleItems = allItems.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }

        visibleItems.sort { lhs, rhs in
            let result: ComparisonResult
            switch sortKey {
            case .name:
                if lhs.isDirectory != rhs.isDirectory {
                    return lhs.isDirectory
                }
                result = lhs.name.localizedStandardCompare(rhs.name)
            case .dateModified:
                result = compare(lhs.modificationDate, rhs.modificationDate)
            case .size:
                result = compare(lhs.fileSize, rhs.fileSize)
            case .kind:
                result = lhs.kind.localizedStandardCompare(rhs.kind)
            }
            return sortAscending ? result == .orderedAscending : result == .orderedDescending
        }

        tableView.reloadData()
        emptyLabel.stringValue = query.isEmpty ? "This folder is empty" : "No matching files"
        emptyLabel.isHidden = !visibleItems.isEmpty
    }

    private func compare<T: Comparable>(_ lhs: T?, _ rhs: T?) -> ComparisonResult {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            if lhs < rhs { return .orderedAscending }
            if lhs > rhs { return .orderedDescending }
            return .orderedSame
        case (nil, nil):
            return .orderedSame
        case (nil, _):
            return .orderedAscending
        case (_, nil):
            return .orderedDescending
        }
    }

    @objc private func openSelectedItem() {
        let row = tableView.clickedRow >= 0 ? tableView.clickedRow : tableView.selectedRow
        guard row >= 0, row < visibleItems.count else { return }
        let item = visibleItems[row]
        if item.isDirectory {
            delegate?.fileListViewController(self, didOpen: item.url)
        } else {
            NSWorkspace.shared.open(item.url)
        }
    }
}

extension FileListViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        visibleItems.count
    }
}

extension FileListViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        FinderTableRowView(isAlternate: row % 2 == 1)
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < visibleItems.count, let tableColumn else { return nil }
        let item = visibleItems[row]
        if tableColumn.identifier == Column.name {
            return nameCell(for: item, in: tableView)
        }

        let text: String
        switch tableColumn.identifier {
        case Column.dateModified:
            text = item.modificationDate.map(dateFormatter.string(from:)) ?? "--"
        case Column.size:
            text = item.fileSize.map(byteFormatter.string(fromByteCount:)) ?? "--"
        case Column.kind:
            text = item.kind
        default:
            text = ""
        }
        return textCell(text, identifier: tableColumn.identifier, in: tableView)
    }

    private func nameCell(for item: FileItem, in tableView: NSTableView) -> NSTableCellView {
        let identifier = NSUserInterfaceItemIdentifier("NameCell")
        let cell = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
            ?? makeNameCell(identifier: identifier)
        cell.textField?.stringValue = item.name
        cell.imageView?.image = item.icon
        return cell
    }

    private func makeNameCell(identifier: NSUserInterfaceItemIdentifier) -> NSTableCellView {
        let cell = NSTableCellView()
        cell.identifier = identifier

        let icon = NSImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.imageScaling = .scaleProportionallyDown

        let label = NSTextField(labelWithString: "")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13)
        label.lineBreakMode = .byTruncatingMiddle

        cell.imageView = icon
        cell.textField = label
        cell.addSubview(icon)
        cell.addSubview(label)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
            icon.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 20),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 7),
            label.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }

    private func textCell(
        _ text: String,
        identifier: NSUserInterfaceItemIdentifier,
        in tableView: NSTableView
    ) -> NSTableCellView {
        let cellIdentifier = NSUserInterfaceItemIdentifier("TextCell.\(identifier.rawValue)")
        let cell = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView
            ?? NSTableCellView()
        cell.identifier = cellIdentifier

        let label: NSTextField
        if let existing = cell.textField {
            label = existing
        } else {
            label = NSTextField(labelWithString: "")
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .systemFont(ofSize: 13)
            label.textColor = .secondaryLabelColor
            label.lineBreakMode = .byTruncatingTail
            cell.textField = label
            cell.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
                label.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -8),
                label.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
            ])
        }
        label.stringValue = text
        return cell
    }
}

private final class FinderTableRowView: NSTableRowView {
    private let isAlternate: Bool

    init(isAlternate: Bool) {
        self.isAlternate = isAlternate
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawBackground(in dirtyRect: NSRect) {
        guard isAlternate else { return }
        NSColor.white.withAlphaComponent(0.035).setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 6, yRadius: 6).fill()
    }

    override func drawSelection(in dirtyRect: NSRect) {
        guard selectionHighlightStyle != .none else { return }
        let color = isEmphasized
            ? NSColor.controlAccentColor.withAlphaComponent(0.55)
            : NSColor.white.withAlphaComponent(0.10)
        color.setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 6, yRadius: 6).fill()
    }
}
