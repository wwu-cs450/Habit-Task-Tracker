//
//  BackgroundIntent.swift
//  Runner
//
//  Created by Riley Smith on 11/27/25.
//

import AppIntents
import Foundation
import home_widget

@available(iOS 17, *)
public struct BackgroundIntent: AppIntent {
    static public var title: LocalizedStringResource = "Complete Task"
    
    @Parameter(title: "Method")
    var method: String
    
    public init() {
        method = "complete"
    }
    
    public init(method: String) {
        self.method = method
    }
    
    public func perform() async throws -> some IntentResult {
        await HomeWidgetBackgroundWorker.run(
          url: URL(string: "habitWidget://\(method)"),
          appGroup: "group.com.example.habitTaskTrackerGroup")

        return .result()
      }
}
