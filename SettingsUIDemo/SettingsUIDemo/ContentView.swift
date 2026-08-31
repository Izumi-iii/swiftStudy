//
//  ContentView.swift
//  SettingsUIDemo
//
//  Created by wangjie on 2026/8/31.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedItem = "外观"
    @State private var searchText = ""
    @State private var appearance = "浅色"
    @State private var glass = "透明"
    @State private var highlightColor = "自动"
    @State private var sidebarIconSize = "中"
    @State private var tintWallpaper = true

    private let items: [SettingsItem] = [
        SettingsItem(title: "Wi-Fi", symbol: "wifi"),
        SettingsItem(title: "蓝牙", symbol: "bolt.horizontal.circle.fill"),
        SettingsItem(title: "网络", symbol: "network"),
        SettingsItem(title: "能耗", symbol: "battery.100percent"),
        SettingsItem(title: "通用", symbol: "gearshape.fill"),
        SettingsItem(title: "菜单栏", symbol: "switch.2"),
        SettingsItem(title: "辅助功能", symbol: "accessibility"),
        SettingsItem(title: "聚焦", symbol: "magnifyingglass"),
        SettingsItem(title: "墙纸", symbol: "atom"),
        SettingsItem(title: "外观", symbol: "circle.lefthalf.filled"),
        SettingsItem(title: "显示器", symbol: "display"),
        SettingsItem(title: "桌面与程序坞", symbol: "dock.rectangle"),
        SettingsItem(title: "Apple 智能与 Siri", symbol: "sparkles")
    ]

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .navigationTitle(selectedItem)
    }

    private var sidebar: some View {
        List(selection: $selectedItem) {
            accountHeader
                .listRowSeparator(.hidden)
                .padding(.vertical, 6)

            HStack {
                Text("今晚安装软件更新")
                Spacer()
                Text("1")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(.red, in: Circle())
            }
            .font(.callout)
            .padding(.vertical, 8)
            .listRowSeparator(.hidden)

            ForEach(items) { item in
                Label(item.title, systemImage: item.symbol)
                    .tag(item.title)
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchText, placement: .sidebar, prompt: "搜索")
        .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 260)
    }

    private var accountHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("王杰")
                    .font(.headline)
                Text("Apple 账户")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var detail: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(selectedItem)
                    .font(.title2.bold())

                if selectedItem == "外观" {
                    appearancePage
                } else {
                    Text("这一页后面再补。")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 18)
            .padding(.bottom, 40)
            .frame(maxWidth: 520, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var appearancePage: some View {
        VStack(alignment: .leading, spacing: 22) {
            SettingsGroup {
                SettingsRow(title: "外观") {
                    Picker("", selection: $appearance) {
                        Text("自动").tag("自动")
                        Text("浅色").tag("浅色")
                        Text("深色").tag("深色")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 170)
                }

                Divider()

                SettingsRow(title: "Liquid Glass", subtitle: "选取喜欢的 Liquid Glass 外观。") {
                    Picker("", selection: $glass) {
                        Text("透明").tag("透明")
                        Text("色调").tag("色调")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
            }

            Text("主题")
                .font(.headline)
                .padding(.leading, 10)

            SettingsGroup {
                SettingsRow(title: "颜色") {
                    HStack(spacing: 13) {
                        AccentDot(style: AnyShapeStyle(AngularGradient(colors: [.red, .yellow, .green, .blue, .purple, .red], center: .center)), selected: true)
                        AccentDot(style: AnyShapeStyle(Color.blue))
                        AccentDot(style: AnyShapeStyle(Color.purple))
                        AccentDot(style: AnyShapeStyle(Color.pink))
                        AccentDot(style: AnyShapeStyle(Color.red))
                        AccentDot(style: AnyShapeStyle(Color.orange))
                        AccentDot(style: AnyShapeStyle(Color.yellow))
                        AccentDot(style: AnyShapeStyle(Color.green))
                        AccentDot(style: AnyShapeStyle(Color.gray))
                    }
                }

                Divider()

                SettingsRow(title: "文本高亮标记颜色") {
                    Picker("", selection: $highlightColor) {
                        Text("自动").tag("自动")
                        Text("蓝色").tag("蓝色")
                        Text("紫色").tag("紫色")
                    }
                    .frame(width: 86)
                }

                Divider()

                SettingsRow(title: "图标与小组件样式") {
                    HStack(spacing: 12) {
                        IconPreview(title: "默认", symbol: "sun.max.fill", selected: true)
                        IconPreview(title: "深色", symbol: "moon.fill")
                        IconPreview(title: "透明", symbol: "cloud.fill")
                        IconPreview(title: "色调", symbol: "cloud.sun.fill")
                    }
                }
            }

            Text("窗口")
                .font(.headline)
                .padding(.leading, 10)

            SettingsGroup {
                SettingsRow(title: "边栏图标大小") {
                    Picker("", selection: $sidebarIconSize) {
                        Text("小").tag("小")
                        Text("中").tag("中")
                        Text("大").tag("大")
                    }
                    .frame(width: 72)
                }

                Divider()

                Toggle("基于墙纸颜色调整窗口背景色调", isOn: $tintWallpaper)
                    .toggleStyle(.switch)
                    .font(.callout)
                    .padding(.vertical, 8)
            }
        }
    }
}

private struct SettingsItem: Identifiable {
    let title: String
    let symbol: String

    var id: String {
        title
    }
}

private struct SettingsGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct SettingsRow<Control: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var control: Control

    init(title: String, subtitle: String? = nil, @ViewBuilder control: () -> Control) {
        self.title = title
        self.subtitle = subtitle
        self.control = control()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 16)
            control
        }
        .font(.callout)
        .padding(.vertical, 8)
    }
}

private struct AccentDot: View {
    let style: AnyShapeStyle
    var selected = false

    var body: some View {
        Circle()
            .fill(style)
            .frame(width: 24, height: 24)
            .overlay {
                if selected {
                    Circle()
                        .stroke(.blue, lineWidth: 3)
                        .frame(width: 30, height: 30)
                }
            }
    }
}

private struct IconPreview: View {
    let title: String
    let symbol: String
    var selected = false

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.title2)
                .frame(width: 36, height: 36)
                .background(.blue.opacity(selected ? 0.18 : 0.08), in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    if selected {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.blue, lineWidth: 3)
                    }
                }

            Text(title)
                .font(.caption)
                .foregroundStyle(selected ? .primary : .secondary)
        }
    }
}

#Preview {
    ContentView()
}
