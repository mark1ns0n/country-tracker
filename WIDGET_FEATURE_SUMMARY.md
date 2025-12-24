# Widget Feature - Top 3 Countries (Last Year)

## ✅ Completed

### 1. Data Flow Integration
- **YearStatsWidget** (Main App) → **WidgetDataService** (App Group) → **CountryTrackerWidget**
- Updated [YearStatsWidget.swift](CountryDaysTracker/Views/Stats/YearStatsWidget.swift) to automatically save calculated statistics to the widget when stats are refreshed
- Data includes: countries count, total days, trips count, and **top 3 countries with days spent**

### 2. Widget Displays
The CountryTrackerWidget now shows top 3 countries in all sizes:

#### Small Widget (2x2)
- Shows 4 key metrics including the top country flag/code

#### Medium Widget (2x3) 
- Main stats (countries, days, trips)
- **Top 3 countries list** with day counts
- Format: [Flag] [Country Code] → [Days]

#### Large Widget (2x4)
- Detailed "Top Countries" section with:
  - Country flag emoji
  - Country code
  - Number of days spent
  - Progress bar comparing to the top country
  - Visual cards for each country

#### Accessory Widget (Lock Screen)
- Compact display showing Countries, Days, and Top country code

### 3. Technical Setup

#### App Group Configuration
Both targets share the same App Group for data synchronization:
- **Main App**: `group.com.mark1ns0n.countrydaystracker`
- **Widget Extension**: `group.com.mark1ns0n.countrydaystracker`

Entitlements files configured:
- [CountryDaysTracker.entitlements](CountryDaysTracker/CountryDaysTracker.entitlements)
- [group.com.mark1ns0n.countrydaystrackerExtension.entitlements](group.com.mark1ns0n.countrydaystrackerExtension.entitlements)

#### Data Persistence
- **WidgetDataService**: Handles encoding/decoding of `CountryYearStats` via UserDefaults with App Group
- **Structures**:
  - `CountryYearStats`: Main data structure with countries count, total days, trips, top countries, and last update time
  - `CountryData`: Individual country data with code and days spent

### 4. Real-time Updates
- Widget automatically updates when new stay intervals are added/closed
- YearStatsWidget listens to `.stayIntervalsDidChange` notification
- Updates saved to widget data every time stats are recalculated
- Widget timeline policy: updates every hour (`policy: .after(nextUpdate)`)

### 5. Data Calculation
Uses existing **AggregationService**:
- `daysByCountry()`: Calculates total unique days per country within date range
- `visitedCountries()`: Gets all unique countries visited
- Results sorted by days descending, top 3 extracted and saved to widget

## File Structure

```
CountryDaysTracker/
├── Services/
│   ├── WidgetDataService.swift          ← Shared widget data manager
│   ├── AggregationService.swift         ← Stats calculation
│   └── DateUtils.swift                  ← Date utilities
├── Widgets/
│   ├── CountryTrackerWidget.swift       ← Widget views (small, medium, large, accessory)
│   └── CountryTrackerWidgetBundle.swift ← Widget entry point
└── Views/Stats/
    └── YearStatsWidget.swift            ← Calculates & saves stats to widget

CountryTrackerWidget/                     ← Legacy copies (not used in build)
```

## How It Works

1. **User adds a stay interval** in the main app
2. **StayRepository** saves to SwiftData and posts `.stayIntervalsDidChange` notification
3. **YearStatsWidget** receives notification and calls `refreshStats()`
4. **AggregationService** calculates days per country for current year
5. **Top 3 countries** extracted from the results
6. **CountryYearStats** object created with all data
7. **WidgetDataService.saveStats()** encodes and saves to UserDefaults (App Group)
8. **CountryTrackerWidget** timeline provider loads saved stats via `WidgetDataService.loadStats()`
9. **Widget displays** the top 3 countries with visual indicators

## Testing Checklist

- [ ] Add a stay interval in the app
- [ ] Check main app stats show updated top countries
- [ ] Add CountryTrackerWidget to home screen (long press → + button)
- [ ] Verify widget displays top 3 countries with correct days
- [ ] Verify flag emojis render correctly for all countries
- [ ] Check that large widget shows progress bars correctly
- [ ] Verify widget updates after closing a stay interval
- [ ] Check widget displays correctly on lock screen (Accessory)

## Next Steps (Optional)

- Add widget intent configuration to filter by custom time range
- Add tap-through to open the app when widget is tapped
- Add widget refresh button to manually refresh
- Customize widget colors and styling based on app theme
