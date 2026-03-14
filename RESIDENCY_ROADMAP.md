# Residency Risk Implementation Spec

## 1. Document Purpose

This document is an execution specification for future work on this project.

It is written for implementation by an engineering agent or developer.

This document must be followed literally.

Do not reinterpret the product goal.
Do not replace the scope with a broader travel-tracker scope.
Do not introduce alternative domain models unless this document explicitly allows it.

## 2. Primary Product Goal

The application must become a residency risk planner for the user's home country.

For the current intended use case, the app must answer these questions:

1. How many days has the user spent in Russia within the current rolling window?
2. How many more days can the user safely spend in Russia before crossing the configured threshold?
3. If the user enters Russia on a chosen date, how long can they stay before crossing the threshold?
4. When can the user next enter Russia safely, and for how long?

The app is not allowed to treat this as a generic "travel stats" feature.
Travel history exists only as input for residency-risk decisions.

## 3. Scope Definition

### In Scope

- Add a first-class home-country concept.
- Add rule-driven residency evaluation.
- Add day-based presence storage derived from existing interval history.
- Add migration support for existing user data.
- Add scenario planning for future trips.
- Add UI that exposes risk and safe-stay information.

### Out of Scope

- Replacing location tracking with a different tracking system.
- Deleting the existing interval model.
- Rewriting the entire UI before the new domain layer exists.
- Adding unrelated country-group rules unless explicitly added later.
- Legal interpretation beyond the configured numerical rule.

## 4. Existing Data Must Be Preserved

The project already has a non-trivial production database.

This is a hard requirement:

- Existing `StayInterval` records must be preserved.
- Existing `LocationEventLog` records must be preserved.
- Existing user history must remain readable after migration.
- Existing app functionality must continue to compile and run during the transition.

This is forbidden:

- destructive migrations
- silent deletion of old records
- changing the meaning of existing `StayInterval` fields
- one-time transformations that cannot be re-run safely

## 5. Required Domain Model

The implementation must use the following layered model.

### Layer A. Raw Event Layer

Source:

- `LocationEventLog`

Purpose:

- debugging
- audit trail
- evidence of how history was derived

Rules:

- do not use this layer directly for residency evaluation
- do not delete it

### Layer B. Interval Layer

Source:

- `StayInterval`

Purpose:

- historical record of country transitions
- source of truth for automatic country tracking

Rules:

- keep this model intact
- continue writing new intervals here
- do not overload it with residency-specific fields

### Layer C. Presence-Day Layer

New model required:

- `PresenceDay`

Purpose:

- normalized day-based representation of presence in a country
- canonical input for residency calculations

Required minimum fields:

- `id`
- `date`
- `countryCode`
- `source`
- `isManualOverride`
- `updatedAt`

Optional fields allowed:

- `notes`
- provenance fields for interval linkage

Rules:

- `PresenceDay` is derived data
- it must be rebuildable from `StayInterval`
- it must support future manual overrides

### Layer D. Rule Layer

New model required:

- `ResidencyProfile`
- `ResidencyRule`

Purpose:

- represent the configured home country
- represent the rule used to evaluate risk

Required `ResidencyProfile` fields:

- `id`
- `homeCountryCode`
- `activeRuleID` or equivalent stable link
- `updatedAt`

Required `ResidencyRule` fields:

- `id`
- `jurisdictionCode`
- `windowKind`
- `windowLengthDays`
- `thresholdDays`
- `safeLimitDays`
- `isEnabled`
- `title`

Rules:

- do not hardcode the home country in UI logic
- do not hardcode the threshold directly inside views

## 6. Required Services

The implementation must add the following services.

### 6.1 PresenceDayBuilder

Responsibilities:

- read `StayInterval`
- produce deterministic `PresenceDay` output
- support full rebuild
- support partial rebuild later if needed

Rules:

- deterministic output for the same inputs
- idempotent rebuild
- no duplicate `PresenceDay` rows after rerun

### 6.2 ResidencyEngine

Responsibilities:

- evaluate current risk as of a given date

Required inputs:

- presence days
- residency rule
- evaluation date

Required outputs:

- `daysUsed`
- `daysRemaining`
- `thresholdDays`
- `isThresholdExceeded`
- `breachDateIfStayFromToday`
- `nextSafeEntryDate`
- `maxSafeStayIfEnterToday`

Rules:

- this engine must not depend on SwiftUI
- this engine must not read directly from views
- this engine must not depend on widget code

### 6.3 ScenarioEngine

Responsibilities:

- evaluate a proposed future trip

Required inputs:

- current presence days
- active rule
- proposed entry date
- proposed exit date
- target country

Required outputs:

- `isSafe`
- `daysUsedAfterScenario`
- `daysRemainingAfterScenario`
- `breachDate`
- `maxSafeStayForEntryDate`

Rules:

- this engine must be separate from the current-state engine
- it must simulate the future without mutating persisted history

## 7. Required Migration Strategy

The migration must be executed in phases exactly in the order below.

## Phase 1. Additive Schema Only

### Required work

- add new schema objects for `ResidencyProfile`
- add new schema objects for `ResidencyRule`
- add new schema objects for `PresenceDay`
- add versioned schema and migration support

### Forbidden work

- no destructive changes
- no rewriting old rows
- no changing old field meaning

### Acceptance criteria

- existing app data remains readable
- existing app still builds and runs
- old interval-based UI still works

## Phase 2. Backfill Pipeline

### Required work

- implement `PresenceDayBuilder`
- implement a backfill service that rebuilds `PresenceDay` from `StayInterval`
- make the backfill idempotent

### Hard requirements

- rerunning backfill must not create duplicates
- backfill must be safe after app restart
- backfill must be callable again if derivation logic changes

### Acceptance criteria

- a database with historical `StayInterval` rows produces valid `PresenceDay` rows
- rerunning the same backfill yields the same final state

## Phase 3. Parity Validation

### Required work

- compare old interval-derived day totals with new presence-day totals
- compare visited-country results for representative ranges
- compare rolling-window totals for the home country

### Rules

- do not switch the primary UI to presence-day logic before parity is proven

### Acceptance criteria

- interval-based and presence-day-based calculations match for tested scenarios

## Phase 4. Residency Engine

### Required work

- implement `ResidencyEngine`
- add unit tests for current-state evaluation

### Acceptance criteria

- engine returns correct values for configured test fixtures
- engine can answer current home-country usage and remaining safe days

## Phase 5. Dashboard UI

### Required work

- add a dedicated residency-risk dashboard

### Required dashboard fields

- home country code
- days used in current rolling window
- safe days remaining
- breach date if staying from today
- next safe entry date
- max safe stay if entering today

### Rules

- this becomes the primary value screen
- generic travel stats must not remain the only top-level story

### Acceptance criteria

- a user can open the app and immediately know whether going home is currently safe

## Phase 6. Scenario Planner

### Required work

- add a planner for a future trip

### Required planner inputs

- entry date
- exit date
- destination country

### Required planner outputs

- safe or unsafe result
- days used after trip
- days remaining after trip
- first breach date if applicable
- max safe stay for that entry date

### Acceptance criteria

- a user can model a trip home before booking it

## Phase 7. Manual Correction Layer

### Required work

- add a mechanism for overriding derived day assignments

### Rules

- manual corrections must not destroy raw history
- manual corrections must override derived output deterministically

### Acceptance criteria

- user can correct a bad day assignment
- recalculation still produces consistent risk numbers

## 8. Time and Day Boundary Rules

These rules must be explicitly defined in code before final residency evaluation is trusted.

The implementation must not leave these ambiguous.

Required explicit decisions:

1. What timezone defines a day boundary for residency counting?
2. How is a day counted if two countries are visited on the same date?
3. How is the current day treated for an open interval?
4. How are delayed location events reconciled with already-derived days?

Rules:

- one shared domain rule must exist
- views must not implement their own day-boundary logic
- widget logic must reuse the same day-boundary decisions

## 9. Required UI Changes

The following UI changes are mandatory.

### Settings

Must include:

- home country configuration
- active residency rule display
- explanation of what the app optimizes for

### Dashboard

Must prioritize:

- residency risk over generic top-countries stats

### Planner

Must provide:

- future-trip simulation for the home country use case

### Widget

The widget must eventually stop prioritizing generic "top countries" output.

Future target widget content:

- days in home country in rolling window
- safe days remaining
- safe-until date

Do not implement this widget change before the domain layer is stable.

## 10. Required File Structure

Use this structure unless there is an implementation-specific reason not to.

- `CountryDaysTracker/Models/PresenceDay.swift`
- `CountryDaysTracker/Models/ResidencyProfile.swift`
- `CountryDaysTracker/Models/ResidencyRule.swift`
- `CountryDaysTracker/Services/PresenceDayBuilder.swift`
- `CountryDaysTracker/Services/ResidencyEngine.swift`
- `CountryDaysTracker/Services/ScenarioEngine.swift`
- `CountryDaysTracker/Services/Migration/PresenceDayBackfillService.swift`
- `CountryDaysTracker/ViewModels/ResidencyDashboardViewModel.swift`
- `CountryDaysTracker/ViewModels/ScenarioPlannerViewModel.swift`
- `CountryDaysTracker/Views/Residency/ResidencyDashboardView.swift`
- `CountryDaysTracker/Views/Residency/ScenarioPlannerView.swift`

This is a requirement for clarity and maintainability.

## 11. Test Requirements

The following tests are mandatory.

### Presence-Day Tests

- interval spanning one day
- interval spanning multiple days
- open interval ending today
- two-country same-day case
- deterministic rebuild
- idempotent rebuild

### Residency Engine Tests

- zero home-country days
- days below safe limit
- exactly at threshold minus one
- exactly at threshold
- over threshold
- days falling out of rolling window tomorrow

### Scenario Engine Tests

- safe short trip
- unsafe long trip
- breach in middle of trip
- delayed safe re-entry

### Migration Tests

- database with existing interval history upgrades successfully
- backfill creates presence days from historical intervals
- rerunning migration/backfill does not duplicate derived rows

No implementation is complete without these tests.

## 12. Implementation Rules

The following rules are mandatory during execution.

1. Do not delete or repurpose `StayInterval`.
2. Do not embed residency thresholds inside SwiftUI views.
3. Do not let widget code define separate business rules.
4. Do not switch the app to presence-day risk logic before parity tests pass.
5. Do not add manual correction before presence-day derivation exists.
6. Do not change the database destructively.
7. Do not ship scenario planning without deterministic engine tests.

## 13. Deliverables By Stage

### Stage A Deliverables

- new models added
- schema versioning added
- app still builds

### Stage B Deliverables

- `PresenceDayBuilder`
- backfill service
- rebuild tests

### Stage C Deliverables

- parity tests
- validation report or documented parity result

### Stage D Deliverables

- `ResidencyEngine`
- engine tests
- dashboard UI

### Stage E Deliverables

- `ScenarioEngine`
- planner UI
- scenario tests

### Stage F Deliverables

- manual correction layer
- override tests

## 14. Immediate Next Step

The next implementation task must be:

1. add `ResidencyProfile`
2. add `ResidencyRule`
3. add `PresenceDay`
4. add schema versioning and additive migration support

Do not skip directly to planner UI.
Do not start with widget changes.
Do not start with manual correction.

## 15. Final Definition of Success

This project is successful only when the app can reliably answer:

- how many Russia days are currently counted
- how many safe Russia days remain
- whether a planned return home is safe
- the latest safe date to leave or the earliest safe date to return

Everything else is secondary.
