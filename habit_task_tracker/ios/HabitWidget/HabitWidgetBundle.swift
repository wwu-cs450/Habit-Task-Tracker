//
//  HabitWidgetBundle.swift
//  HabitWidget
//
//  Created by Riley Smith on 11/27/25.
//

import WidgetKit
import SwiftUI

@main
struct HabitWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitWidget()
        HabitWidgetControl()
    }
}
