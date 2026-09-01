# 用 AppKit 做出 SwiftUI NavigationSplitView 的 macOS 原生质感

本文总结当前 demo 的实现方向：不用 SwiftUI 的 `NavigationSplitView`，但用 AppKit 的原生窗口、split view、sidebar 和 source list 组合，做出接近 `NavigationSplitView` 在 macOS 上的 sidebar 质感。

目标不是逐像素手画一个 sidebar，而是尽量把结构交给 AppKit 的原生组件。

## 核心结论

要做出 SwiftUI `NavigationSplitView` 那种 macOS 原生感，关键不是颜色，而是结构：

```swift
NSSplitViewController
NSSplitViewItem(sidebarWithViewController:)
NSVisualEffectView(material: .sidebar)
NSTableView.style = .sourceList
NSToolbar + .sidebarTrackingSeparator
NSWindow.StyleMask.fullSizeContentView
```

如果只用普通 `NSSplitView` 加一个灰色 `NSView`，很容易变成“自定义侧边栏”，看起来不像系统控件。

## 当前 demo 的结构

当前项目里，窗口根控制器在 `ViewController` 中组装：

```swift
private let splitViewController = NSSplitViewController()
private let sidebarViewController = SettingsSidebarViewController()
private let detailViewController = NSViewController()
private let settingsView = SettingsView(frame: .zero)
```

左侧用：

```swift
let sidebarItem = NSSplitViewItem(
    sidebarWithViewController: sidebarViewController
)
```

右侧用普通 detail item：

```swift
let detailItem = NSSplitViewItem(viewController: detailViewController)
```

这一步很重要。`sidebarWithViewController` 会让 AppKit 按 sidebar 的语义处理左侧区域，比手动 `addArrangedSubview` 更接近 SwiftUI `NavigationSplitView`。

## 窗口配置

窗口需要让 content view 进入 titlebar 区域，这样 sidebar 才能和标题栏融合：

```swift
window.title = "Settings"
window.titleVisibility = .visible
window.titlebarAppearsTransparent = true
window.styleMask.insert(.fullSizeContentView)
window.toolbarStyle = .unified
```

同时 toolbar 里保留 sidebar 分隔线：

```swift
[
    .sidebarTrackingSeparator,
    .flexibleSpace
]
```

这会产生类似系统 App 的 titlebar/sidebar 分隔关系。没有这一步，sidebar 会像放在标题栏下面的一块普通面板。

## Sidebar 背景

sidebar 根视图使用 `NSVisualEffectView`：

```swift
let visualView = NSVisualEffectView()
visualView.material = .sidebar
visualView.blendingMode = .withinWindow
visualView.state = .active
view = visualView
```

`material = .sidebar` 是关键。它比普通灰色背景更接近系统 sidebar。

当前 demo 额外加了一层很轻的 wash：

```swift
NSColor.white.withAlphaComponent(0.62)
```

原因是 `.sidebar` 材质会受窗口背后内容影响。如果后面是深色网页或图片，sidebar 会显得偏灰。轻 wash 可以让它更接近 SwiftUI demo 里那种浅白、干净的 sidebar。

这层 wash 不是替代原生材质，而是压住过强的背景透出。

## Sidebar 列表

列表使用 `NSTableView`：

```swift
tableView.headerView = nil
tableView.style = .sourceList
tableView.rowHeight = 32
tableView.intercellSpacing = .zero
tableView.backgroundColor = .clear
```

`style = .sourceList` 决定了系统 source list 的选择态、键盘行为和基础观感。

当前 demo 的 sidebar cell 只保留文字：

```swift
let label = NSTextField(labelWithString: "")
label.font = .systemFont(ofSize: 13, weight: .semibold)
```

这里特意去掉了彩色图标。原因是参考的 SwiftUI `NavigationSplitView` demo 左侧是纯文字列表；如果加彩色设置图标，会更像自定义设置页，而不是轻量系统 sidebar。

## 尺寸和间距

当前较接近目标的参数：

```swift
sidebarItem.minimumThickness = 236
sidebarItem.maximumThickness = 260
window.setContentSize(NSSize(width: 760, height: 540))
```

sidebar 内部列表：

```swift
scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4)
scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4)
scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 72)
```

几个判断标准：

- sidebar 不能太窄，否则不像 SwiftUI demo 的比例。
- 列表左右 inset 不能太大，否则蓝色选中条会显得短。
- 顶部 inset 要给 traffic light/titlebar 留空间。
- 右侧 detail 不要设置过大的最小宽度，否则整个窗口会被撑宽。

## Detail 区域

右侧内容不要参与 sidebar 的结构。当前做法是让 `SettingsView` 只负责 detail：

```swift
detailViewController.view = settingsView
```

`SettingsView` 内部只保留右侧页面内容，不再自己创建 split view 或 sidebar。

这一点可以避免两套导航结构混在一起：外层 `NSSplitViewController` 管布局，内层 `SettingsView` 管设置内容。

## 常见问题

### 1. 看起来像自定义 UI

通常是因为做了这些事：

- 自己画 sidebar 背景，而不是用 `NSVisualEffectView.material = .sidebar`
- 用普通 `NSSplitView`，没有用 `NSSplitViewItem(sidebarWithViewController:)`
- sidebar cell 放了过重的图标、卡片、按钮样式
- 字体、行高、选中条都手动设计得太重

### 2. Sidebar 没有融入 titlebar

检查窗口是否有：

```swift
window.titlebarAppearsTransparent = true
window.styleMask.insert(.fullSizeContentView)
window.toolbarStyle = .unified
```

再检查 toolbar 是否包含：

```swift
.sidebarTrackingSeparator
```

### 3. 右侧把窗口撑太宽

不要让 detail view 自己声明过大的最小宽度。当前 demo 曾经有：

```swift
private static let minimumSize = NSSize(width: 800, height: 520)
```

放进 split view 后，这等于强制右侧至少 800 宽。现在降为：

```swift
private static let minimumSize = NSSize(width: 500, height: 520)
```

### 4. Sidebar 背景太灰

`.sidebar` material 不是固定颜色，会受窗口背后内容和 vibrancy 影响。当前 demo 用轻 wash 稳定浅色效果：

```swift
return NSColor.white.withAlphaComponent(0.62)
```

如果后续放进真实 Snapio，需要在浅色/深色模式下分别看实际效果。

## 推荐迁移顺序

1. 先把 Settings 窗口根结构改成 `NSSplitViewController`。
2. 左侧使用独立的 `SettingsSidebarViewController`。
3. sidebar split item 使用 `NSSplitViewItem(sidebarWithViewController:)`。
4. sidebar 根视图使用 `NSVisualEffectView(.sidebar)`。
5. 列表使用 `NSTableView.style = .sourceList`。
6. 先做纯文字列表，确认原生感后再考虑是否加图标。
7. 右侧 detail 保持现有内容，只调整宽度、背景和行组样式。

## 当前基线

当前项目的目标基线是：

- 左侧接近 SwiftUI `NavigationSplitView` 的纯文字 sidebar。
- 使用 AppKit 原生 sidebar/sourceList 结构。
- 不走网页式导航、不做彩色卡片式 sidebar。
- 设置项内容保持现有业务含义，只优化 macOS 原生视觉。

