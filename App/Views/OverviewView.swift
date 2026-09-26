//
//  OverviewView.swift
//  GlucoseDirect
//
//  Redesigned with modern card-based home screen layout.
//

import SwiftUI

// MARK: - OverviewView

struct OverviewView: View {
    @EnvironmentObject var store: DirectStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // ── Glucose hero card ──────────────────────────────────────
                VStack(spacing: 0) {
                    GlucoseView()
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                }
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.07), radius: 16, x: 0, y: 6)
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // ── Chart card ────────────────────────────────────────────
                if !store.state.sensorGlucoseValues.isEmpty || !store.state.bloodGlucoseValues.isEmpty {
                    VStack(spacing: 0) {
                        if #available(iOS 16.0, *) {
                            ChartView()
                        } else {
                            ChartViewCompatibility()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }

                // ── In-Range / % ring card ────────────────────────────────
                if let stats = store.state.glucoseStatistics {
                    InRangeRingCard(statistics: stats)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }

                // ── Connection + Sensor info ───────────────────────────────
                VStack(spacing: 0) {
                    ConnectionView()
                        .listRowBackground(Color.clear)
                    SensorView()
                        .listRowBackground(Color.clear)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer(minLength: 32)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .listStyle(.grouped)
    }
}

// MARK: - InRangeRingCard

struct InRangeRingCard: View {
    let statistics: GlucoseStatistics

    var tirPercent: Int { Int(statistics.tir) }

    var body: some View {
        HStack(spacing: 20) {
            // Ring
            ZStack {
                Circle()
                    .stroke(Color(.systemFill), lineWidth: 8)
                    .frame(width: 64, height: 64)

                Circle()
                    .trim(from: 0, to: CGFloat(statistics.tir) / 100.0)
                    .stroke(
                        Color.ui.purple,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))

                Text("\(tirPercent)%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("% in range")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                let seconds = Int(statistics.toTimestamp.timeIntervalSince(statistics.fromTimestamp))
                Text(verbatim: seconds.inTime)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}
