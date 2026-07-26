//
//  structDemo_BankAccount.swift
//  
//
//  Created by 1-6 on 2026/7/26.
//
import Foundation


struct BankAccount {
    let accountNumber:String
    var balance: Double {
        didSet{
            print("余额变动：\(oldValue) —> \(balance) ")
        }
    }
    
    var holderName: String
    
    //计算属性
    var isOverdrawn: Bool{
        return balance < 0
    }
    
    //方法
    mutating func deposit(amount:Double){
        guard amount > 0 else {
            print("存款金额必须为正数")
            return
        }
        balance += amount
        print("存入¥"\(amount)")
    }
    
    mutating func withdraw(amount: Double) -> Bool {
        guard amount > 0 && amount <= balance else {
            print("余额不足或金额无效")
            return false
        }
        balance -= amount
        print("取出¥\(amount)")
        return true
    }
    
}


var account = BankAccount(accountNumber: "237874917",balance:1000,holderName:"Jack")

account.deposit(amount:500)
account.withdraw(amount:200)
