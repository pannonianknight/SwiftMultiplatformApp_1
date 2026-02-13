import SwiftUI
#if os(tvOS)
import UIKit
#endif

// MARK: - Orbit Manager (Shared State)
@Observable
class OrbitManager {
    var isEnabled = false
    var zoomLevel: Int = 0

    private var lastToggleTime: Date = .distantPast

    func toggle() {
        let now = Date()
        guard now.timeIntervalSince(lastToggleTime) > 0.5 else {
            print("[Orbit] toggle ignored (debounce)")
            return
        }
        lastToggleTime = now
        
        isEnabled.toggle()
        if !isEnabled { zoomLevel = 0 }
        print("[Orbit] toggled: \(isEnabled ? "ON" : "OFF")")
    }

    func zoomIn() {
        guard isEnabled else { return }
        zoomLevel = min(3, zoomLevel + 1)
        logZoom()
    }

    func zoomOut() {
        guard isEnabled else { return }
        zoomLevel = max(-3, zoomLevel - 1)
        logZoom()
    }

    private func logZoom() {
        if zoomLevel > 0 {
            print("[Zoom] in +\(zoomLevel)")
        } else if zoomLevel < 0 {
            print("[Zoom] out \(zoomLevel)")
        } else {
            print("[Zoom] default (0)")
        }
    }
}

// MARK: - Content View (Root)
struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var orbitManager = OrbitManager()

    var body: some View {
        Group {
            #if os(iOS)
            iOSView()
            #elseif os(tvOS)
            tvOSView()
            #endif
        }
        .environment(orbitManager)
        .onAppear { logPlatform() }
    }

    private func logPlatform() {
        #if os(iOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .phone: print("[Platform] iOS – iPhone")
        case .pad:   print("[Platform] iOS – iPad")
        default:     print("[Platform] iOS – other")
        }
        #elseif os(tvOS)
        print("[Platform] tvOS")
        #endif
    }

    #if os(iOS)
    private func iOSView() -> some View {
        TabView {
            ForEach(MenuItem.allCases.filter { !$0.isToggle }) { item in
                NavigationStack {
                    DetailView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                OrbitControlButton()
                            }
                        }
                }
                .tabItem {
                    Label(item.title, systemImage: item.icon)
                }
                .tag(item)
            }
        }
    }
    #endif

    #if os(tvOS)
    private func tvOSView() -> some View {
        TVOSBoatConfiguratorView()
    }
    #endif
}

// MARK: - Detail View (iOS)
struct DetailView: View {
    @Environment(OrbitManager.self) private var orbitManager

    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                Image(systemName: "car.rear.fill")
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.blue)
                    .frame(width: 96)
                    .padding(.top, 64)

                Divider()

                Text("Hello, world!")
                    .font(.title)

                Text("Orbit: \(orbitManager.isEnabled ? "ON" : "OFF")")
                    .font(.subheadline)
                    .foregroundStyle(orbitManager.isEnabled ? .green : .red)

                Spacer()
            }
            .padding(64)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Orbit Control Button (iOS)
struct OrbitControlButton: View {
    @Environment(OrbitManager.self) private var orbitManager

    var body: some View {
        Button {
            orbitManager.toggle()
        } label: {
            Image(systemName: orbitManager.isEnabled ? "globe.desk.fill" : "globe.desk")
                .font(.title2)
                .foregroundStyle(orbitManager.isEnabled ? .blue : .primary)
        }
    }
}

// MARK: - Menu Item Model (iOS only)
#if os(iOS)
enum MenuItem: String, CaseIterable, Identifiable {
    case button1 = "Button 1"
    case button2 = "Button 2"
    case button3 = "Button 3"
    case toggleOption = "Moj Toggle"

    var id: String { rawValue }
    var title: String { rawValue }

    var icon: String {
        switch self {
        case .button1: return "1.circle"
        case .button2: return "2.circle"
        case .button3: return "3.circle"
        case .toggleOption: return "switch.2"
        }
    }

    var isToggle: Bool {
        self == .toggleOption
    }
}
#endif

// MARK: - tvOS Boat Configurator

#if os(tvOS)

struct ConfigurationOption: Identifiable {
    let id = UUID()
    let title: String
    let choices: [String]
}

enum CameraView: String, CaseIterable, Identifiable {
    case front = "Front"
    case side = "Side"
    case rear = "Rear"
    case interior = "Interior"

    var id: String { rawValue }
    var title: String { rawValue }
}

@Observable
class TVOSConfigurationManager {
    var selectedCamera: CameraView = .front
    var selectedLeftOption: Int = 1
    var configurations: [ConfigurationOption] = [
        ConfigurationOption(title: "Hull Color", choices: ["White", "Blue", "Red", "Black"]),
        ConfigurationOption(title: "Deck Style", choices: ["Classic", "Sport", "Luxury"]),
        ConfigurationOption(title: "Engine", choices: ["Standard", "Performance", "Eco"]),
        ConfigurationOption(title: "Interior", choices: ["Leather", "Fabric", "Wood"]),
        ConfigurationOption(title: "Electronics", choices: ["Basic", "Advanced", "Premium"])
    ]
    var selectedChoices: [UUID: String] = [:]
    var activeBottomMenu: UUID? = nil
}

// MARK: - Root tvOS View
struct TVOSBoatConfiguratorView: View {
    @State private var configManager = TVOSConfigurationManager()
    @State private var touchPanel = TouchPanelObserver()
    @Environment(OrbitManager.self) private var orbitManager
    @FocusState private var focusedConfigCard: UUID?

    private let screenMargin: CGFloat = 32

    var body: some View {
        ZStack {
            // Layer 0: Boat display
            BoatDisplayView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environment(touchPanel)
                .focusable(false)

            // Layer 1: Sidebars (Always visible, fixed position)
            HStack(spacing: 0) {
                LeftSideMenu(selectedOption: $configManager.selectedLeftOption)
                    .frame(width: 200)
                    .focusSection()
                Spacer()
                RightSideMenu()
                    .frame(width: 200)
            }
            .frame(maxHeight: .infinity)
            .padding(screenMargin)

            // Layer 2: Top & Bottom Bars (Dynamic visibility)
            VStack(spacing: 0) {
                TopBarView(selectedCamera: $configManager.selectedCamera)
                    .focusSection()
                
                Spacer()

                if !orbitManager.isEnabled {
                    BottomConfigurationCards(
                        configManager: configManager,
                        focusedCard: $focusedConfigCard
                    )
                    .focusSection()
                    .padding(.horizontal, 24)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: orbitManager.isEnabled)
            .padding(screenMargin)

            // Layer 2: Selection overlay
            if let activeMenuId = configManager.activeBottomMenu,
               let option = configManager.configurations.first(where: { $0.id == activeMenuId }) {
                SelectionMenuOverlay(
                    option: option,
                    selectedChoice: Binding(
                        get: { configManager.selectedChoices[activeMenuId] ?? option.choices.first ?? "" },
                        set: { configManager.selectedChoices[activeMenuId] = $0 }
                    ),
                    onDismiss: {
                        focusedConfigCard = activeMenuId
                        configManager.activeBottomMenu = nil
                    }
                )
            }
        }
        .onPlayPauseCommand {
            // SwiftUI native — ovo UVIJEK radi za play/pause
            print("[SwiftUI] onPlayPauseCommand")
            orbitManager.toggle()
        }
        .onAppear {
            touchPanel.onPlayPause = { orbitManager.toggle() }
            touchPanel.onZoomIn = { orbitManager.zoomIn() }
            touchPanel.onZoomOut = { orbitManager.zoomOut() }
        }
        .onChange(of: orbitManager.isEnabled) { _, isOn in
            if isOn { configManager.activeBottomMenu = nil }
        }
        .ignoresSafeArea()
        .environment(configManager)
    }
}

// MARK: - Top Bar
struct TopBarView: View {
    @Binding var selectedCamera: CameraView
    @Environment(OrbitManager.self) private var orbitManager

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            if !orbitManager.isEnabled {
                HStack(spacing: 24) {
                    ForEach(CameraView.allCases) { view in
                        Button {
                            selectedCamera = view
                        } label: {
                            Text(view.title)
                                .font(.system(size: 16, weight: .medium))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 15)
                                .background(selectedCamera == view ? Color.accentColor.opacity(0.3) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.card)
                    }
                }
                .transition(.opacity)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .animation(.easeInOut(duration: 0.25), value: orbitManager.isEnabled)
    }
}

// MARK: - Left Side Menu
struct LeftSideMenu: View {
    @Binding var selectedOption: Int
    @Environment(OrbitManager.self) private var orbitManager
    @FocusState private var focusedButton: Int?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Buttons 1 & 2 — hidden while orbit is active
            if !orbitManager.isEnabled {
                // View 1
                SideMenuButton(
                    isActive: selectedOption == 1,
                    icon: selectedOption == 1 ? "sun.max.fill" : "sun.max",
                    action: { selectedOption = 1 }
                )
                .focused($focusedButton, equals: 1)

                // View 2
                SideMenuButton(
                    isActive: selectedOption == 2,
                    icon: selectedOption == 2 ? "sun.haze.fill" : "sun.haze",
                    action: { selectedOption = 2 }
                )
                .focused($focusedButton, equals: 2)
            }

            Spacer(minLength: 16)
        }
        .defaultFocus($focusedButton, 1)
        .animation(.easeInOut(duration: 0.25), value: orbitManager.isEnabled)
    }
}

// MARK: - Right Side Menu (Orbit Indicator)
struct RightSideMenu: View {
    @Environment(OrbitManager.self) private var orbitManager

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Orbit Indicator (Visual only, not focusable)
            ZStack {
                // Glass Background
                Circle()
                    .fill(orbitManager.isEnabled ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.08))
                Circle()
                    .fill(.ultraThinMaterial)
                
                // Icon
                Image(systemName: orbitManager.isEnabled ? "rotate.3d.fill" : "rotate.3d")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.white)
                    .opacity(orbitManager.isEnabled ? 1.0 : 0.6)
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.25), value: orbitManager.isEnabled)
            
            // Phantom Spacer to match LeftSideMenu structure (2 items vs 1)
            // This ensures the Orbit indicator aligns with the TOP button of the left menu.
            Color.clear
                .frame(width: 80, height: 80)
            
            Spacer()
        }
    }
}

struct SideMenuButton: View {
    let isActive: Bool
    let icon: String
    var isOrbit: Bool = false      // Deprecated/Unused parameter, kept for compatibility if needed but logic removed
    var orbitEnabled: Bool = false // Deprecated/Unused parameter
    let action: () -> Void
    
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(isActive ? Color.white : Color.white.opacity(0.6))
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(isActive ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
                )
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            isFocused ? Color.white.opacity(0.6) : Color.white.opacity(0.15),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .scaleEffect(isFocused ? 1.15 : 1.0)
                .shadow(color: isFocused ? Color.white.opacity(0.3) : Color.clear, radius: 12)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Boat Display
struct BoatDisplayView: View {
    @Environment(OrbitManager.self) private var orbitManager
    @Environment(TVOSConfigurationManager.self) private var configManager
    @Environment(TouchPanelObserver.self) private var touchPanel

    private var zoomLabel: String {
        if orbitManager.zoomLevel > 0 {
            return "zoom in +\(orbitManager.zoomLevel)"
        } else if orbitManager.zoomLevel < 0 {
            return "zoom out \(orbitManager.zoomLevel)"
        } else {
            return "default"
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Image(systemName: "ferry.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 300)
                    .foregroundStyle(.blue)

                Text("View: \(configManager.selectedCamera.title)")
                    .font(.headline)

                Text("Orbit: \(orbitManager.isEnabled ? "ON" : "OFF")")
                    .font(.subheadline)
                    .foregroundStyle(orbitManager.isEnabled ? .green : .secondary)

                if orbitManager.isEnabled {
                    VStack(spacing: 8) {
                        Text("Touch panel (remote)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("x: \(touchPanel.x, specifier: "%.3f")  y: \(touchPanel.y, specifier: "%.3f")")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.white)
                        Text(zoomLabel)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Bottom Configuration Cards
struct BottomConfigurationCards: View {
    var configManager: TVOSConfigurationManager
    var focusedCard: FocusState<UUID?>.Binding

    var body: some View {
        HStack(spacing: 24) {
            ForEach(configManager.configurations) { option in
                ConfigurationCard(
                    option: option,
                    selectedChoice: configManager.selectedChoices[option.id] ?? option.choices.first ?? "",
                    isActive: configManager.activeBottomMenu == option.id,
                    focusedCard: focusedCard
                ) {
                    withAnimation {
                        if configManager.activeBottomMenu == option.id {
                            configManager.activeBottomMenu = nil
                        } else {
                            configManager.activeBottomMenu = option.id
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 96)
        .defaultFocus(focusedCard, configManager.configurations.first?.id)
    }
}

// MARK: - Configuration Card
struct ConfigurationCard: View {
    let option: ConfigurationOption
    let selectedChoice: String
    let isActive: Bool
    var focusedCard: FocusState<UUID?>.Binding
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Text(option.title)
                    .font(.system(size: 24, weight: .medium))

                Text(selectedChoice)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(isActive ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(.card)
        .focused(focusedCard, equals: option.id)
    }
}

// MARK: - Selection Menu Overlay
struct SelectionMenuOverlay: View {
    let option: ConfigurationOption
    @Binding var selectedChoice: String
    let onDismiss: () -> Void
    @FocusState private var focusedChoice: String?

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: 24) {
                Text("Select \(option.title)")
                    .font(.system(size: 24, weight: .medium))
                    .fontWeight(.bold)
                    .padding(.bottom, 8)

                VStack(spacing: 12) {
                    ForEach(option.choices, id: \.self) { choice in
                        Button {
                            selectedChoice = choice
                            onDismiss()
                        } label: {
                            HStack {
                                Text(choice)
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                                if choice == selectedChoice {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .frame(width: 500)
                            .background(choice == selectedChoice ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                        .buttonStyle(.card)
                        .focused($focusedChoice, equals: choice)
                    }
                }
            }
            .padding(32)
            .background(Color(white: 0.15))
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(radius: 20)
        }
        .focusSection()
        .onAppear {
            focusedChoice = selectedChoice
        }
    }
}

#endif
