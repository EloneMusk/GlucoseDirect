//
//  GlucoseActivityWidget.swift
//  GlucoseDirect
//
//  Redesigned Live Activity with modern pill-style layout and configurable display options.
//  Also supports CarPlay via the same lock-screen view.
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - GlucoseActivityWidget

@available(iOS 16.1, *)
struct GlucoseActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SensorGlucoseActivityAttributes.self) { context in
            // Lock Screen / CarPlay Live Activity banner
            GlucoseActivityBannerView(context: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    DynamicIslandCenterView(context: context.state)
                }
            } compactLeading: {
                if let latestGlucose = context.state.glucose,
                   let glucoseUnit = context.state.glucoseUnit,
                   let connectionState = context.state.connectionState,
                   context.state.showValue
                {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(latestGlucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .strikethrough(connectionState != .connected, color: Color.ui.red)

                        Text(glucoseUnit.shortLocalizedDescription)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }.padding(.leading, 7.5)
                }
            } compactTrailing: {
                if let latestGlucose = context.state.glucose,
                   let glucoseUnit = context.state.glucoseUnit,
                   context.state.showTrend
                {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(latestGlucose.trend.description)
                            .font(.system(size: 15, weight: .bold))

                        if let minuteChange = latestGlucose.minuteChange?.asShortMinuteChange(glucoseUnit: glucoseUnit),
                           latestGlucose.trend != .unknown
                        {
                            Text(minuteChange)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }.padding(.trailing, 7.5)
                }
            } minimal: {
                if let latestGlucose = context.state.glucose,
                   let glucoseUnit = context.state.glucoseUnit,
                   let connectionState = context.state.connectionState,
                   context.state.showValue
                {
                    Text(latestGlucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .strikethrough(connectionState != .connected, color: Color.ui.red)
                }
            }
        }
    }
}

// MARK: - GlucoseStatusContext

@available(iOS 16.1, *)
protocol GlucoseStatusContext {
    var context: SensorGlucoseActivityAttributes.GlucoseStatus { get }
}

@available(iOS 16.1, *)
extension GlucoseStatusContext {
    var warning: String? {
        if let sensorState = context.sensorState, sensorState != .ready {
            return sensorState.localizedDescription
        }

        if let connectionState = context.connectionState, connectionState != .connected {
            return connectionState.localizedDescription
        }

        return nil
    }

    func isAlarm(glucose: any Glucose) -> Bool {
        if glucose.glucoseValue < context.alarmLow || glucose.glucoseValue > context.alarmHigh {
            return true
        }
        return false
    }

    func glucoseStatusColor(glucose: any Glucose) -> Color {
        let g = glucose.glucoseValue
        if g < context.alarmLow { return Color(red: 1.0, green: 0.55, blue: 0.0) }
        if g > context.alarmHigh { return Color.ui.red }
        return Color.ui.purple
    }
}

// MARK: - DynamicIslandCenterView

@available(iOS 16.1, *)
struct DynamicIslandCenterView: View, GlucoseStatusContext {
    @State var context: SensorGlucoseActivityAttributes.GlucoseStatus

    var body: some View {
        VStack(spacing: 4) {
            if let latestGlucose = context.glucose, let glucoseUnit = context.glucoseUnit {
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    if context.showValue {
                        if latestGlucose.type != .high {
                            Text(verbatim: latestGlucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                                .font(.system(size: 56, weight: .black, design: .rounded))
                                .foregroundColor(glucoseStatusColor(glucose: latestGlucose))
                        } else {
                            Text("HIGH")
                                .font(.system(size: 44, weight: .black, design: .rounded))
                                .foregroundColor(Color.ui.red)
                        }
                    }

                    if context.showTrend {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(verbatim: latestGlucose.trend.description)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(glucoseStatusColor(glucose: latestGlucose))
                        }
                        .padding(.bottom, 8)
                    }
                }

                if let warning = warning {
                    Text(verbatim: warning)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.ui.red))
                } else {
                    HStack(spacing: 12) {
                        if context.showValue {
                            Text(verbatim: glucoseUnit.localizedDescription)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        if context.showLastUpdate {
                            Text(latestGlucose.timestamp, style: .time)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text("No Data")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(Color.ui.red)

                Text(Date(), style: .time)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 4)
    }
}

// MARK: - GlucoseActivityBannerView (Lock Screen + CarPlay)

@available(iOS 16.1, *)
struct GlucoseActivityBannerView: View, GlucoseStatusContext {
    @State var context: SensorGlucoseActivityAttributes.GlucoseStatus

    var body: some View {
        HStack(spacing: 0) {
            // Left: glucose value + trend
            if let latestGlucose = context.glucose, let glucoseUnit = context.glucoseUnit {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        if context.showValue {
                            Group {
                                if latestGlucose.type != .high {
                                    Text(verbatim: latestGlucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                                } else {
                                    Text("HIGH")
                                }
                            }
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(glucoseStatusColor(glucose: latestGlucose))
                        }

                        if context.showTrend {
                            Text(verbatim: latestGlucose.trend.description)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(glucoseStatusColor(glucose: latestGlucose))
                                .padding(.bottom, 6)
                        }
                    }

                    // Status row
                    if let warning = warning {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color.ui.red)
                            Text(verbatim: warning)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.ui.red)
                        }
                    } else {
                        HStack(spacing: 8) {
                            if context.showValue {
                                Text(verbatim: glucoseUnit.localizedDescription)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            if let minuteChange = latestGlucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) {
                                Text(verbatim: minuteChange)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                // Right: last updated time
                if context.showLastUpdate {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Updated")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(latestGlucose.timestamp, style: .time)
                            .font(.system(size: 13, weight: .bold))
                            .monospacedDigit()

                        // Relative time
                        HStack(spacing: 2) {
                            Text(latestGlucose.timestamp, style: .relative)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.trailing)
                            Text("ago")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }

            } else {
                // No data
                VStack(alignment: .leading, spacing: 4) {
                    Text("No Data")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(Color.ui.red)

                    Text(Date(), style: .time)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Color(.systemBackground)
        )
    }
}

// MARK: - GlucoseActivityWidget_Previews

@available(iOS 16.1, *)
struct GlucoseActivityWidget_Previews: PreviewProvider {
    static var previews: some View {
        // No data state
        GlucoseActivityBannerView(
            context: SensorGlucoseActivityAttributes.GlucoseStatus(
                alarmLow: 80,
                alarmHigh: 160,
                sensorState: .expired,
                connectionState: .disconnected,
                glucoseUnit: .mgdL,
                startDate: Date(),
                restartDate: Date(),
                stopDate: Date(),
                showValue: true,
                showTrend: true,
                showLastUpdate: true
            )
        ).previewContext(WidgetPreviewContext(family: .systemMedium))

        // Normal glucose
        GlucoseActivityBannerView(
            context: SensorGlucoseActivityAttributes.GlucoseStatus(
                alarmLow: 80,
                alarmHigh: 160,
                sensorState: .ready,
                connectionState: .connected,
                glucose: SensorGlucose(glucoseValue: 107, minuteChange: -0.5),
                glucoseUnit: .mgdL,
                startDate: Date(),
                restartDate: Date(),
                stopDate: Date(),
                showValue: true,
                showTrend: true,
                showLastUpdate: true
            )
        ).previewContext(WidgetPreviewContext(family: .systemMedium))

        // Show only value (no trend, no time)
        GlucoseActivityBannerView(
            context: SensorGlucoseActivityAttributes.GlucoseStatus(
                alarmLow: 80,
                alarmHigh: 160,
                sensorState: .ready,
                connectionState: .connected,
                glucose: SensorGlucose(glucoseValue: 185, minuteChange: 1.2),
                glucoseUnit: .mgdL,
                startDate: Date(),
                restartDate: Date(),
                stopDate: Date(),
                showValue: true,
                showTrend: false,
                showLastUpdate: false
            )
        ).previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
