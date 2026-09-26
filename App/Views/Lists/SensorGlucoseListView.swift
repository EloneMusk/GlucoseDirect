//
//  SensorGlucoseList.swift
//  GlucoseDirectApp
//
//  Redesigned with card-based rows matching the design mockup style.
//

import SwiftUI

struct SensorGlucoseListView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        Group {
            // Section header with "History" title
            VStack(alignment: .leading, spacing: 0) {
                if sensorGlucoseValues.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "sensor.tag.radiowaves.forward")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text("No Readings Yet")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 48)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(sensorGlucoseValues) { sensorGlucose in
                        GlucoseHistoryRow(
                            glucose: sensorGlucose,
                            glucoseUnit: store.state.glucoseUnit,
                            alarmLow: store.state.alarmLow,
                            alarmHigh: store.state.alarmHigh,
                            smoothThreshold: store.state.smoothThreshold
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onDelete { offsets in
                        DirectLog.info("onDelete: \(offsets)")
                        let deletables = offsets.map { i in
                            (index: i, glucose: sensorGlucoseValues[i])
                        }
                        deletables.forEach { delete in
                            sensorGlucoseValues.remove(at: delete.index)
                            store.dispatch(.deleteSensorGlucose(glucose: delete.glucose))
                        }
                    }
                }
            }
        }
        .onAppear {
            DirectLog.info("onAppear")
            self.sensorGlucoseValues = store.state.sensorGlucoseValues.reversed()
        }
        .onChange(of: store.state.sensorGlucoseValues) { glucoseValues in
            DirectLog.info("onChange")
            self.sensorGlucoseValues = glucoseValues.reversed()
        }
    }

    // MARK: Private

    @State private var sensorGlucoseValues: [SensorGlucose] = []

    private func getTeaser(_ count: Int) -> String {
        return count.pluralizeLocalization(singular: "%@ Entry", plural: "%@ Entries")
    }
}

// MARK: - GlucoseHistoryRow

struct GlucoseHistoryRow: View {
    let glucose: SensorGlucose
    let glucoseUnit: GlucoseUnit
    let alarmLow: Int
    let alarmHigh: Int
    let smoothThreshold: Date

    private var displayValue: Int {
        if let smooth = glucose.smoothGlucoseValue?.toInteger(),
           glucose.timestamp < smoothThreshold,
           DirectConfig.showSmoothedGlucose {
            return smooth
        }
        return glucose.glucoseValue
    }

    private var statusLabel: (text: String, color: Color) {
        if displayValue < alarmLow {
            return ("Low", Color(red: 1.0, green: 0.55, blue: 0.0))
        } else if displayValue > alarmHigh {
            return ("High", Color(red: 0.94, green: 0.27, blue: 0.27))
        }
        return ("Good", Color(red: 0.39, green: 0.76, blue: 0.35))
    }

    private var valueColor: Color {
        if displayValue < alarmLow { return Color(red: 1.0, green: 0.55, blue: 0.0) }
        if displayValue > alarmHigh { return Color.ui.red }
        return .primary
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Glucose value + trend
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(verbatim: displayValue.asGlucose(glucoseUnit: glucoseUnit))
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(valueColor)

                    Text(verbatim: glucose.trend.description)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(valueColor)
                        .padding(.bottom, 3)
                }

                // Status badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusLabel.color)
                        .frame(width: 6, height: 6)
                    Text(statusLabel.text)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(statusLabel.color)
                }
            }

            Spacer()

            // Timestamp
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 2) {
                    Text(glucose.timestamp, style: .relative)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary) as! Text
                    Text("ago")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Text(glucose.timestamp.toLocalTime())
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}
