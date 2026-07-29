//
//  ViewController.swift
//  DelegateDemo2
//
//  Created by wangjie on 2026/7/29.
//

import Cocoa

//表示当前界面状态，比如 ready、copying、saving、error。
enum MiniQuickActionStatus {
    case ready
    case copying
    case saving
    case error(String)
}

//是 View 的渲染输入。View 不自己猜状态，外部传什么状态，它就画什么状态。
struct MiniQuickActionViewState {
    let title: String
    let status: MiniQuickActionStatus
}

//是 View 通知 Controller 的出口。View 不执行复制保存，只说：用户点了 Copy、用户点了 Save、用户点了 Retry
//
protocol MiniQuickActionViewDelegate: AnyObject {
    func miniQuickActionViewDidRequestCopy(_ view: MiniQuickActionView)
    func miniQuickActionViewDidRequestSave(_ view: MiniQuickActionView)
    func miniQuickActionViewDidRequestRetry(_ view: MiniQuickActionView)
}

final class MiniQuickActionView: NSView {
    weak var delegate: MiniQuickActionViewDelegate?
    
    //给 MiniQuickActionView 加控件属性
    private let titleLable = NSTextField(labelWithString: "")
    private let statusLable = NSTextField(string: "")
    private let copyButton = NSButton(title: "Copy", target: nil, action: nil)
    private let saveButton = NSButton(title: "Save", target: nil, action: nil)
    private let retryButton = NSButton(title: "Retry", target: nil, action: nil)
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)    //先调用父类 NSView 的初始化方法，让 NSView 自己把基础东西初始化好。
        //frame 不是“框架 framework”，这里是视图的位置和大小。
        buildView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildView()
    }
    
    private func buildView() {
        
        copyButton.target = self
        copyButton.action = #selector(copyButtonClicked)
        
        saveButton.target = self
        saveButton.action = #selector(saveButtonClicked)
        
        retryButton.target = self
        retryButton.action = #selector(retryButtonClicked)
        
        
        //搭界面骨架：有哪些控件、它们怎么排列、字体大概是什么
        titleLable.font = .systemFont(ofSize: 18,weight: .semibold)
        statusLable.textColor = .secondaryLabelColor
        
        let buttoonRow = NSStackView(views: [copyButton,saveButton,retryButton])
        buttoonRow.orientation = .horizontal
        buttoonRow.spacing = 12
        
        let stackView = NSStackView(views: [titleLable,statusLable,buttoonRow])
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    //render(_:) 是“根据当前剧情换台词和灯光”。
    func render(_ state: MiniQuickActionViewState) {
        titleLable.stringValue = state.title
        
        switch state.status {
        case .ready:
            statusLable.stringValue = "Ready"
            statusLable.textColor = .secondaryLabelColor
            copyButton.isEnabled = true
            saveButton.isEnabled = true
            retryButton.isHidden = true
            
        case .copying:
            statusLable.stringValue = "Copying..."
            statusLable.textColor = .secondaryLabelColor
            copyButton.isEnabled = false
            saveButton.isEnabled = false
            retryButton.isHidden = true
            
        case .saving:
            statusLable.stringValue = "Saving..."
            statusLable.textColor = .secondaryLabelColor
            copyButton.isEnabled = false
            saveButton.isEnabled = false
            retryButton.isHidden = true
            
        case .error(let message):
            statusLable.stringValue = message
            statusLable.textColor = .systemRed
            copyButton.isEnabled = true
            saveButton.isEnabled = true
            retryButton.isHidden = false
        }
    }
    
    @objc private func copyButtonClicked() {
        delegate?.miniQuickActionViewDidRequestCopy(self)
    }
    
    @objc private func saveButtonClicked() {
        delegate?.miniQuickActionViewDidRequestSave(self)
    }
    
    @objc private func retryButtonClicked() {
        delegate?.miniQuickActionViewDidRequestRetry(self)
    }
    
    
    
    
}

class ViewController: NSViewController, MiniQuickActionViewDelegate {
    //Controller 长期持有这个 View。
    private let miniView = MiniQuickActionView(frame: .zero)
    //Controller 保存当前业务状态。后面点击 Copy / Save 时，Controller 改这个状态，再调用 render()。
    private var status = MiniQuickActionStatus.ready
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        miniView.translatesAutoresizingMaskIntoConstraints = false
        miniView.delegate = self    //MiniQuickActionView 以后按钮被点，就通知这个 ViewController
        
        view.addSubview(miniView)
        
        NSLayoutConstraint.activate([
            miniView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            miniView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            miniView.topAnchor.constraint(equalTo: view.topAnchor),
            miniView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        render()
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func render() {
        miniView.render(
            MiniQuickActionViewState(title: "Mini Quick Action", status: status)
        )
    }
    
    
    func miniQuickActionViewDidRequestCopy(_ view: MiniQuickActionView) {
        status = .copying
        render()
        
        print("Controller: start copy")
    }
    
    func miniQuickActionViewDidRequestSave(_ view: MiniQuickActionView) {
        status = .saving
        render()
        
        print("Controller: Start save")
        
        //让 Save 不要一直停在 Saving...，而是 1 秒后变成错误状态，并显示 Retry。
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            self.status = .error("Save failed")
            self.render()
        }
    }
    
    func miniQuickActionViewDidRequestRetry(_ view: MiniQuickActionView) {
        status = .ready
        render()
        
        print("Controller: retry")
    }

}

