# AGENTS.md

## Purpose

This project is an AppKit reference implementation for a macOS System Settings-style window. Use it as a migration source when another macOS project wants the same native Settings visual language.

The goal is not to copy the demo settings literally. The goal is to preserve these visual traits:

- a full-size AppKit window whose content extends under the titlebar
- traffic-light window buttons visually sitting inside the left floating sidebar panel
- a rounded sidebar panel that feels like a small layer floating inside the window
- a subtle four-sided sidebar shadow, not a heavy one-sided drop shadow
- colorful sidebar icons with white SF Symbols
- a blue rounded selected sidebar row
- a quiet right-side detail surface with grouped rounded setting cards
- card groups with subtle borders, separators, and light depth

Treat all labels such as `王杰`, `今晚安装软件更新`, `外观`, and the demo setting rows as placeholders.

## Source Of Truth

Inspect these files first:

- `SettingsAppkitDemo/AppDelegate.swift`
- `SettingsAppkitDemo/ViewController.swift`
- `SettingsAppkitDemo/main.swift`
- `SettingsAppkitDemo.xcodeproj/project.pbxproj`

Most reusable UI code is in `ViewController.swift`. Window setup lives in `AppDelegate.swift`. The project entry configuration matters because this demo intentionally does not start from the default storyboard.

## Migration Priority

Migrate in this order:

1. Window setup from `AppDelegate.showMainWindow()`
2. Traffic-light repositioning from `AppDelegate.positionTrafficLightButtons(in:)`
3. Split layout and sidebar container from `ViewController.loadView()` and `makeSidebar()`
4. Sidebar floating panel classes
5. Sidebar row, icon, account, and badge cell classes
6. Right-side detail layout from `makeDetail()`
7. Card group helpers and card classes
8. Real product settings data and controls

Do not start by copying only the right-side setting rows. The native Settings feel mainly comes from the window/titlebar integration and the left floating sidebar layer.

## Window Setup

`AppDelegate.showMainWindow()` creates an `NSWindow` manually:

```swift
let viewController = ViewController()
let window = NSWindow(contentViewController: viewController)
window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
window.titlebarAppearsTransparent = true
window.titleVisibility = .hidden
window.toolbarStyle = .unified
window.isReleasedWhenClosed = false
```

Important requirements:

- keep `.fullSizeContentView`
- hide the title text
- make the titlebar transparent
- keep the window alive with `isReleasedWhenClosed = false`
- call `makeKeyAndOrderFront(nil)` before adjusting titlebar buttons

Without `.fullSizeContentView`, the sidebar cannot visually occupy the titlebar area and the traffic-light buttons will look detached from the sidebar panel.

## Traffic-Light Buttons

The standard red/yellow/green macOS buttons are repositioned in:

```swift
positionTrafficLightButtons(in:)
```

Current offset:

```swift
frame.origin.x += 22
frame.origin.y -= 10
```

The call is intentionally delayed:

```swift
window.makeKeyAndOrderFront(nil)

DispatchQueue.main.async {
    self.positionTrafficLightButtons(in: window)
}
```

If this runs too early, AppKit's titlebar layout can overwrite the custom frames.

When migrating, tune only the offsets after the sidebar panel's top/left padding is final. The buttons should sit inside the visible sidebar card, not in the blank window margin.

## App Entry And Storyboard

This demo uses `main.swift`:

```swift
let app = NSApplication.shared
let appDelegate = AppDelegate()

app.delegate = appDelegate
app.setActivationPolicy(.regular)
app.run()
```

The default storyboard entry was disabled by removing:

```text
INFOPLIST_KEY_NSMainStoryboardFile = Main
```

from `SettingsAppkitDemo.xcodeproj/project.pbxproj`.

Do not blindly copy this into every project. If the target app already has a stable SwiftUI `App`, AppKit app delegate, or storyboard lifecycle, keep that lifecycle and migrate the window/view construction carefully.

## Sidebar Layout

`ViewController.loadView()` uses `FloatingSplitView`, a custom `NSSplitView` whose divider thickness is zero. The left arranged subview is fixed to about `230` points wide.

`makeSidebar()` builds the floating sidebar in layers:

- transparent outer `NSView`
- `SidebarPanelShadowView`
- `SidebarPanelContentView`
- `NSSearchField`
- `NSScrollView`
- `NSTableView`

Keep the shadow and content as separate views:

- `SidebarPanelShadowView` must not clip, because it draws the outer floating shadow
- `SidebarPanelContentView` must clip, because it owns the rounded panel background

Current layout constants that define the floating feeling:

```swift
shadowPanel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8)
shadowPanel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18)
shadowPanel.topAnchor.constraint(equalTo: container.topAnchor, constant: 8)
shadowPanel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)

contentPanel.leadingAnchor.constraint(equalTo: shadowPanel.leadingAnchor, constant: 8)
contentPanel.trailingAnchor.constraint(equalTo: shadowPanel.trailingAnchor, constant: -8)
contentPanel.topAnchor.constraint(equalTo: shadowPanel.topAnchor, constant: 8)
contentPanel.bottomAnchor.constraint(equalTo: shadowPanel.bottomAnchor, constant: -8)
```

The search field starts lower than normal because the traffic-light buttons occupy the top of the sidebar:

```swift
searchField.topAnchor.constraint(equalTo: contentPanel.topAnchor, constant: 60)
```

## Sidebar Shadow

The small floating-layer effect is custom drawn in `SidebarPanelShadowView.draw(_:)`:

```swift
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
```

Tuning rules:

- stronger shadow: increase `0.075` slightly
- softer shadow: decrease `0.075`
- smaller shadow range: reduce `0..<7`
- wider shadow range: increase `0..<7`
- avoid `layer?.shadowOpacity` on the clipped content panel for this effect

The important visual requirement is a subtle, compact, four-sided shadow. If the shadow appears only on the right side, check clipping, neighboring backgrounds, and whether the shadow is being drawn inside a view that is too tight.

## Sidebar Content

`SidebarPanelContentView` owns the visible rounded sidebar background:

```swift
layer?.backgroundColor = NSColor(calibratedWhite: 0.955, alpha: 0.98).cgColor
layer?.cornerRadius = 14
layer?.borderWidth = 0.5
layer?.borderColor = NSColor.white.withAlphaComponent(0.85).cgColor
layer?.masksToBounds = true
```

Keep `masksToBounds = true` here so the search field and table content stay inside the rounded panel. Do not put the outer shadow on this same clipped layer.

## Sidebar Rows And Icons

Sidebar list behavior is built from:

- `SidebarRowView`
- `SidebarItemCellView`
- `SidebarIconView`
- `AccountCellView`
- `UpdateCellView`
- `BadgeView`

`SidebarRowView` draws the selected row manually:

```swift
let selectionRect = bounds.insetBy(dx: 2, dy: 1)
NSColor.controlAccentColor.setFill()
NSBezierPath(roundedRect: selectionRect, xRadius: 7, yRadius: 7).fill()
```

`SidebarIconView` draws the System Settings-like icon:

- 20 x 20 point icon box
- 5 point corner radius
- colored rounded-square background
- white SF Symbol image
- symbol point size around 11

Replace `itemRows` with real categories in the target app, but preserve this icon structure if the visual target is macOS Settings.

## Right Detail Area

`makeDetail()` builds the right panel:

- very light background: `NSColor(calibratedWhite: 0.985, alpha: 1)`
- `NSScrollView` with no drawn background
- `FlippedView` as the document view
- vertical `NSStackView`
- detail content width around `460`
- title label around 22 pt semibold

Keep `FlippedView`. It makes the scroll document use top-origin layout, which keeps the settings content positioned naturally from the top.

## Card Groups

Right-side setting groups are created by:

- `makeGroup(rows:)`
- `RoundedGroupView`
- `makeSettingsRow(title:subtitle:control:)`
- `makeDivider()`

`RoundedGroupView` defines the card look:

```swift
layer?.backgroundColor = NSColor(calibratedWhite: 0.965, alpha: 1).cgColor
layer?.cornerRadius = 10
layer?.borderWidth = 0.5
layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.35).cgColor
layer?.shadowColor = NSColor.black.cgColor
layer?.shadowOpacity = 0.08
layer?.shadowRadius = 10
layer?.shadowOffset = NSSize(width: 0, height: -2)
layer?.masksToBounds = false
```

The shadow is intentionally light. The right-side cards should feel layered, but not like large modal panels.

`makeSettingsRow` uses fixed row width and row heights:

- width: `436`
- normal row height: `38`
- subtitle row height: `56`

If the target project's settings text is longer, adjust row layout before increasing the whole panel width.

## Demo Controls

Current demo controls include:

- `NSSegmentedControl`
- `NSPopUpButton`
- `NSSwitch`
- `ColorDotView`
- `IconPreviewView`
- `IconImageBox`

These are examples, not product requirements. In a real migration, replace them with actual settings controls while keeping the surrounding row and group layout.

## Copy List

For a direct migration, copy or port these pieces:

- `FloatingSplitView`
- `SidebarPanelShadowView`
- `SidebarPanelContentView`
- `SidebarRowView`
- `SidebarIconView`
- `SidebarItemCellView`
- `AccountCellView`
- `UpdateCellView`
- `BadgeView`
- `RoundedGroupView`
- `FlippedView`
- `ColorDotView`
- `IconPreviewView`
- `IconImageBox`
- `makeSidebar()`
- `makeDetail()`
- `makeGroup(rows:)`
- `makeSettingsRow(title:subtitle:control:)`
- `makeDivider()`
- `positionTrafficLightButtons(in:)`

Then replace the demo data, labels, and controls.

## Do Not Copy Blindly

Do not blindly copy:

- placeholder user name or account text
- placeholder software update row
- demo category titles
- demo right-panel settings
- fixed window title
- `main.swift`, unless the target app also needs this manual AppKit entry
- `project.pbxproj` storyboard changes, unless the target app is also moving away from storyboard startup

## Common Failure Cases

If no window appears:

- check whether storyboard startup and manual app entry are conflicting
- check whether `NSApp.setActivationPolicy(.regular)` is called
- check whether the window is retained by a strong property
- check whether `makeKeyAndOrderFront(nil)` is reached

If traffic-light buttons do not move:

- ensure `positionTrafficLightButtons(in:)` runs after `makeKeyAndOrderFront(nil)`
- keep the `DispatchQueue.main.async` delay
- confirm the window uses `.fullSizeContentView`

If the sidebar has no floating shadow:

- confirm `SidebarPanelShadowView` is outside the clipped content view
- confirm the outer container and shadow view are not masking to bounds
- confirm the shadow view has enough inset space to draw outside the panel rect
- tune the custom `draw(_:)` loop instead of only increasing `layer?.shadowOpacity`

If the right cards look too heavy:

- reduce `RoundedGroupView.layer?.shadowOpacity`
- reduce `shadowRadius`
- keep the border subtle

## Verification Checklist

After migration, verify with a real app launch, not only a successful build:

- the app opens exactly one window
- the sidebar appears as a rounded floating panel
- the sidebar shadow is visible on all sides and remains subtle
- the traffic-light buttons sit inside the sidebar panel
- the search field does not overlap the traffic-light buttons
- selected sidebar row is blue and readable
- sidebar icons are colorful with white symbols
- right-side content starts near the top and scrolls normally
- right-side cards have rounded corners, separators, and light depth
- resizing the window does not create overlap or clipped controls

Build command used for this demo:

```sh
xcodebuild -project SettingsAppkitDemo.xcodeproj -scheme SettingsAppkitDemo -configuration Debug -destination 'platform=macOS' -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

Launch command:

```sh
open .build/DerivedData/Build/Products/Debug/SettingsAppkitDemo.app
```

## Known Caveat

This is a hand-built AppKit approximation of macOS System Settings. It does not use Apple's private System Settings implementation.

Judge success by layout, layering, spacing, and native feel. Do not claim pixel-perfect equivalence.
