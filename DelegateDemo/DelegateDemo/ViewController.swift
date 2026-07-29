//
//  ViewController.swift
//  DelegateDemo
//
//  Created by wangjie on 2026/7/28.
//

import Cocoa

//protocol 意思是定义一个“代理协议”。谁想接收 ButtonPanelView 的按钮事件，谁就要实现这个协议。

//AnyObject 表示这个 delegate 只能由 class 类型实现。
protocol ButtonPanelViewDelegate: AnyObject {
    func buttonPanelViewTapCopy(_ view: ButtonPanelView)
    func buttonPanelViewTapSave(_ view: ButtonPanelView)
}


//定义一个自定义 View，它继承 AppKit 的 NSView。
final class ButtonPanelView: NSView {
    //意思是这个 View 有一个代理。当按钮被点时，它会通知这个 delegate。
    weak var delegate: ButtonPanelViewDelegate?
    //weak 是弱引用，避免 View 和 Controller 互相强引用导致释放不了。
    //? 表示 delegate 可以暂时没有，所以是可选的。
    
    //创建一个 AppKit 按钮
    private let copyButton = NSButton(
        title: "Copy", target: nil, action: nil
    )
    
    private let saveButton = NSButton(
        title: "Save", target: nil, action: nil
    )
    
    //代码创建 ButtonPanelView 时会走这里。
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        buildView()
    }
    
    //Storyboard / XIB 创建 View 时可能走这里。这里我们也调用 buildView()，保证两种创建方式都能把按钮加上。
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildView()
    }
    
    private func buildView() {
        copyButton.target = self
        copyButton.action = #selector(copyButtonClicked)
        
        saveButton.target = self
        saveButton.action = #selector(saveButtonClicked)
        
        
        //创建一个横向容器，把两个按钮排在一起。
        let stackView = NSStackView(views: [copyButton,saveButton])
        stackView.orientation = .horizontal
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    @objc private func copyButtonClicked() {
        print("View: Copy button clicked")
        delegate?.buttonPanelViewTapCopy(self)
    }
    
    @objc private func saveButtonClicked() {
        print("View: Save button clicked")
        delegate?.buttonPanelViewTapSave(self)
    }
}

class ViewController: NSViewController, ButtonPanelViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let buttonPanelView = ButtonPanelView(frame: view.bounds)
        buttonPanelView.translatesAutoresizingMaskIntoConstraints = false
        buttonPanelView.delegate = self
        
        view.addSubview(buttonPanelView)
        
        NSLayoutConstraint.activate([
            buttonPanelView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonPanelView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonPanelView.topAnchor.constraint(equalTo: view.topAnchor),
            buttonPanelView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func buttonPanelViewTapCopy(_ view: ButtonPanelView) {
        print("Controller: received Copy request")
        start("copy")
    }
    
    func buttonPanelViewTapSave(_ view: ButtonPanelView) {
        print("Controller: received Save request")
        start("save")
    }
    
    private func start(_ operation: String) {
        print("Controller: start  \(operation)")
    }
    

}

