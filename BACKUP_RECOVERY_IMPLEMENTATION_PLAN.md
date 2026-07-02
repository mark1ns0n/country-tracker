# Backup And Recovery Implementation Plan

This document is an execution contract for any future agent or model working in this repository.
It is written to be followed directly without interpretation, optional detours, or alternative implementation plans.

## Objective

Implement a reliable backup, export, import, and recovery flow for `CountryDaysTracker` so that user history can be preserved and restored even when SwiftData store migration fails.

Follow the steps in order.
Do not skip ahead.
Do not replace scope with alternative solutions.
Do not reinterpret requirements as suggestions.

## Scope

Included:
- Manual JSON export of all user data
- Manual JSON import that fully restores app state
- Automatic pre-recovery backup before destructive recovery actions
- Deterministic validation of backup files
- Settings UI for export/import
- Tests for round-trip restore and recovery behavior

Excluded:
- iCloud sync
- CloudKit
- Multi-device merge
- Encrypted backups
- Scheduled background backups

## Constraints

- Existing user data must be preserved.
- Migration strategy must remain additive-first.
- No destructive operation may run before at least one backup artifact is created.
- Backup format must not depend on SwiftData internal schema details.
- Import must be replace-only, not merge-based.
- UI must not contain backup business logic.

## Step 1. Define Backup Format

Create file:
- `/Users/mark1ns0n/projects/m/country-tracker/CountryDaysTracker/Models/Backup/CountryTrackerBackup.swift`

Add these types:
- `CountryTrackerBackup`
- `BackupMetadata`
- `BackupStayInterval`
- `BackupLocationEventLog`
- `BackupPresenceDay`
- `BackupResidencyProfile`
- `BackupResidencyRule`

Requirements:
- All types must conform to `Codable`.
- `CountryTrackerBackup` must contain:
  - `metadata`
  - `stayIntervals`
  - `locationEventLogs`
  - `presenceDays`
  - `residencyProfile`
  - `residencyRules`
- `BackupMetadata` must contain:
  - `formatVersion`
  - `createdAt`
  - `appVersion`
  - `bundleIdentifier`
- Dates must be serialized as ISO-8601 strings.
- `formatVersion` must be explicit and required.

Acceptance criteria:
- One JSON file fully describes all persisted user data needed to restore the app.
- The format is independent from SwiftData table names and Core Data metadata.

## Step 2. Implement Export Service

Create file:
- `/Users/mark1ns0n/projects/m/country-tracker/CountryDaysTracker/Services/Backup/BackupExportService.swift`

Add functions:
- `makeBackup() throws -> CountryTrackerBackup`
- `writeBackup(to url: URL) throws`

Data sources:
- `StayInterval`
- `LocationEventLog`
- `PresenceDay`
- `ResidencyProfile`
- `ResidencyRule`

Requirements:
- Export must read from `ModelContext`.
- Export must not mutate persistent state.
- JSON output must be pretty-printed.
- Filename format must be:
  - `country-tracker-backup-YYYY-MM-DD-HH-mm-ss.json`

Acceptance criteria:
- Export produces a valid JSON file.
- The JSON file can be decoded back into `CountryTrackerBackup`.

## Step 3. Implement Import Service

Create file:
- `/Users/mark1ns0n/projects/m/country-tracker/CountryDaysTracker/Services/Backup/BackupImportService.swift`

Add functions:
- `readBackup(from url: URL) throws -> CountryTrackerBackup`
- `replaceStoreContents(with backup: CountryTrackerBackup) throws`

Requirements:
- Import mode is replace-only.
- Import must validate the backup before mutating the store.
- Existing data may only be deleted after successful decode and validation.
- Import must restore:
  - all `StayInterval`
  - all `LocationEventLog`
  - all `PresenceDay`
  - `ResidencyProfile`
  - all `ResidencyRule`
- After import, the app must trigger derived-data refresh and widget sync.

Acceptance criteria:
- Exported data can be imported into an empty store and produce equivalent state.
- Importing a valid backup restores the app without manual repair.

## Step 4. Implement Backup Validation

Create file:
- `/Users/mark1ns0n/projects/m/country-tracker/CountryDaysTracker/Services/Backup/BackupValidationService.swift`

Validation rules:
- `formatVersion` must be supported.
- No duplicate `id` values within the same entity type.
- `ResidencyProfile` must be absent or exactly one item.
- If `activeRuleIdentifier` is present, that rule must exist.
- Country codes must be uppercase.
- `entryAt <= exitAt` whenever `exitAt` is non-nil.
- Dates must decode successfully.

Acceptance criteria:
- Invalid backup files fail validation deterministically.
- Import does not proceed on invalid input.

## Step 5. Implement Backup File Management

Create file if needed:
- `/Users/mark1ns0n/projects/m/country-tracker/CountryDaysTracker/Services/Backup/BackupFileService.swift`

Responsibilities:
- Resolve backup directory
- Create backup directory if missing
- Generate filenames
- Return URLs for backup artifacts

Requirements:
- Backup directory must be:
  - `Library/Application Support/Backups/`
- Path logic must exist in one place only.

Acceptance criteria:
- All backup-related file paths are centralized.

## Step 6. Add Pre-Recovery Backup Artifacts

Update file:
- `/Users/mark1ns0n/projects/m/country-tracker/CountryDaysTracker/Storage/AppModelSchema.swift`

Requirements:
- Before destructive recovery, create raw sqlite backup artifacts:
  - `.store`
  - `.store-wal`
  - `.store-shm`
- Additionally, attempt to create a JSON snapshot backup from the readable store content.
- Store recovery backups under:
  - `Library/Application Support/Backups/`
- If JSON backup creation fails but raw sqlite backup succeeds, recovery may continue.
- If no backup artifact can be created, destructive recovery must not run.

Acceptance criteria:
- Recovery creates at least one backup artifact before replacing the store.
- Backup artifacts are inspectable after recovery.

## Step 7. Add Settings UI

Update file:
- `/Users/mark1ns0n/projects/m/country-tracker/CountryDaysTracker/Views/Settings/SettingsView.swift`

Add section:
- `Backup`

Add actions:
- `Export Backup`
- `Import Backup`
- `Last Backup Status`
- `Last Recovery Status`

Requirements:
- Export must use system file exporter.
- Import must use system file importer.
- Import must require explicit destructive confirmation.
- UI must call services only; all logic stays outside the view.

Acceptance criteria:
- User can export a backup file from Settings.
- User can import a backup file from Settings.

## Step 8. Trigger Refresh After Import Or Recovery

After successful import or recovery, emit:
- `.stayIntervalsDidChange`
- `.presenceDaysDidChange`
- `.residencySettingsDidChange`

Also run widget sync.

Acceptance criteria:
- Calendar, stats, residency dashboard, and widget reflect restored data without relaunch requirement.

## Step 9. Tests

Create file:
- `/Users/mark1ns0n/projects/m/country-tracker/CountryDaysTracker/Tests/BackupExportImportTests.swift`

Required tests:
1. `export contains all entity types`
2. `export -> import round trip preserves entity counts`
3. `import rejects unsupported format version`
4. `import rejects broken active rule reference`
5. `manual presence day overrides survive round trip`
6. `recovery writes backup artifacts before destructive action`
7. `real-device legacy store snapshot can be converted into backup data`

Acceptance criteria:
- Backup and restore behavior is covered by deterministic tests.

## Step 10. Cleanup Pass

After implementation:
- Remove duplicated backup path logic
- Remove temporary mapping helpers not needed in final code
- Ensure no business logic lives in SwiftUI views
- Ensure no stale recovery code paths remain unused

## Definition Of Done

The task is complete only when all of the following are true:

- App can export a JSON backup containing all relevant data.
- App can import that backup and fully restore user state.
- Recovery writes backup artifacts before destructive recovery steps.
- Import is replace-only and validated before mutation.
- Round-trip tests pass.
- Real legacy-store recovery no longer presents the user with an empty app state.
- UI for backup/export/import exists in Settings.
- No duplicate backup path or import/export logic remains.

## Execution Order

Follow this exact order:
1. Define backup format
2. Implement export service
3. Implement validation service
4. Implement import service
5. Implement backup file service
6. Add pre-recovery backup artifacts
7. Add Settings UI
8. Add refresh + widget sync hooks
9. Add tests
10. Run cleanup pass

Do not reorder these steps.
