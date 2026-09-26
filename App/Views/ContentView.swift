//
//  ContentView.swift
//  GlucoseDirect
//
//  Redesigned with a modern purple tab bar to match the design mockups.
//

import WidgetKit
import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        LoadingView(isShowing: isShowing) {
            ZStack(alignment: .bottom) {
                // Page content
                TabView(selection: selectedView) {
                    OverviewView()
                        .tag(DirectConfig.overviewViewTag)

                    ListsView()
                        .tag(DirectConfig.listsViewTag)

                    if (store.state.isConnectionPaired && store.state.isConnectable || store.state.isDisconnectable) && (DirectConfig.customCalibration || !store.state.customCalibration.isEmpty || store.state.sensor?.factoryCalibration != nil) {
                        CalibrationsView()
                            .tag(DirectConfig.calibrationsViewTag)
                    }

                    SettingsView()
                        .tag(DirectConfig.settingsViewTag)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea(edges: .bottom)

                // Custom purple tab bar
                PurpleTabBar(selectedView: selectedView)
            }
            .onChange(of: scenePhase) { newPhase in
                if store.state.appState != newPhase {
                    store.dispatch(.setAppState(appState: newPhase))
                }

                if newPhase == .background, store.state.preventScreenLock {
                    store.dispatch(.setPreventScreenLock(enabled: false))
                }

                if newPhase == .active {
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            .onChange(of: store.state.latestSensorGlucose, perform: { _ in
                WidgetCenter.shared.reloadAllTimelines()
            })
        }
    }

    // MARK: Private

    private var isShowing: Binding<Bool> {
        Binding(
            get: { store.state.appIsBusy },
            set: { store.dispatch(.setAppIsBusy(isBusy: $0)) }
        )
    }

    private var selectedView: Binding<Int> {
        Binding(
            get: { store.state.selectedView },
            set: { store.dispatch(.selectView(viewTag: $0)) }
        )
    }
}

// MARK: - PurpleTabBar

struct PurpleTabBar: View {
    @EnvironmentObject var store: DirectStore
    var selectedView: Binding<Int>

    private struct TabItem {
        let tag: Int
        let icon: String
        let selectedIcon: String
        let label: String
    }

    private let items: [TabItem] = [
        TabItem(tag: DirectConfig.overviewViewTag,
                icon: "house",
                selectedIcon: "house.fill",
                label: "Home"),
        TabItem(tag: DirectConfig.listsViewTag,
                icon: "clock",
                selectedIcon: "clock.fill",
                label: "History"),
        TabItem(tag: DirectConfig.calibrationsViewTag,
                icon: "chart.bar",
                selectedIcon: "chart.bar.fill",
                label: "Stats"),
        TabItem(tag: DirectConfig.settingsViewTag,
                icon: "slider.horizontal.3",
                selectedIcon: "slider.horizontal.3",
                label: "Settings"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.tag) { item in
                Button(action: {
                    DirectNotifications.shared.hapticFeedback()
                    selectedView.wrappedValue = item.tag
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedView.wrappedValue == item.tag
                              ? item.selectedIcon
                              : item.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(selectedView.wrappedValue == item.tag
                                             ? Color.ui.yellow
                                             : .white.opacity(0.55))

                        Text(item.label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedView.wrappedValue == item.tag
                                             ? Color.ui.yellow
                                             : .white.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, safeAreaBottom)
        .background(
            Color.ui.purple
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: Color.ui.purple.opacity(0.45), radius: 20, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first(where: { $0.isKeyWindow })?
            .safeAreaInsets.bottom ?? 0
    }
}
