//
//  AppIntent.swift
//  group.com.mark1ns0n.countrydaystracker
//
//  Created by Ivan Markin on 18.12.2025.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Travel Stats" }
    static var description: IntentDescription { "Shows your travel stats for the last 12 months." }

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}
