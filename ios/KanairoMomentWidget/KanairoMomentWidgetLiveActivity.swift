//
//  KanairoMomentWidgetLiveActivity.swift
//  KanairoMomentWidget
//
//  Created by Timothy Oriedo on 08/06/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct KanairoMomentWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct KanairoMomentWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KanairoMomentWidgetAttributes.self) { context in
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

extension KanairoMomentWidgetAttributes {
    fileprivate static var preview: KanairoMomentWidgetAttributes {
        KanairoMomentWidgetAttributes(name: "World")
    }
}

extension KanairoMomentWidgetAttributes.ContentState {
    fileprivate static var smiley: KanairoMomentWidgetAttributes.ContentState {
        KanairoMomentWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: KanairoMomentWidgetAttributes.ContentState {
         KanairoMomentWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: KanairoMomentWidgetAttributes.preview) {
   KanairoMomentWidgetLiveActivity()
} contentStates: {
    KanairoMomentWidgetAttributes.ContentState.smiley
    KanairoMomentWidgetAttributes.ContentState.starEyes
}
