//
//  asyncDemoUserProfile.swift
//  studyDemo
//
//  Created by wangjie on 2026/7/27.
//

//模拟一个 异步加载用户资料页 的过程，并且用 struct 表示用户、订单、最终页面数据。

import Foundation

struct User {
    let id: Int
    let name: String
}

struct Order {
    let id: Int
    let title: String
    let price: Double
}

struct UserProfile {
    let user: User
    let orders: [Order]
    
    var totalPrice: Double {
        var total = 0.0
        for order in orders {
            total += order.price
        }
        
        return total
    }
}

func fetchUser(id: Int) async -> User {
    print("开始加载用户信息")
    
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    
    print("用户信息加载完成")
    
    return User(id: id,name: "Izumi")
}

func fetchOrders(userId: Int) async -> [Order] {
    print("开始加载订单列表")
    
    try? await Task.sleep(nanoseconds: 1_500_000_000)
    
    print("订单列表加载完成")
    
    return [
        Order(id: 1, title: "Swift Book", price: 88),
        Order(id: 2, title: "Mac App", price: 188),
        Order(id: 3, title: "keyboard", price: 388)
        
    ]
}

func loadUserProfile(userID: Int) async -> UserProfile{
    //这两行表示：用户信息和订单列表同时开始加载。
    async let user = fetchUser(id: userID)
    async let orders = fetchOrders(userId: userID)
    
    //如果写成这样
    //let user = await fetchUser(id: userID)
    //let orders = await fetchOrders(userID: userID)
    //就是先等用户加载完，再开始加载订单，速度更慢。
    
    //这里要创建 UserProfile，必须拿到 user 和 orders 的真实结果，所以这里写 await。
    let profile = await UserProfile(user: user, orders: orders)
    
    return profile
}

func runAsyncUserProfileDemo() async {
    print("=== async + struct demo 开始 ===")
    
    let profile = await loadUserProfile(userID: 1001)
    
    print("用户：\(profile.user.name)")
    print("订单数量：\(profile.orders.count)")
    print("订单总价：\(profile.totalPrice)")
    
    print("=== async + struct demo 结束 ===")
}
