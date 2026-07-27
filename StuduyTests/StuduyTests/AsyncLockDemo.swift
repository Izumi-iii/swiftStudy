//
//  AsyncLockDemo.swift
//  StuduyTests
//
//  Created by wangjie on 2026/7/24.
//
import SwiftUI
import Foundation
import Combine

actor AsyncLock {   //actor 可以保护自己的内部状态，避免多个并发任务同时直接修改它的属性。
    private var isLocked = false    //记录当前锁是否已经被占用。false 表示没人拿锁，true 表示已经有人拿锁。
    private var waiters: [CheckedContinuation<Void,Never>] = [] //保存正在等待锁的任务。每个 continuation 可以理解成“一个暂停中的任务的恢复点”。
    
    //如果锁已经被别人拿走，就进入等待。withCheckedContinuation 的作用是：把当前 async 函数暂停，并拿到一个将来可以恢复它的 continuation。
    func acquire() async {  //定义拿锁方法。因为拿锁可能需要等待，所以它是 async。
        if !isLocked {
            isLocked = true
            return
        }
        
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
        
    }
    
    //定义释放锁方法。
    func release() {
        if waiters.isEmpty {
            isLocked = false
        } else {
            waiters.removeFirst().resume()
        }
    }
}

@MainActor  //表示这个类里的代码默认在主线程执行。因为它会更新 UI 状态，比如 number 和 logs。

//定义一个 ViewModel。ObservableObject 表示这个对象可以被 SwiftUI 观察，属性变化时刷新界面。
final class LockDemoViewModel: ObservableObject {
    @Published var number = 0
    @Published var logs: [String] = []
    
    private let lock = AsyncLock()
    
    func runWithoutLock()  {
        number = 0
        logs.removeAll()
        
        for index in 1...5{
            Task {
                let oldValue = number
                logs.append("任务\(index) 读到 number = \(oldValue)")
                
                try? await Task.sleep(nanoseconds: 300_000_000)
                
                number = oldValue + 1
                logs.append("任务\(index) 写入 number = \(number)")
            }
        }
    }
    
    func runWithLock(){
        number = 0
        logs.removeAll()
        
        
        for index in 1...5{
            Task {
                await lock.acquire()
                
                let oldValue = number
                logs.append("任务 \(index) 拿到锁，读到 number = \(oldValue)")
                
                try? await Task.sleep(nanoseconds: 300_000_000)
                
                number = oldValue + 1
                logs.append("任务 \(index) 写入 number = \(number)，释放锁")
                
                await lock.release()
                
                
            }   
        }
    }
}

struct AsyncLockDemo: View {
    @StateObject private var viewModel = LockDemoViewModel()
    
    var body: some View{
        VStack(alignment:.leading,spacing: 16){
            Text("number: \(viewModel.number)")
                .font(.title)
            
            HStack {
                Button("不加锁"){
                    viewModel.runWithoutLock()
                }
                
                Button("加锁"){
                    viewModel.runWithLock()
                }
            }
            
            List(viewModel.logs,id:\.self){ log in
                Text(log)   //每一行日志显示成一段文字。
            }
        }
        .padding()  //给整个界面加内边距。
        .frame(width: 520,height: 420)  //设置窗口内容区域的宽高。
    }
}
