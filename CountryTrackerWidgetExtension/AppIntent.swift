//
//  AppIntent.swift
//  CountryTrackerWidgetExtension
//
//  Created by Ivan Markin on 07.01.2026.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Travel Stats" }
    static var description: IntentDescription { "Shows your travel stats for the last 365 days." }
}
