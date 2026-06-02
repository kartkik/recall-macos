//
//  ReminderEvent.swift
//  Recall
//
//  Created by twixx  on 30/05/26.
//

import Foundation
import SwiftUI

struct ReminderEvent: Identifiable {
    var id: String
    var title: String
    var isCompleted: Bool
    var startDate: Date?
    var endDate: Date?
    var isReminder : Bool
    var colorName: String
    
    var color: Color {
        switch colorName {
        case "Purple": return Color(red: 0.55, green: 0.36, blue: 0.96)
        case "Blue": return Color(red: 0.23, green: 0.51, blue: 0.96)
        case "Green": return Color(red: 0.18, green: 0.70, blue: 0.44)
        case "Red": return Color(red: 0.92, green: 0.30, blue: 0.30)
        case "Teal": return Color(red: 0.12, green: 0.69, blue: 0.73)
        default: return Color(red: 0.55, green: 0.36, blue: 0.96)
        }
    }
    
}
