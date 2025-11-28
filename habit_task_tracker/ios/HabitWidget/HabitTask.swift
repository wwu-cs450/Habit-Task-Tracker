//
//  HabitTask.swift
//  Runner
//
//  Created by Riley Smith on 11/27/25.
//

// simplified struct of our "task"
import Foundation

struct HabitTask: Identifiable, Codable {
    let id: String
    
    let name: String
    
    private(set) var isCompleted: Bool = false
}
