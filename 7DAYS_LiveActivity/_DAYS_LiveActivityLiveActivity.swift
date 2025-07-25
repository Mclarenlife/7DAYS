//
//  _DAYS_LiveActivityLiveActivity.swift
//  7DAYS_LiveActivity
//
//  Created by Mclarenlife on 2025/7/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct _DAYS_LiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct _DAYS_LiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: _DAYS_LiveActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension _DAYS_LiveActivityAttributes {
    fileprivate static var preview: _DAYS_LiveActivityAttributes {
        _DAYS_LiveActivityAttributes(name: "World")
    }
}

extension _DAYS_LiveActivityAttributes.ContentState {
    fileprivate static var smiley: _DAYS_LiveActivityAttributes.ContentState {
        _DAYS_LiveActivityAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: _DAYS_LiveActivityAttributes.ContentState {
         _DAYS_LiveActivityAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: _DAYS_LiveActivityAttributes.preview) {
   _DAYS_LiveActivityLiveActivity()
} contentStates: {
    _DAYS_LiveActivityAttributes.ContentState.smiley
    _DAYS_LiveActivityAttributes.ContentState.starEyes
}
