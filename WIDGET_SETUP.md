# iOS Widget Setup Instructions

## Что нужно сделать для включения виджета в Xcode

### 1. Создать Widget Target
- В Xcode: File → New → Target
- Выбрать "Widget Extension"
- Назвать: `CountryTrackerWidget`
- Product Name: `CountryTrackerWidget`
- Выбрать основное приложение `CountryDaysTracker`

### 2. Настроить App Group
В основном приложении (CountryDaysTracker):
- Signing & Capabilities
- + Capability → App Groups
- Добавить: `group.com.mark1ns0n.countrydaystracker`

В Widget Extension:
- Signing & Capabilities
- + Capability → App Groups
- Добавить: `group.com.mark1ns0n.countrydaystracker`

### 3. Файлы которые нужны:
1. `CountryTrackerWidget.swift` - основной виджет с разными размерами
2. `CountryTrackerWidgetBundle.swift` - Bundle точка входа
3. `WidgetDataService.swift` - сервис для обмена данными между приложением и виджетом

### 4. Функционал виджета
- **Small (2x2)**: Показывает 4 основные метрики
- **Medium (2x3)**: Метрики + топ 3 страны
- **Large (2x4)**: Полная информация с прогресс-барами
- **Accessory (Lock Screen)**: Компактное отображение на экране блокировки

### 5. Обновление данных
Когда добавляется новая поездка в приложении, `YearStatsWidget` автоматически сохраняет данные через `WidgetDataService`, который обновляет виджет.

### 6. Использование
После установки - долгий тап на рабочий стол iOS → нажать + → выбрать CountryDaysTracker → выбрать CountryTrackerWidget → добавить.
