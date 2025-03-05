//
//  DreamReminderWidgetExtensionLiveActivity.swift
//  DreamReminderWidgetExtension
//
//  Created by 陈宗伟 on 2025/3/4.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct DreamReminderWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct DreamReminderWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DreamReminderWidgetExtensionAttributes.self) { context in
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

extension DreamReminderWidgetExtensionAttributes {
    fileprivate static var preview: DreamReminderWidgetExtensionAttributes {
        DreamReminderWidgetExtensionAttributes(name: "World")
    }
}

extension DreamReminderWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: DreamReminderWidgetExtensionAttributes.ContentState {
        DreamReminderWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: DreamReminderWidgetExtensionAttributes.ContentState {
         DreamReminderWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: DreamReminderWidgetExtensionAttributes.preview) {
   DreamReminderWidgetExtensionLiveActivity()
} contentStates: {
    DreamReminderWidgetExtensionAttributes.ContentState.smiley
    DreamReminderWidgetExtensionAttributes.ContentState.starEyes
}
