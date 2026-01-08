//
//  CountryTrackerWidgetExtensionLiveActivity.swift
//  CountryTrackerWidgetExtension
//
//  Created by Ivan Markin on 07.01.2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct CountryTrackerWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct CountryTrackerWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CountryTrackerWidgetExtensionAttributes.self) { context in
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

extension CountryTrackerWidgetExtensionAttributes {
    fileprivate static var preview: CountryTrackerWidgetExtensionAttributes {
        CountryTrackerWidgetExtensionAttributes(name: "World")
    }
}

extension CountryTrackerWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: CountryTrackerWidgetExtensionAttributes.ContentState {
        CountryTrackerWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: CountryTrackerWidgetExtensionAttributes.ContentState {
         CountryTrackerWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: CountryTrackerWidgetExtensionAttributes.preview) {
   CountryTrackerWidgetExtensionLiveActivity()
} contentStates: {
    CountryTrackerWidgetExtensionAttributes.ContentState.smiley
    CountryTrackerWidgetExtensionAttributes.ContentState.starEyes
}
