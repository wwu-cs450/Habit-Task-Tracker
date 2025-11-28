//
//  BackgroundIntent.swift
//  Runner
//
//  Created by Riley Smith on 11/27/25.
//

import AppIntents
import Foundation
import home_widget


@available(iOS 26, *)
public struct BackgroundIntent: AppIntent {
    static public var title: LocalizedStringResource = "Complete Task"
    
    static public var supportedModes: IntentModes = [.foreground]
    
    @Parameter(title: "Method")
    var method: String
    
    @Parameter(title: "ID")
    var id: String
    
    public init() {
        method = "complete"
        id = "none"
    }
    
    public init(method: String, id: UUID) {
        self.method = method
        self.id = id.uuidString
    }
    
    public func perform() async throws -> some IntentResult {
        await HomeWidgetBackgroundWorker.run(
          url: URL(string: "habitWidget://\(method)?id=\(id)"),
          appGroup: "group.com.example.habitTaskTrackerGroup")

        return .result()
      }
}
