//
//  HabitWidget.swift
//  HabitWidget
//
//  Created by Riley Smith on 11/27/25.
//

import WidgetKit
import SwiftUI
import AppIntents

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

//    func relevances() async -> WidgetRelevances<Void> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct HabitWidgetEntry: TimelineEntry {
    let date: Date
    
    let tasks: [HabitTask]
    
    static var preview: HabitWidgetEntry {
        let demoTasks: [HabitTask] = [
            .init(id: .init(), name: "Clean the Toilet"),
            .init(id: .init(), name: "Brush Teeth"),
            .init(id: .init(), name: "Make Bed"),
        ]
        return HabitWidgetEntry(date: .now, tasks: demoTasks)
    }
    
    static var current: HabitWidgetEntry {
        let tasks: [HabitTask] = [
            .init(id: .init(), name: "Clean the Toilet"),
            .init(id: .init(), name: "Brush Teeth"),
            .init(id: .init(), name: "Make Bed"),
        ]
        
        return HabitWidgetEntry(date: .now, tasks: tasks)
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

struct HabitWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Habit Task Tracker")
                    .font(.largeTitle)
                    .padding(.bottom, 10)
                Spacer()
                Text(entry.tasks.count, format: .number)
                     .font(.title)
            }
            ForEach(entry.tasks.prefix(7), id: \.id) {task in
                Toggle(isOn: task.isDone, intent: BackgroundIntent(method: "complete", id: task.id)) {
                    Text(task.name)
                        .lineLimit(1)
                }
                .toggleStyle(CheckToggleStyle())
                .frame(maxHeight: 30, alignment: .leading)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemLarge])
    }
}

#Preview(as: .systemLarge) {
    HabitWidget()
} timeline: {
    HabitWidgetEntry.preview
}
