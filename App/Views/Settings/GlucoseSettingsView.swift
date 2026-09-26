//
//  GlucoseSettingsView.swift
//  GlucoseDirect
//
//  Updated with Live Activity display options (show value, trend arrow, last update time).
//

import SwiftUI

// MARK: - GlucoseSettingsView

struct GlucoseSettingsView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        Section(
            content: {
                Picker("Glucose unit", selection: selectedGlucoseUnit) {
                    Text(GlucoseUnit.mgdL.localizedDescription).tag(GlucoseUnit.mgdL.rawValue)
                    Text(GlucoseUnit.mmolL.localizedDescription).tag(GlucoseUnit.mmolL.rawValue)
                }.pickerStyle(.menu)

                NumberSelectorView(key: LocalizedString("Lower limit"), value: store.state.alarmLow, step: 5, max: store.state.alarmHigh, displayValue: store.state.alarmLow.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true)) { value in
                    store.dispatch(.setAlarmLow(lowerLimit: value))
                }

                NumberSelectorView(key: LocalizedString("Upper limit"), value: store.state.alarmHigh, step: 5, min: store.state.alarmLow, displayValue: store.state.alarmHigh.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true)) { value in
                    store.dispatch(.setAlarmHigh(upperLimit: value))
                }

                Toggle("Normal glucose notification", isOn: normalGlucoseNotification).toggleStyle(SwitchToggleStyle(tint: Color.ui.accent))
                Toggle("Alarm glucose notification", isOn: alarmGlucoseNotification).toggleStyle(SwitchToggleStyle(tint: Color.ui.accent))

                if #available(iOS 16.1, *) {
                    Toggle("Glucose Live Activity", isOn: glucoseLiveActivity).toggleStyle(SwitchToggleStyle(tint: Color.ui.accent))
                }
                
                Toggle("Glucose read aloud", isOn: readGlucose).toggleStyle(SwitchToggleStyle(tint: Color.ui.accent))
            },
            header: {
                Label("Glucose settings", systemImage: "cross.case")
            }
        )

        // Live Activity display options section
        if #available(iOS 16.1, *), store.state.glucoseLiveActivity {
            Section(
                content: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Choose what to show in the Live Activity on your Lock Screen and in CarPlay.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

                    Toggle(isOn: liveActivityShowValue) {
                        HStack(spacing: 10) {
                            Image(systemName: "number.circle.fill")
                                .foregroundColor(Color.ui.purple)
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Glucose Value")
                                    .font(.body)
                                Text("Show current blood sugar reading")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.ui.accent))

                    Toggle(isOn: liveActivityShowTrend) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.up.right.circle.fill")
                                .foregroundColor(Color.ui.purple)
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Trend Arrow")
                                    .font(.body)
                                Text("Show direction (rising, stable, falling)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.ui.accent))

                    Toggle(isOn: liveActivityShowLastUpdate) {
                        HStack(spacing: 10) {
                            Image(systemName: "clock.circle.fill")
                                .foregroundColor(Color.ui.purple)
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Last Updated Time")
                                    .font(.body)
                                Text("Show when reading was last received")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.ui.accent))
                },
                header: {
                    Label("Live Activity Display", systemImage: "iphone.and.arrow.right.outward")
                }
            )
        }
    }

    // MARK: Private

    private var normalGlucoseNotification: Binding<Bool> {
        Binding(
            get: { store.state.normalGlucoseNotification },
            set: { store.dispatch(.setNormalGlucoseNotification(enabled: $0)) }
        )
    }

    private var alarmGlucoseNotification: Binding<Bool> {
        Binding(
            get: { store.state.alarmGlucoseNotification },
            set: { store.dispatch(.setAlarmGlucoseNotification(enabled: $0)) }
        )
    }

    private var glucoseLiveActivity: Binding<Bool> {
        Binding(
            get: { store.state.glucoseLiveActivity },
            set: { store.dispatch(.setGlucoseLiveActivity(enabled: $0)) }
        )
    }

    private var readGlucose: Binding<Bool> {
        Binding(
            get: { store.state.readGlucose },
            set: { store.dispatch(.setReadGlucose(enabled: $0)) }
        )
    }

    private var selectedGlucoseUnit: Binding<String> {
        Binding(
            get: { store.state.glucoseUnit.rawValue },
            set: { store.dispatch(.setGlucoseUnit(unit: GlucoseUnit(rawValue: $0)!)) }
        )
    }

    private var liveActivityShowValue: Binding<Bool> {
        Binding(
            get: { store.state.liveActivityShowValue },
            set: { store.dispatch(.setLiveActivityShowValue(enabled: $0)) }
        )
    }

    private var liveActivityShowTrend: Binding<Bool> {
        Binding(
            get: { store.state.liveActivityShowTrend },
            set: { store.dispatch(.setLiveActivityShowTrend(enabled: $0)) }
        )
    }

    private var liveActivityShowLastUpdate: Binding<Bool> {
        Binding(
            get: { store.state.liveActivityShowLastUpdate },
            set: { store.dispatch(.setLiveActivityShowLastUpdate(enabled: $0)) }
        )
    }
}
