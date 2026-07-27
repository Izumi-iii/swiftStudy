//
//  enumDemoCharacter.swift
//  studyDemo
//
//  Created by wangjie on 2026/7/27.
//

import Foundation

func runCharacter(){
    enum CharacterClass {
        case warrior(weapon: Weapon)
        case mage(element: MagicElement)
        case archer(arrowCount: Int)
        
        enum Weapon: String {
            case sword = "剑"
            case axe = "斧"
            case hammer = "锤"
        }
        
        enum MagicElement: String {
            case fire = "🔥"
            case ice = "🧊"
            case lightning = "⚡️"
        }
        
        var baseAttack: Int {
            switch self{
            case .warrior(let weapon):
                switch weapon {
                case .sword: return 15
                case .axe: return 20
                case .hammer: return 25
                }
            case .mage: return 18
            case .archer(let arrows):
                return arrows > 0 ? 12 : 2
            }
        }
        
        var description: String {
            switch self {
            case .warrior(let weapon):
                return "⚔️ 战士，武器：\(weapon.rawValue)，攻击力：\(baseAttack)"
            case .mage(let element):
                return "🧙 法师，元素：\(element.rawValue)，攻击力：\(baseAttack)"
            case .archer(let arrows):
                return "🏹 弓箭手，剩余箭矢：\(arrows)，攻击力：\(baseAttack)"
            }
        }
        
        var isRanged: Bool{
            switch self {
            case .warrior: return false
            case .mage: return true
            case .archer:return true
            }
        }
        
    }
    
    
    
    
    struct GameCharacter {
        var name: String
        var charClass: CharacterClass
        var health: Int
        
        func display(){
            print("\(name) - \(charClass.description)")
            print("生命值:\(health)")
            print("远程攻击:\(charClass.isRanged ? "是" : "否")")
        }
    }
    
    let warrior = GameCharacter(name: "钢铁侠", charClass: .warrior(weapon: .axe), health: 100)
    let mage = GameCharacter(name: "甘道夫", charClass: .mage(element: .lightning), health: 75)
    let archer = GameCharacter(name:"精灵", charClass: .archer(arrowCount: 20), health: 85)
    
    warrior.display()
    print("--------")
    mage.display()
    print("--------")
    archer.display()
    
}
