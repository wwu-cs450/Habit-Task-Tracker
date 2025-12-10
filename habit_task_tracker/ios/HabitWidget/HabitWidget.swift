//
//  HabitWidget.swift
//  HabitWidget
//
//  Created by Riley Smith on 11/27/25.
//

import WidgetKit
import SwiftUI
import AppIntents
import Foundation

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> HabitWidgetEntry {
        HabitWidgetEntry.preview
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitWidgetEntry) -> ()) {
        if context.isPreview {
            return completion(HabitWidgetEntry.preview)
        }
        
        completion(HabitWidgetEntry.current)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        if context.isPreview {
            return completion( Timeline(entries: [HabitWidgetEntry.preview], policy: .never))
        }
        
        completion(Timeline(entries: [HabitWidgetEntry.current], policy: .never))
    }
}



struct HabitWidgetEntry: TimelineEntry {
    let date: Date
    
    let tasks: [HabitTask]
    
    let totalTasks: Int
    
    static var preview: HabitWidgetEntry {
        let demoTasks: [HabitTask] = [
            .init(id: "habit-1", name: "Clean the Toilet"),
            .init(id: "habit-2", name: "Brush Teeth"),
            .init(id: "habit-3", name: "Make Bed"),
        ]
        return HabitWidgetEntry(date: .now, tasks: demoTasks, totalTasks: 3)
    }
    
    static var current: HabitWidgetEntry {
        let prefs = UserDefaults(suiteName: "group.com.example.habitTaskTrackerGroup")
        
        let savedData = prefs?.string(forKey: "habits") ?? "[]"
        
        guard let jsonData = savedData.data(using: .utf8) else {
            fatalError("Could not convert string to Data")
        }
        
        let decoder = JSONDecoder()
        
        var tasks: [HabitTask] = []
        do {
             tasks = try decoder.decode([HabitTask].self, from: jsonData)
        } catch {
            print(error.localizedDescription)
        }
        
        let totalTasks = prefs?.integer(forKey: "habitCount")
        
        return HabitWidgetEntry(date: .now, tasks: tasks, totalTasks: totalTasks ?? 0)
    }
}

struct CheckToggleStyle: ToggleStyle {
 func makeBody(configuration: Configuration) -> some View {
  Button {
   configuration.isOn.toggle()
  } label: {
   Label {
    configuration.label
     .strikethrough(configuration.isOn, color: .accentColor)
   } icon: {
    Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
           .foregroundStyle(.red)
     .accessibility(label: Text(configuration.isOn ? "Checked" : "Unchecked"))
     .imageScale(.large)
   }
  }
  .buttonStyle(.plain)
 }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


struct HabitWidgetEntryView : View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            switch family {
            case .systemSmall:
                HStack(alignment: .firstTextBaseline) {
                    Text("Habit Tracker")
                        .font(.default)
                    Spacer()
                    Text("\(entry.tasks.count)")
                        .font(.default)
                }
            default:
                HStack(alignment: .firstTextBaseline) {
                    Text("Habit Task Tracker")
                        .font(.title)
                    Spacer()
                    Text("\(entry.tasks.count)")
                        .font(.title)
                }
                
            }
            Divider()
            ForEach(entry.tasks.prefix(7)) { task in
                            Toggle(isOn: task.isCompleted, intent: BackgroundIntent(method: "complete", id: task.id)) {
                                Text(task.name)
                                    .lineLimit(1)
                            }
                            .toggleStyle(CheckToggleStyle())
                            .padding(.vertical, 8) // Vertical padding for row height
                            .frame(maxWidth: .infinity, alignment: .leading) // Ensure row spans full width
                            .overlay(alignment: .bottom) { // Apply an overlay at the bottom for the border
                                Rectangle() // The border itself
                                    .frame(height: 1) // Set border thickness
                                    .foregroundColor(.gray.opacity(0.3)) // Set border color and opacity
                            }
                        }
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        HStack() {
            
            Spacer()
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
                .frame(maxWidth: .infinity, alignment: .center)
            switch family {
            case .systemLarge:
                Button(intent: BackgroundIntent(method: "task:add", id: "")) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "f73378"))
                .frame(maxWidth: .infinity, alignment: .trailing)
            default:
                EmptyView()
            }
        }
    }
}



struct HabitWidget: Widget {
    let kind: String = "HabitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                HabitWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                HabitWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Tasks Widget")
        .description("Mark off your habits/tasks for today")
    }
}

#Preview(as: .systemLarge) {
    HabitWidget()
} timeline: {
    HabitWidgetEntry.preview
}
