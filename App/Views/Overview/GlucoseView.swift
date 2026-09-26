//
//  GlucoseView.swift
//  GlucoseDirect
//
//  Redesigned with modern card-based UI inspired by the provided design mockups.
//

import SwiftUI

// MARK: - GlucoseStatusEmoji

private enum GlucoseStatusEmoji: String {
    case lookingGood = "😊"
    case woozy = "🥴"
    case high = "😟"
    case noData = "❓"

    static func from(glucose: (any Glucose)?, alarmLow: Int, alarmHigh: Int) -> GlucoseStatusEmoji {
        guard let glucose = glucose else { return .noData }
        if glucose.glucoseValue < alarmLow { return .woozy }
        if glucose.glucoseValue > alarmHigh { return .high }
        return .lookingGood
    }

    var label: String {
        switch self {
        case .lookingGood: return "LOOKING GOOD!"
        case .woozy: return "FEELING WOOZY?"
        case .high: return "HUH, KINDA HIGH!"
        case .noData: return "NO DATA"
        }
    }

    var color: Color {
        switch self {
        case .lookingGood: return Color(red: 0.39, green: 0.76, blue: 0.35)
        case .woozy: return Color(red: 1.0, green: 0.7, blue: 0.0)
        case .high: return Color(red: 0.94, green: 0.27, blue: 0.27)
        case .noData: return Color.secondary
        }
    }
}

// MARK: - GlucoseStatusLabel

private enum GlucoseStatusLabel: String {
    case good = "Good"
    case low = "Low"
    case high = "High"

    static func from(glucose: (any Glucose)?, alarmLow: Int, alarmHigh: Int) -> GlucoseStatusLabel {
        guard let glucose = glucose else { return .good }
        if glucose.glucoseValue < alarmLow { return .low }
        if glucose.glucoseValue > alarmHigh { return .high }
        return .good
    }

    var color: Color {
        switch self {
        case .good: return Color(red: 0.39, green: 0.76, blue: 0.35)
        case .low: return Color(red: 1.0, green: 0.55, blue: 0.0)
        case .high: return Color(red: 0.94, green: 0.27, blue: 0.27)
        }
    }
}

// MARK: - GlucoseView

struct GlucoseView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        VStack(spacing: 0) {
            // Status emoji + label
            VStack(spacing: 6) {
                Text(statusEmoji.rawValue)
                    .font(.system(size: 64))
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)

                Text(statusEmoji.label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
            .padding(.bottom, 12)

            // Large glucose reading + trend
            if let latestGlucose = store.state.latestSensorGlucose {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    if latestGlucose.type != .high {
                        Text(verbatim: latestGlucose.glucoseValue.asGlucose(glucoseUnit: store.state.glucoseUnit))
                            .font(.system(size: 80, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.6)

                        VStack(alignment: .leading, spacing: 0) {
                            Text(verbatim: latestGlucose.trend.description)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(trendColor(for: latestGlucose))
                        }
                        .padding(.bottom, 10)
                    } else {
                        Text("HIGH")
                            .font(.system(size: 60, weight: .black, design: .rounded))
                            .foregroundColor(Color.ui.red)
                    }
                }

                // Unit + status badge row
                HStack(spacing: 12) {
                    Text(verbatim: store.state.glucoseUnit.localizedDescription)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    let statusLabel = GlucoseStatusLabel.from(
                        glucose: latestGlucose,
                        alarmLow: store.state.alarmLow,
                        alarmHigh: store.state.alarmHigh
                    )
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusLabel.color)
                            .frame(width: 7, height: 7)
                        Text(statusLabel.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(statusLabel.color)
                    }
                }
                .padding(.bottom, 4)

                // Timestamp
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                    Text(latestGlucose.timestamp, style: .relative)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    + Text(" ago")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)

                // Warning banner
                if let warning = warning {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(verbatim: warning)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color.ui.red)
                    )
                    .padding(.bottom, 8)
                }

            } else {
                // No data state
                VStack(spacing: 8) {
                    Text("No Data")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(Color.ui.red.opacity(0.8))

                    Text(Date(), style: .time)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 16)
            }

            // Bottom controls: screen lock + snooze
            HStack(spacing: 16) {
                // Screen lock toggle
                Button(action: {
                    DirectNotifications.shared.hapticFeedback()
                    store.dispatch(.setPreventScreenLock(enabled: !store.state.preventScreenLock))
                }, label: {
                    HStack(spacing: 6) {
                        Image(systemName: store.state.preventScreenLock ? "lock.slash.fill" : "lock.fill")
                            .font(.system(size: 14))
                        if store.state.preventScreenLock {
                            Text("No screen lock")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .foregroundColor(store.state.preventScreenLock ? Color.ui.purple : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(store.state.preventScreenLock
                                  ? Color.ui.purple.opacity(0.12)
                                  : Color(.tertiarySystemFill))
                    )
                })

                Spacer()

                // Snooze controls
                if store.state.alarmSnoozeUntil != nil {
                    Button(action: {
                        DirectNotifications.shared.hapticFeedback()
                        store.dispatch(.setAlarmSnoozeUntil(untilDate: nil))
                    }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    })
                }

                Button(action: {
                    let date = (store.state.alarmSnoozeUntil ?? Date()).toRounded(on: 1, .minute)
                    let nextDate = Calendar.current.date(byAdding: .minute, value: 30, to: date)
                    DirectNotifications.shared.hapticFeedback()
                    store.dispatch(.setAlarmSnoozeUntil(untilDate: nextDate))
                }, label: {
                    HStack(spacing: 6) {
                        Image(systemName: store.state.alarmSnoozeUntil == nil ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 14))
                        if let snoozeUntil = store.state.alarmSnoozeUntil {
                            Text(verbatim: snoozeUntil.toLocalTime())
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .foregroundColor(store.state.alarmSnoozeUntil == nil ? .secondary : Color.ui.purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(store.state.alarmSnoozeUntil == nil
                                  ? Color(.tertiarySystemFill)
                                  : Color.ui.purple.opacity(0.12))
                    )
                })
            }
            .buttonStyle(.plain)
            .disabled(store.state.latestSensorGlucose == nil)
            .padding(.top, 4)
            .padding(.bottom, 4)
        }
    }

    // MARK: Private

    private var statusEmoji: GlucoseStatusEmoji {
        GlucoseStatusEmoji.from(
            glucose: store.state.latestSensorGlucose,
            alarmLow: store.state.alarmLow,
            alarmHigh: store.state.alarmHigh
        )
    }

    private var warning: String? {
        if let sensor = store.state.sensor, sensor.state != .ready {
            return sensor.state.localizedDescription
        }
        if store.state.connectionState != .connected {
            return store.state.connectionState.localizedDescription
        }
        return nil
    }

    private func isAlarm(glucose: any Glucose) -> Bool {
        store.state.isAlarm(glucoseValue: glucose.glucoseValue) != .none
    }

    private func trendColor(for glucose: any Glucose) -> Color {
        if isAlarm(glucose: glucose) {
            return Color.ui.red
        }
        let g = glucose.glucoseValue
        if g < store.state.alarmLow { return Color(red: 1.0, green: 0.55, blue: 0.0) }
        if g > store.state.alarmHigh { return Color.ui.red }
        return Color.ui.purple
    }
}
