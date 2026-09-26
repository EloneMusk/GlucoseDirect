//
//  ListView.swift
//  GlucoseDirect
//
//  Redesigned History tab with segmented time filter and modern card layout.
//

import SwiftUI

// MARK: - ListsView

struct ListsView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore
    @State private var selectedSegment = 0 // 0=Today, 1=Week, 2=Month
    @State private var showingAddBloodGlucoseView = false
    @State private var showingAddInsulinView = false

    private let segments = ["Today", "Week", "Month"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("History")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                // Add blood glucose button
                Button(action: { showingAddBloodGlucoseView = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.ui.purple)
                }
                .sheet(isPresented: $showingAddBloodGlucoseView) {
                    AddBloodGlucoseView(glucoseUnit: store.state.glucoseUnit) { time, value in
                        let glucose = BloodGlucose(id: UUID(), timestamp: time, glucoseValue: value)
                        store.dispatch(.addBloodGlucose(glucoseValues: [glucose]))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Segmented control (Today / Week / Month)
            HStack(spacing: 0) {
                ForEach(Array(segments.enumerated()), id: \.0) { index, title in
                    Button(action: {
                        DirectNotifications.shared.hapticFeedback()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedSegment = index
                        }
                    }) {
                        Text(title)
                            .font(.system(size: 13, weight: selectedSegment == index ? .bold : .medium))
                            .foregroundColor(selectedSegment == index ? .white : .secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedSegment == index ? Color.ui.purple : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                Capsule()
                    .fill(Color(.systemFill))
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if DirectConfig.showInsulinInput, store.state.showInsulinInput {
                        Button("Add insulin", action: { showingAddInsulinView = true })
                            .buttonStyle(.bordered)
                            .tint(Color.ui.purple)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                            .sheet(isPresented: $showingAddInsulinView) {
                                AddInsulinView { start, end, units, insulinType in
                                    let insulinDelivery = InsulinDelivery(id: UUID(), starts: start, ends: end, units: units, type: insulinType)
                                    store.dispatch(.addInsulinDelivery(insulinDeliveryValues: [insulinDelivery]))
                                }
                            }
                    }

                    // Sensor glucose cards
                    SensorGlucoseListView()

                    // Blood glucose section
                    if DirectConfig.bloodGlucoseInput {
                        BloodGlucoseListView()
                            .padding(.top, 8)
                    }

                    // Insulin delivery
                    if DirectConfig.showInsulinInput, store.state.showInsulinInput {
                        InsulinDeliveryListView()
                            .padding(.top, 8)
                    }

                    // Sensor errors
                    if DirectConfig.glucoseErrors {
                        SensorErrorListView()
                            .padding(.top, 8)
                    }

                    // Statistics
                    if DirectConfig.glucoseStatistics {
                        StatisticsView()
                            .padding(.top, 8)
                    }

                    Spacer(minLength: 32)
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
