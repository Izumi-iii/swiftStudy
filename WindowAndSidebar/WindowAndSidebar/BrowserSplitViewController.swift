import AppKit

protocol BrowserSplitViewControllerDelegate: AnyObject {
    func browserSplitViewControllerDidChangeLocation(_ controller: BrowserSplitViewController)
}

final class BrowserSplitViewController: NSSplitViewController {
    weak var delegate: BrowserSplitViewControllerDelegate?

    private let sidebarController = SidebarViewController()
    private let fileListController = FileListViewController()
    private var history: [URL] = []
    private var historyIndex = -1

    var displayedTitle: String {
        fileListController.currentURL.lastPathComponent.isEmpty
            ? fileListController.currentURL.path
            : fileListController.currentURL.lastPathComponent
    }

    var canGoBack: Bool { historyIndex > 0 }
    var canGoForward: Bool { historyIndex >= 0 && historyIndex < history.count - 1 }
    var selectedURL: URL? { fileListController.selectedURL }

    override func viewDidLoad() {
        super.viewDidLoad()

        splitView.isVertical = true
        splitView.dividerStyle = .thin

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarController)
        sidebarItem.minimumThickness = 210
        sidebarItem.maximumThickness = 360
        sidebarItem.preferredThicknessFraction = 0.24

        let contentItem = NSSplitViewItem(viewController: fileListController)
        contentItem.minimumThickness = 520

        addSplitViewItem(sidebarItem)
        addSplitViewItem(contentItem)

        sidebarController.delegate = self
        fileListController.delegate = self

        let initialURL = FileManager.default.homeDirectoryForCurrentUser
        navigate(to: initialURL, recordingHistory: true)
    }

    func goBack() {
        guard canGoBack else { return }
        historyIndex -= 1
        navigate(to: history[historyIndex], recordingHistory: false)
    }

    func goForward() {
        guard canGoForward else { return }
        historyIndex += 1
        navigate(to: history[historyIndex], recordingHistory: false)
    }

    func sort(by key: FileSortKey) {
        fileListController.sort(by: key)
    }

    func filter(with query: String) {
        fileListController.filter(with: query)
    }

    func selectSidebarItem(named name: String) {
        sidebarController.select(named: name)
    }

    func createFolder() {
        fileListController.createFolder()
    }

    private func navigate(to url: URL, recordingHistory: Bool) {
        let standardizedURL = url.standardizedFileURL
        if recordingHistory {
            if historyIndex < history.count - 1 {
                history.removeSubrange((historyIndex + 1)..<history.count)
            }
            if history.last != standardizedURL {
                history.append(standardizedURL)
                historyIndex = history.count - 1
            }
        }

        fileListController.show(url: standardizedURL)
        sidebarController.select(url: standardizedURL)
        delegate?.browserSplitViewControllerDidChangeLocation(self)
    }
}

extension BrowserSplitViewController: SidebarViewControllerDelegate {
    func sidebarViewController(_ controller: SidebarViewController, didSelect item: SidebarItem) {
        guard let url = item.url else { return }
        navigate(to: url, recordingHistory: true)
    }
}

extension BrowserSplitViewController: FileListViewControllerDelegate {
    func fileListViewController(_ controller: FileListViewController, didOpen url: URL) {
        navigate(to: url, recordingHistory: true)
    }
}
