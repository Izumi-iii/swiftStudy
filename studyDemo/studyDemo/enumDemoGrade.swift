//
//  enumDemoGrade.swift
//  studyDemo
//
//  Created by 1-6 on 2026/7/26.
//

import Foundation

//考试成绩等级
func runGrade(){
    enum Grade: Double{
        case excellent = 90.0
        case good = 80.0
        case average = 70.0
        case pass = 60.0
        case fail = 0.0
        
        var description: String{
            switch self{
            case .excellent: return "优秀"
            case .good:return "良好"
            case .average:return "一般"
            case .pass:return "及格"
            case .fail: return "不及格"
            }
        }
        
        //静态方法：根据分数获取等级
        static func from(score: Double) -> Grade {
            switch score {
            case 90...100: return .excellent
            case 80..<90:return .good
            case 70..<80:return .average
            case 60..<70:return .pass
            default: return .fail
            }
        }
    }
    let grade = Grade.from(score: 85)
    print("\(grade.description)(\(grade.rawValue)分以上")
}
