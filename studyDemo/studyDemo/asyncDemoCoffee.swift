//
//  asyncDemoCoffee.swift
//  studyDemo
//
//  Created by wangjie on 2026/7/27.
//

import Foundation

//async 的意思是：这个函数里面可能会暂停等待别的异步任务完成。
func runAsyncCoffeeDemo() async {
    print("=== async / await demo 开始 ===")
    
    print("\n--- 1. 顺序执行 ---")
    let sequentialCoffee = await makeCoffeeSequential()
    // await 等 makeCoffeeSequential() 返回结果后，再继续往下执行。
    print("顺序执行结果：\(sequentialCoffee)")
    
    print("\n--- 2. 并发执行 ---")
    let concurrentCoffee = await makeCoffeeConcurrent()
    print("并发执行结果：\(concurrentCoffee)")
}

func grindBeans() async -> String {
    print("开始磨咖啡豆")
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    print("咖啡豆磨好了")
    return "咖啡粉"
}

func boilWater() async -> String {
    print("开始烧水")
    try? await Task.sleep(nanoseconds: 1_500_000_000)
    print("水烧好了")
    return "热水"
}

func brewCoffee(beans: String, water: String) async -> String {
    print("开始冲咖啡：\(beans) + \(water)")
    try? await Task.sleep(nanoseconds: 800_000_000)
    print("咖啡冲好了")
    return "一杯咖啡"
}

//顺序执行
// 耗时1.0 秒 + 1.5 秒 + 0.8 秒 = 3.3 秒
func makeCoffeeSequential() async -> String {
    let beans = await grindBeans()
    let water = await boilWater()
    let coffee = await brewCoffee(beans: beans, water: water)
    
    return coffee
    
}

//并发执行
// 耗时 max(1.0 秒, 1.5 秒) + 0.8 秒 = 2.3 秒
func makeCoffeeConcurrent() async -> String {
    async let beans = grindBeans()
    async let water = boilWater()
    //这里不是马上等待结果，而是启动一个异步子任务去磨豆子。同时启动另一个异步子任务去烧水
    
    let coffee = await brewCoffee(beans: beans, water: water)
    //这里真正需要 beans 和 water 的值了，所以 Swift 会等待它们都完成。
    
    return coffee
}



