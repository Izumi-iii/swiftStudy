---

excalidraw-plugin: parsed
tags: [excalidraw]

---
==⚠  Switch to EXCALIDRAW VIEW in the MORE OPTIONS menu of this document. ⚠== You can decompress Drawing data with the command palette: 'Decompress current Excalidraw file'. For more info check in plugin settings under 'Saving'



# Code Block

```mermaid
flowchart TD
    subgraph App[SnapioApplication]
        AC[AppCoordinator]
    end

    subgraph Core[SnapioCore]
        PG[PermissionGate]
        PP[PermissionPort protocol]
    end

    subgraph Platform[SnapioPlatform]
        MPC[MacPermissionClient]
    end

    subgraph Pres[SnapioPresentation]
        PVC[PermissionViewController]
    end

    subgraph UI[SnapioUI]
        PV[PermissionView]
        PVS[PermissionViewState]
        PVD[PermissionViewDelegate]
    end

    AC -->|creates| PG
    AC -->|injects MPC| PG
    PG -->|calls| PP
    MPC -->|implements| PP
    PVC -->|subscribes| PG
    PVC -->|render| PV
    PV -->|delegate| PVC
    PVC -->|calls| PG
```


# 截图到输出主流程

```mermaid
sequenceDiagram
actor User
participant StatusItem as StatusItemController
participant App as AppCoordinator
participant Perm as PermissionGate
participant Capture as CaptureCoordinator
participant Backend as CaptureBackend
participant Assets as TransientAssetStore
participant Annotation as AnnotationSessionStore
participant Quick as QuickActionViewController
participant Output as OutputCoordinator
participant Pin as PinSessionStore

User->>StatusItem: 交互截图 / 当前显示器
StatusItem->>App: statusItemDidRequestCapture(intent)
App->>Capture: begin(intent)
Capture->>Perm: refresh + requireCaptureAccess()
Capture->>Backend: prepareDisplay(display)

alt 当前显示器
  Capture->>Assets: insert(frame, owner: quickAction)
  Capture-->>App: resultReady(display)
  App->>Quick: make(context revision 0)
else 交互区域 / 窗口
  Capture-->>App: selecting(session)
  User->>Capture: selection action / commit
  Capture->>Assets: insert(frame, owner: quickAction)
  Capture-->>App: resultReady(region/window)
  App->>Annotation: create(assetID)
  Annotation->>Assets: acquire(editor)
  App->>Assets: release(quickAction)
  User->>Annotation: add/update/undo/redo
  User->>Annotation: Capture
  Annotation->>Assets: storeResolved(document revision)
  App->>Assets: acquire(quickAction)
  App->>Quick: make(context document revision)
  App->>Annotation: close + release(editor)
end

alt Copy / Save / Save As
  Quick->>Assets: resolvedImage(context)
  Quick->>Output: copy/save(resolvedImage)
  Output-->>Quick: success
  Quick->>Assets: release(quickAction)
  Quick->>Capture: dismissResult(session)
else Pin
  Quick->>App: createPin(context)
  App->>Pin: create(imageIdentity)
  Pin->>Assets: acquire(pin)
  App-->>User: show PinWindowController
end
```


# 截图状态机

```mermaid
stateDiagram-v2
[*] --> idle
idle --> checkingPermissions: begin(intent)
checkingPermissions --> preparing: permissions granted
checkingPermissions --> failed: missing permission
preparing --> selecting: interactive
preparing --> capturing: current display
selecting --> capturing: region mouse-up / window click
selecting --> idle: cancel
capturing --> resultReady: asset inserted
capturing --> failed: backend / geometry / permission error
preparing --> failed: backend / display error
resultReady --> idle: quick action closed / output done / annotation canceled
failed --> idle: acknowledgeError
```


# 模块依赖图

```mermaid
classDiagram
direction LR

class AppTarget["Snapio App Target\nAppDelegate + XIB + Assets"]
class SnapioApplication["SnapioApplication\nAppCoordinator"]
class SnapioPresentation["SnapioPresentation\nViewController / WindowController / Routing"]
class SnapioUI["SnapioUI\nNSView / NSControl / Style"]
class SnapioPlatform["SnapioPlatform\nmacOS adapters"]
class SnapioCore["SnapioCore\nbusiness state + ports + models"]

AppTarget --> SnapioApplication
SnapioApplication --> SnapioPresentation
SnapioApplication --> SnapioPlatform
SnapioApplication --> SnapioCore
SnapioPresentation --> SnapioUI
SnapioPresentation --> SnapioCore
SnapioUI --> SnapioCore
SnapioPlatform --> SnapioCore
```


# 类图

```mermaid
classDiagram
direction LR

class AppDelegate {
  +applicationDidFinishLaunching()
  +applicationDidBecomeActive()
  +applicationWillTerminate()
}

class AppCoordinator {
  -permissionGate
  -settingsStore
  -captureCoordinator
  -assetStore
  -pinSessionStore
  -outputCoordinator
  +start()
  +stop()
  +showPermissions()
  +showSettings()
  +statusItemDidRequestCapture(intent)
  +finishAnnotation(result, imageIdentity)
  +createPin(context)
}

class PermissionGate {
  +snapshot
  +refresh()
  +requireCaptureAccess()
}

class PermissionPort {
  <<protocol>>
  +currentSnapshot()
  +request(kind)
  +openSystemSettings(kind)
}

class MacPermissionClient
MacPermissionClient ..|> PermissionPort
PermissionGate --> PermissionPort
AppCoordinator --> PermissionGate

class CaptureCoordinator {
  +state
  +begin(intent)
  +overlaySnapshot(sessionID)
  +sendSelection(action, sessionID)
  +commit(selection, sessionID)
  +cancel()
  +dismissResult(sessionID)
}

class DisplayPort {
  <<protocol>>
  +displayContainingPointer()
}

class DisplayGeometryAdapter
DisplayGeometryAdapter ..|> DisplayPort

class CaptureBackend {
  <<protocol>>
  +prepareDisplay(display)
  +captureWindow(target)
}

class LegacyCaptureBackend {
  <<actor>>
}

class ScreenCaptureKitBackend {
  <<actor>>
}

LegacyCaptureBackend ..|> CaptureBackend
ScreenCaptureKitBackend ..|> CaptureBackend

CaptureCoordinator --> PermissionGate
CaptureCoordinator --> DisplayPort
CaptureCoordinator --> CaptureBackend
CaptureCoordinator --> TransientAssetStore
AppCoordinator --> CaptureCoordinator
AppCoordinator --> DisplayGeometryAdapter
AppCoordinator --> LegacyCaptureBackend
AppCoordinator --> ScreenCaptureKitBackend

class TransientAssetStore {
  <<actor>>
  +insert(frame, origin, owner)
  +source(assetID)
  +resolved(identity)
  +storeResolved(image)
  +acquire(assetID, owner)
  +release(owner)
  +resolvedImage(context)
  +releaseQuickAction(sessionID)
}

class QuickActionAssetAccess {
  <<protocol>>
  +resolvedImage(context)
  +releaseQuickAction(sessionID)
}

TransientAssetStore ..|> QuickActionAssetAccess
AppCoordinator --> TransientAssetStore

class AnnotationSessionStore {
  +state
  +create(assetID, assetStore, renderer)
  +send(action)
  +snapshot()
  +canvasSnapshot()
  +resolvedImage()
  +markSaved()
  +close()
}

class AnnotationDocument {
  +id
  +assetID
  +revision
  +baselineRevision
  +elements
  +selectedID
  +apply(command, newRevision)
  +restore(snapshot)
  +select(id)
  +markSaved()
}

class AnnotationRenderer {
  <<actor>>
  +render(document, source)
}

class AnnotationRendering {
  <<protocol>>
  +render(document, source)
}

AnnotationRenderer ..|> AnnotationRendering
AnnotationSessionStore --> AnnotationDocument
AnnotationSessionStore --> TransientAssetStore
AnnotationSessionStore --> AnnotationRendering
AppCoordinator --> AnnotationSessionStore
AppCoordinator --> AnnotationRenderer

class InlineAnnotationViewController {
  +annotationViewDidRequestCapture()
  +annotationViewDidRequestCancel()
  +annotationCanvasView(didSend)
  -capture()
  -cancel()
}

class CaptureWorkspaceActions {
  <<protocol>>
  +finishAnnotation(result, imageIdentity)
  +cancelAnnotation(result)
}

InlineAnnotationViewController --> AnnotationSessionStore
InlineAnnotationViewController --> CaptureWorkspaceActions
AppCoordinator ..|> CaptureWorkspaceActions
AppCoordinator --> InlineAnnotationViewController

class QuickActionViewController {
  +make(context, ...)
  +dismiss()
  +quickActionViewDidRequestCopy()
  +quickActionViewDidRequestSave()
  +quickActionViewDidRequestSaveAs()
  +quickActionViewDidRequestPin()
}

class QuickActionRouting {
  <<protocol>>
  +createPin(context)
}

QuickActionViewController --> QuickActionAssetAccess
QuickActionViewController --> CaptureCoordinator
QuickActionViewController --> OutputCoordinator
QuickActionViewController --> SettingsStore
QuickActionViewController --> QuickActionRouting
AppCoordinator ..|> QuickActionRouting
AppCoordinator --> QuickActionViewController

class OutputCoordinator {
  <<actor>>
  +copy(image)
  +save(image, destination)
}

class PNGEncoder {
  <<actor>>
  +encode(image)
}

class PasteboardPort {
  <<protocol>>
  +writePNG(payload)
}

class FileWriterPort {
  <<protocol>>
  +writePNG(payload, destination)
}

class PasteboardWriter
class FileWriter {
  <<actor>>
}

PasteboardWriter ..|> PasteboardPort
FileWriter ..|> FileWriterPort
OutputCoordinator --> PNGEncoder
OutputCoordinator --> PasteboardPort
OutputCoordinator --> FileWriterPort
AppCoordinator --> OutputCoordinator

class PinSessionStore {
  <<actor>>
  +create(identity)
  +descriptor(id)
  +resolvedImage(id)
  +close(id)
}

class PinViewController {
  +loadImage()
  +requestClose()
  +pinImageView(didDragBy)
  +pinImageView(didScaleBy)
}

class PinWindowController {
  +present(descriptor, at, in)
  +present(descriptor, near, in)
  +move(by)
  +scale(by)
  +closeAfterSessionRelease()
}

PinSessionStore --> TransientAssetStore
PinViewController --> PinSessionStore
PinWindowController --> PinViewController
AppCoordinator --> PinSessionStore
AppCoordinator --> PinViewController
AppCoordinator --> PinWindowController

class SettingsStore {
  +settings
  +directoryStatus
  +load()
  +setDefaultDirectory(url)
  +revalidateDirectory()
}

class SettingsPersistencePort {
  <<protocol>>
  +load()
  +save(settings)
}

class DirectoryGrantPort {
  <<protocol>>
  +makeReference(url)
  +validate(reference)
  +withAccess(reference, operation)
}

class UserDefaultsSettingsPersistence {
  <<actor>>
}

class BookmarkDirectoryClient {
  <<actor>>
}

UserDefaultsSettingsPersistence ..|> SettingsPersistencePort
BookmarkDirectoryClient ..|> DirectoryGrantPort
SettingsStore --> SettingsPersistencePort
SettingsStore --> DirectoryGrantPort
AppCoordinator --> SettingsStore

class ShortcutCoordinator {
  +state
  +activeShortcut
  +restoreRegistration(shortcut)
  +updateShortcut(shortcut)
  +unregister()
}

class GlobalShortcutPort {
  <<protocol>>
  +register(shortcut)
  +unregister(id)
}

class CarbonHotKeyClient

CarbonHotKeyClient ..|> GlobalShortcutPort
ShortcutCoordinator --> GlobalShortcutPort
ShortcutCoordinator --> SettingsStore
AppCoordinator --> ShortcutCoordinator

AppDelegate --> AppCoordinator
```

# Excalidraw Data

## Text Elements
AppDelegate.swift ^a5CiWnsI

启动时他只做三件事 ^hhyNmdRf

真正的对象创建发生在这里 ^AUz0pBp9

这里会创建： ^oKQXixdn

PermissionGate ^xLTKzBTW

SettingsStore ^12E1zxd1

CaptureCoordinator ^64SlkdJa

TransientAssetStore ^rj8kcMFJ

AnnotationRenderer ^fdd7HxYM

OutputCoordinator ^iVSfJhlx

PinSessionStore ^LJCWcayV

各种 macOS Platform adapter ^udM0ag5l

这叫 composition root， ^KJ19sQ9t

也就是“整个应用唯一负责组装依赖的地方”。 ^3o51Tqr1

创建 AppCoordinator ^jBHZ1OVu

调用 start() ^pa9Y644A

应用退出时调用 stop() ^G8Kxj9sO

AppCoordinator ^y7sFTwme

定义 Core、Platform、UI、Presentation、Application ^ZI6L7zAV

五个模块及四个测试 target 的依赖关系。 ^YF7LX9SS

Package.swift ^VMyYXlJ1

products: [ ^pLvfCGIh

.library(name: "SnapioApplication" ^41DUuFjT

products 表示这个包对外提供什么可链接
的构建产物。
import SnapioApplication可以这样进
行调用 ^dnjl0WCK

各种targets
SnapioCore ^6uo1wT62

SnapioUI ^AgU55byZ

SnapioPlatform ^7ypD1aAK

SnapioPresentation ^IMgFeWH8

SnapioApplication ^14EhElwE

定义 Core 模块 ^LbfZLJni

因为没有写 dependencies，所以它不依赖包内其他模块。
SwiftPM 默认从下面的目录查找源码：
Sources/SnapioCore/ ^aVmVcVLL

这些模块依赖 Core ^eIwy4KeH

它负责实现 Core 定义的系统能力接口 ^Fvz10EDd

它主要包含：AppKit View、自定义 Control、
不可变 ViewState、语义动作、视觉样式 ^xkAPiRsd

最上层的应用组装模块，他依赖于
前三者，并且把他们组装起来 ^vuHa99Em

它不依赖 SnapioPlatform，因此窗口控制器不会直接创建或调用具体的系统 adapter。 ^Fwuy7cys

它主要包含：
NSViewController、NSWindowController
状态栏菜单控制器、路由、系统面板封装
Core 状态到 UI ViewState 的投影 ^jMivW2fq

Core 定义 PermissionClient 接口
          ↑
Platform 提供 MacPermissionClient 实现
          ↑
AppCoordinator 创建实现并注入 Presentation ^syKhQ1Ak

例如 ^5NxEkUSm

SnapioCore ^NEuzQQ2s

Core 保存业务数据、状态和规则，不应依赖 AppKit。 ^0afywIOs

Shared ^U1BuNaXU

公共基础类型 ^hOnwHQf9

Identifiers ^FWlj3gMf

AsyncLock ^GIMpych8

GeometryTypes ^1fGV7aoi

定义了一组“强类型标识符”。它们用于区分截图会话、
图片资产、标注文档、显示器、窗口等对象。
核心目的可以概括为：
即使底层都是 UUID 或整数，也不允许不同含义的 ID 被意外混用。 ^VC4aqZns

区分 AppKit 全局坐标、
Quartz 全局坐标、
显示器局部坐标和图片像素坐标。 ^sehAJrhq

Point2<Space>    → 带坐标空间的 point 点
PointRect<Space> → 带坐标空间的 point 矩形
PixelPoint       → 图片中的像素点
PixelSize        → 图片的像素尺寸
PixelRect        → 图片中的像素矩形 ^lOJcjZ78

Permissions ^nnFkcGku

权限 ^IasgmeqX

PermissionModels ^f0c0ekzj

PermissionGate ^XTekKsPh

定义了 Snapio 权限系统的公共数据类型、错误类型和系统能力接口。 ^c7dPRR1o

是 Snapio 权限系统的协调层，夹在 Platform 的具体实现和 UI/Presentation 之间。
它做四件事：管理当前权限快照、串行化并发检查、
通过 @Published 驱动界面刷新、对外提供一个同步的"门禁"检查。 ^GXEde6mY

PermissionGate 是权限状态的唯一协调者——它用 AsyncLock 保证检查串行，用引用计数保证 isChecking 正确，用 @Published 驱动界面刷新，用 requireCaptureAccess() 提供截图前的同步门禁。 ^eUaeF8sU

全局快捷键 ^EqlGMElw

Shortcuts ^kz9YhKUE

Settings ^3cylKl1Q

设置 ^xHk7atqy

ShortcutModels ^UfKkQpKM

ShortcutCoordinator ^Vz9PALSy

定义按键、修饰键、注册 ID、快捷键状态、错误和系统端口。 ^67qKnCpm

负责快捷键注册事务：先注册新值、保存，再注销旧值；失败时回滚。 ^EpATV9PI

SettingsModels ^2FtURZH2

定义应用设置、目录引用、目录状态、错误以及持久化和目录授权协议。 ^lTOGwybV

加载和保存设置，设置、清除、重新验证默认保存目录。 ^BPnuaxC9

SettingsStore ^wbewenfU

：截图与选区 ^5MZcKfhr

Capture ^Ro2ne5AT

CaptureModels ^LBuXwU3J

截图领域对象：显示器、窗口目标、捕获帧、冻结准备结果、选择结果和错误。 ^CjGBf56Q

定义了截图流程中所有核心数据类型，涵盖了从"准备截图"到"得到结果"、以及"出错"的完整生命周期。 ^R9NEI9YT

CapturePorts ^vI2FvRW9

定义获取显示器和执行截图的系统能力协议。 ^4IruKJha

定义了 Core 层对截图能力的抽象接口。只有两个协议，但它们是截图流程中 Core 和 Platform 之间的契约边界 ^kp9dzSyz

Snapio 核心链路 ^QVBdIc7H

触发入口 ^Y8ERiGYU

权限门控+显示器准备 ^aHr0dBcW

选区or窗口 ^BHFtB9Vr

创建内存资产 ^yFr8N2bh

标注 ^4BRG7w2s

快捷浮层 ^jKIYuzSp

创建内存资产 ^TeacWq3j

窗口或区域 ^4nJUPdvq

显示器全屏 ^YVdis24l

输出 ^UpSyqoo4

冻结显示器 ^lnW2CV1V

静态捕获 ^cLVUHyL7

渲染当前 revision 为 ResolvedImage ^m8o3dYlH

ResolvedImage ^oFljC4eC

App 启动后，[AppDelegate.swift (line 17)](/Users/wangjie/dddd/Snapio/Snapio/AppDelegate.swift:17) 创建 AppCoordinator 并调用 start()。
真正的组合根在 AppCoordinator.swift:65)：这里注入 PermissionGate、SettingsStore、TransientAssetStore、CaptureCoordinator、AnnotationRenderer、OutputCoordinator、PinSessionStore。 ^YYeyBpMb

触发来源有两个： ^mYvlGPcK

状态栏菜单：Capture… 和 Capture Current Display 分别转成 .interactive 与 .currentDisplay，见 [StatusItemController.swift (line 112)](/Users/wangjie/dddd/Snapio/Packages/SnapioKit/Sources/SnapioPresentation/StatusItem/StatusItemController.swift:112)。 ^VdoUehS2

全局快捷键：ShortcutCoordinator 回调里调用 attemptCapture(.interactive)，见 [AppCoordinator.swift (line 20)](/Users/wangjie/dddd/Snapio/Packages/SnapioKit/Sources/SnapioApplication/AppCoordinator.swift:20)。 ^D51MmyZj

TransientAssetStore 管理截图图片在内存里的生命周期 ^yOJVSjT5

两个重要概念
 ^lZqn471Z

SourceAsset = 原始截图 ^t33YdXQ0

ResolvedImage = 可以输出的最终图 ^MDoXhXbS

owner 是生命周期的关键 ^bLj2GmhO

当前显示器截图：

insert quickAction
→ QuickAction
→ Copy / Save / Close
→ release quickAction
→ destroy ^ecstfq9l

交互截图：

insert quickAction
→ create AnnotationSession
→ acquire editor
→ release quickAction
→ Annotation editing
→ render ResolvedImage
→ acquire quickAction
→ close AnnotationSession / release editor
→ QuickAction
→ release quickAction
→ destroy ^Y1DDiAhH

当前显示器截图 + Pin：

insert quickAction
→ QuickAction
→ Pin acquire pin
→ release quickAction
→ PinWindow still alive
→ close pin
→ release pin
→ destroy ^O0uJizfH

AppCoordinator ^UWdYZtA8

@MainActor：这个类默认在主线程执行。因为它大量操作 AppKit 对象，比如 NSApp、NSWindow、NSAlert、状态栏菜单，这些都必须在主线程。

public：因为 SnapioApplication 是 Swift Package 里的 library，外面的 App target 需要 import 它并创建 AppCoordinator。

final：不允许继承。Coordinator 通常是具体组合对象，不希望子类改生命周期行为。

NSObject：为了和 AppKit / Objective-C 运行时对象配合。它本身不一定非要继承 NSObject，但这里和 AppKit 风格一致。 ^gugRKLFQ

注意一个关键设计：这些对象不是散落在各个 ViewController 里 new 出来的，而是在 AppCoordinator 里集中创建、集中注入。这就是文档里说的“只有 AppCoordinator 可以选择并注入具体 Platform 实现”。 ^ZEx7c1Sd

这段很重要。CaptureCoordinator 面向的是 Core 里的 CaptureBackend 协议，但具体用哪个 macOS 后端，由 App 层决定： ^tKIVN4NL

macOS 14+：ScreenCaptureKitBackend ^ibOpf7aU

macOS 11-13：LegacyCaptureBackend ^sbGvxMtp

这就是 Snapio 的依赖方向：Core 不知道 AppKit / ScreenCaptureKit 怎么接，Platform 提供实现，AppCoordinator 负责把实现塞进去。 ^S7T0uvGL

这里启动三件事： ^0Lnpd57m

防止重复启动：guard !isStarted else { return } ^IkFHnSZq

设置为菜单栏应用：NSApp.setActivationPolicy(.accessory) ^2WAETLDF

安装状态栏菜单：statusItemController.install() ^RcNbyK5F

PermissionGate ^5MwuInTs

是 Snapio Core 里的权限状态门：它不直接问 macOS 权限，而是通过 PermissionPort 间接查询；它负责保存当前权限快照、发布状态变化、阻止没有权限时开始截图。 ^t200ZAsh

@MainActor：这个对象的公开操作默认在主线程执行。因为它的状态会被 AppCoordinator、权限窗口、菜单栏 UI 观察，和 UI 更新关系很近。 ^EdArav8g

public：外部模块能用它。比如 SnapioApplication 里的 AppCoordinator 会创建它。 ^a0L1tM10

final：不能被继承。 ^3vtKZaZk

ObservableObject：这是 Combine / SwiftUI 生态里的“可观察对象”协议。虽然 Snapio UI 用 AppKit，不用 SwiftUI，但 Combine 仍然可以用这个机制来发布状态变化。 ^ZV0POfdF

这里体现 Snapio 的架构边界。 ^pduZ1H57

Core 只定义“我需要什么能力”： ^iEnipKCg

查询当前权限 ^qACVk04K

请求某种权限 ^qBDf2HKB

打开系统设置 ^lFSXmz85

但 Core 不知道这些能力在 macOS 上怎么实现。 ^3gkI3GoD

真正实现是在 Platform 里： ^9rLTtYRC

PermissionGate 依赖 PermissionPort 协议 ^pbFHvNUg

MacPermissionClient 实现 PermissionPort 协议 ^MIaTCfLh

AppCoordinator 把 MacPermissionClient 注入 PermissionGate ^FgK7dDXC

这就是“Core 不直接碰 macOS API”的具体体现。 ^QQ5AZ9fP

## Element Links
R3ICQ8ND: [[Excalidraw/SnapioStudy.md#Code Block]]

wNxRWAzG: [[Excalidraw/SnapioStudy.md#截图到输出主流程]]

RB0IZ4Mt: [[Excalidraw/SnapioStudy.md#截图状态机]]

uMxoDeGA: [[Excalidraw/SnapioStudy.md#模块依赖图]]

FZzF6KAb: [[Excalidraw/SnapioStudy.md#类图]]

## Embedded Files
e55ad25cad237b42eda1d7f72ae5712db4f6d880: [[Pasted Image 20260720152708_647.png]]

8e4e3578f36248c0815e2d8cad3d3fd96e468d50: [[Pasted Image 20260720162332_147.png]]

ce831024f791e2d70e5364880b08b4fbd4bc46b8: [[Pasted Image 20260720171251_933.png]]

163c2da495a82e5a3dc86d5b8b0790fdf4e1746b: [[Pasted Image 20260721092738_676.png]]

7a9454453713cde0c0424c8c4a19ed9a502ee517: [[Pasted Image 20260721100209_049.png]]

c11b578dba24f72a8017da094f1ff1d8d0e2d700: [[Pasted Image 20260721101057_152.png]]

648d88994ea800d0cafe32fc5b43e5dee772ff00: [[Pasted Image 20260721102100_848.png]]

76daffd546bc20c437e24b2a044812d8b7341785: [[Pasted Image 20260722145855_134.png]]

9a68e13f255e33194c80339d87420c3119d6df2b: [[Pasted Image 20260722150017_237.png]]

55294f431e343db508b7d85b670cacaa9e52d2ee: [[Pasted Image 20260722150738_838.png]]

bab3f9794906c3cf331362f2ff97fd8e56e877e4: [[Pasted Image 20260722150800_049.png]]

0f4a1008bf0a25a535b8318260bc65489b43d55d: [[Pasted Image 20260722151002_167.png]]

e78c1639d1f38dc06246dc3605f81144fcb46800: [[Pasted Image 20260722151224_520.png]]

9eaa0b1453ab3e4ebe05fd0a753ec6d31d29fc42: [[Pasted Image 20260722151516_375.png]]

0846c53e4a9ba2426a5a06367ef8a95bd481c6f1: [[Pasted Image 20260722151711_148.png]]

235eb6633d2b7de48d139053a5d3e3299ed0c53c: [[Pasted Image 20260722153559_838.png]]

2ef5b0d30ac25db6894a5a33ffe45e5f83186a67: [[Pasted Image 20260722153633_277.png]]

f842ad3b3aaab0024dcd122c948e77cf5a08a450: [[Pasted Image 20260722153652_458.png]]

6df848f0e0bf6297924728b49b78a7fe75822df9: [[Pasted Image 20260722153737_536.png]]

fb6aba84ed804519c0af5173a59807b953072bef: [[Pasted Image 20260722153800_028.png]]

e7b114376b3f395885711ec09aedb56c481929d8: [[Pasted Image 20260722153909_905.png]]

2ae9c2cf0d4b006332b98676691ac53a70e1c713: [[Pasted Image 20260722160211_890.png]]

62e7e0f12dc4f980ac684cd3b8caf98385273f12: [[Pasted Image 20260723110954_156.png]]

b9ef4e608c506f94e6cc4e6c0272ff8c2350d586: [[Pasted Image 20260723111011_224.png]]

2bdb3b702b0900562229ef5eefa3850e3f6374cf: [[Pasted Image 20260723150822_810.png]]

a6f8676aab37d018e597cec96514dacb1af4aed2: [[Pasted Image 20260723150924_365.png]]

75348674a318ca560bf1cedccdbc69be878d5dea: [[Pasted Image 20260723150941_437.png]]

d63570f310d5918de064d72151fa2cc417322901: [[Pasted Image 20260723151436_535.png]]

9f6eab5aa6e5fcc250be16734b25c543237816fd: [[Pasted Image 20260723152204_484.png]]

5b6c45261deb4a190da89bfb8dbee67eaf839a92: [[Pasted Image 20260723152631_284.png]]

7d26e1b53b4d086e541edeac9416a00aa0563a13: [[Pasted Image 20260723173819_118.png]]

a0e54779d2cfc5f119c71daf52f46da5e0947680: [[Pasted Image 20260723174229_566.png]]

98fb72657b735ca75837f87cea3de1040db1fe27: [[Pasted Image 20260723174254_471.png]]

9ae21f1ac179a9d24b0f0b379a51ab8f16d090b6: [[Pasted Image 20260723174331_024.png]]

d05b94b6abb7c818fa77d4d7984411ff1b9698c4: [[Pasted Image 20260723174838_311.png]]

a9764cab5e20f6167ddfda167dbd754d6bbc2123: [[Pasted Image 20260723174924_024.png]]

95e00c493af3badd9b198200e72fd23a6aca990b: [[Pasted Image 20260723175130_286.png]]

%%
## Drawing
```compressed-json
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
```
%%