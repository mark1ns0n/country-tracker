//
//  AppMigrationPlan.swift
//  CountryDaysTracker
//
//  Created on 15 March 2026.
//

import SwiftData

enum AppSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            StayInterval.self,
            LocationEventLog.self,
        ]
    }
}

enum AppSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            StayInterval.self,
            LocationEventLog.self,
            PresenceDay.self,
            ResidencyProfile.self,
            ResidencyRule.self,
        ]
    }
}

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            AppSchemaV1.self,
            AppSchemaV2.self,
        ]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: AppSchemaV1.self,
                toVersion: AppSchemaV2.self
            )
        ]
    }
}
