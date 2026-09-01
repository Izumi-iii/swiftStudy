import AppKit

enum SidebarItem: Hashable {
    case location(title: String, symbol: String, url: URL?)

    var title: String {
        switch self {
        case .location(let title, _, _): title
        }
    }

    var symbolName: String {
        switch self {
        case .location(_, let symbol, _): symbol
        }
    }

    var url: URL? {
        switch self {
        case .location(_, _, let url): url
        }
    }
}

struct SidebarSection: Hashable {
    let title: String?
    let items: [SidebarItem]
}

struct FileItem: Hashable {
    let url: URL
    let name: String
    let isDirectory: Bool
    let modificationDate: Date?
    let fileSize: Int64?
    let kind: String

    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
}

enum FileSortKey: Int {
    case name
    case dateModified
    case size
    case kind
}
