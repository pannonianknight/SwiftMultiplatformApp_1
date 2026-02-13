import SwiftUI
import Combine

// MARK: - Orbit Manager (Shared State)
// ObservableObject: shared state that multiple views read/update. Use @StateObject where the view owns it, @EnvironmentObject where it’s injected.
// - isEnabled: orbit mod uključen/isključen (npr. Play/Pause na Siri Remoteu).
// - zoomLevel: -3...0...3; 0 = default. zoomIn()/zoomOut() iz dpad.up/down (samo kad nije swipe).
class OrbitManager: ObservableObject {
    @Published var isEnabled = false
    @Published var zoomLevel: Int = 0  // -3...0...3, 0 = default

    func toggle() {
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
// Picks the right root UI per platform: iOS (iPhone/iPad) or tvOS (Apple TV).
struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    // StateObject: this view owns OrbitManager; SwiftUI creates it once and keeps it across body updates.
    @StateObject private var orbitManager = OrbitManager()

    var body: some View {
        Group {
            #if os(iOS)
            iOSView()
            #elseif os(tvOS)
            tvOSView()
            #endif
        }
        .environmentObject(orbitManager)
        .onAppear { logPlatform() }
    }

    private func logPlatform() {
        #if os(iOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            print("[Platform] iOS – iPhone")
        case .pad:
            print("[Platform] iOS – iPad")
        default:
            print("[Platform] iOS – other")
        }
        #elseif os(tvOS)
        print("[Platform] tvOS")
        #endif
    }

    // MARK: - Platform root views

    #if os(iOS)
    // iOS: Tab-based navigation; each tab has its own NavigationStack and shows DetailView.
    private func iOSView() -> some View {
        TabView {
            ForEach(MenuItem.allCases.filter { !$0.isToggle }) { item in
                NavigationStack {
                    DetailView()
                        // ——— Top nav (toolbar) ———
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                OrbitControlButton()
                            }
                        }
                }
                // ——— Bottom nav (tab bar) ———
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

// MARK: - Detail View
// Shared content view used on iOS (and previously other platforms). Reads OrbitManager from environment.
struct DetailView: View {
    @EnvironmentObject private var orbitManager: OrbitManager

    var body: some View {
        ZStack {
            // ——— Main content ———
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
                    .foregroundColor(orbitManager.isEnabled ? .green : .red)

                Spacer()
            }
            .padding(64)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Orbit Control Button
// Button that toggles OrbitManager; used in toolbars. EnvironmentObject gives access to shared OrbitManager.
struct OrbitControlButton: View {
    @EnvironmentObject private var orbitManager: OrbitManager

    var body: some View {
        Button {
            orbitManager.toggle()
        } label: {
            Image(systemName: orbitManager.isEnabled ? "globe.desk.fill" : "globe.desk")
                .font(.title2)
                .foregroundColor(orbitManager.isEnabled ? .blue : .primary)
                .cornerRadius(12)
        }
    }
}

// MARK: - Menu Item Model (iOS only – tab bar items)
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

// Camera/view options for the top bar: named views (text only, no icons).
enum CameraView: String, CaseIterable, Identifiable {
    case front = "Front"
    case side = "Side"
    case rear = "Rear"
    case interior = "Interior"

    var id: String { rawValue }
    var title: String { rawValue }
}

// Shared config state for the tvOS configurator: camera, side menu, and bottom card selections.
class TVOSConfigurationManager: ObservableObject {
    @Published var selectedCamera: CameraView = .front
    @Published var selectedLeftOption: Int = 1
    @Published var configurations: [ConfigurationOption] = [
        ConfigurationOption(title: "Hull Color", choices: ["White", "Blue", "Red", "Black"]),
        ConfigurationOption(title: "Deck Style", choices: ["Classic", "Sport", "Luxury"]),
        ConfigurationOption(title: "Engine", choices: ["Standard", "Performance", "Eco"])
    ]
    @Published var selectedChoices: [UUID: String] = [:]
    @Published var activeBottomMenu: UUID? = nil
}

// Root tvOS view: top bar, left menu, center boat, bottom config cards.
// ignoresSafeArea + uniform padding so margins are equal on all 4 sides (tvOS safe area is asymmetric).
struct TVOSBoatConfiguratorView: View {
    @StateObject private var configManager = TVOSConfigurationManager()
    @StateObject private var touchPanel = TouchPanelObserver()
    @EnvironmentObject private var orbitManager: OrbitManager
    @FocusState private var focusedConfigCard: UUID?

    private let screenMargin: CGFloat = 32

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // ——— Top nav ———
                TopBarView(selectedCamera: $configManager.selectedCamera)

                HStack(spacing: 0) {
                    // ——— Side nav ———
                    LeftSideMenu(selectedOption: $configManager.selectedLeftOption)
                        .frame(width: 200)

                    // ——— Main content ———
                    BoatDisplayView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .environmentObject(touchPanel)
                }

                // ——— Bottom nav (maknuto kad je Orbit aktivan) ———
                if !orbitManager.isEnabled {
                    BottomConfigurationCards(configManager: configManager, focusedCard: $focusedConfigCard)
                        .padding(.horizontal, 24)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: orbitManager.isEnabled)
            .padding(screenMargin)
            .overlay(RoundedRectangle(cornerRadius: 0).stroke(Color.red, lineWidth: 1))

            // Overlay when a bottom card is active
            if let activeMenuId = configManager.activeBottomMenu,
               let option = configManager.configurations.first(where: { $0.id == activeMenuId }) {
                SelectionMenuOverlay(
                    option: option,
                    selectedChoice: Binding(
                        get: { configManager.selectedChoices[activeMenuId] ?? option.choices.first ?? "" },
                        set: { configManager.selectedChoices[activeMenuId] = $0 }
                    ),
                    onDismiss: {
                        let cardId = activeMenuId
                        focusedConfigCard = cardId
                        configManager.activeBottomMenu = nil
                    }
                )
            }
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
        .environmentObject(configManager)
    }
}

// Top bar (tvOS): Front/Side/Rear/Interior. Kad je Orbit aktivan, segment se uklanja iz layouta.
struct TopBarView: View {
    @Binding var selectedCamera: CameraView
    @EnvironmentObject private var orbitManager: OrbitManager

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
                                .font(.title3)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 15)
                                .background(selectedCamera == view ? Color.accentColor.opacity(0.3) : Color.clear)
                                .cornerRadius(10)
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
        .focusSection()
    }
}

// Left side menu (tvOS): View 1, View 2, Orbit. Kad je Orbit aktivan, ostaje samo gumb Orbit.
struct LeftSideMenu: View {
    @Binding var selectedOption: Int
    @EnvironmentObject private var orbitManager: OrbitManager

    private let menuOptions = [
        (title: "View 1", icon: "viewfinder"),
        (title: "View 2", icon: "camera.viewfinder"),
        (title: "Orbit", icon: "globe.desk")
    ]

    private var visibleOptions: [Int] {
        orbitManager.isEnabled ? [3] : [1, 2, 3]
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ForEach(visibleOptions, id: \.self) { option in
                Button {
                    selectedOption = option
                    if option == 3 {
                        orbitManager.toggle()
                    }
                } label: {
                    VStack(spacing: 0) {
                        Image(systemName: menuOptions[option - 1].icon)
                            .font(.title2)
                        Text(menuOptions[option - 1].title)
                            .font(.caption)
                    }
                    .frame(width: 160, height: 120)
                    .background(selectedOption == option ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.2))
                    .cornerRadius(15)
                }
                .buttonStyle(.card)
                .transition(.opacity)
            }

            Spacer()
        }
        .animation(.easeInOut(duration: 0.25), value: orbitManager.isEnabled)
        .focusSection()
    }
}

// Center boat display (tvOS): camera/orbit state. Kad je Orbit ON, ispisuje touch (x,y) i zoom razinu (dpad up/down).
struct BoatDisplayView: View {
    @EnvironmentObject private var orbitManager: OrbitManager
    @EnvironmentObject private var configManager: TVOSConfigurationManager
    @EnvironmentObject private var touchPanel: TouchPanelObserver

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
                    .foregroundColor(.blue)

                Text("View: \(configManager.selectedCamera.title)")
                    .font(.headline)

                Text("Orbit: \(orbitManager.isEnabled ? "ON" : "OFF")")
                    .font(.subheadline)
                    .foregroundColor(orbitManager.isEnabled ? .green : .secondary)

                if orbitManager.isEnabled {
                    VStack(spacing: 8) {
                        Text("Touch panel (remote)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("x: \(touchPanel.x, specifier: "%.3f")  y: \(touchPanel.y, specifier: "%.3f")")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                        Text(zoomLabel)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding()
                }
            }
        }
    }
}

// Bottom config cards (tvOS): tapping opens SelectionMenuOverlay. focusedCard restores focus to the card when overlay dismisses.
struct BottomConfigurationCards: View {
    @ObservedObject var configManager: TVOSConfigurationManager
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
        .frame(height: 180)
    }
}

// Single config card (tvOS): shows option title and current choice. focusedCard restores focus here when overlay dismisses.
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
                    .font(.headline)

                Text(selectedChoice)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(isActive ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.15))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(.card)
        .focused(focusedCard, equals: option.id)
    }
}

// Full-screen overlay for picking a choice; @FocusState drives focus for remote. Dismiss by selecting or tapping background.
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

            VStack(spacing: 0) {
                Text("Select \(option.title)")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(spacing: 0) {
                    ForEach(option.choices, id: \.self) { choice in
                        Button {
                            selectedChoice = choice
                            onDismiss()
                        } label: {
                            HStack {
                                Text(choice)
                                    .font(.title3)
                                Spacer()
                                if choice == selectedChoice {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.horizontal, 0)
                            .padding(.vertical, 0)
                            .frame(width: 500)
                            .background(choice == selectedChoice ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.2))
                            .cornerRadius(15)
                        }
                        .buttonStyle(.card)
                        .focused($focusedChoice, equals: choice)
                    }
                }
            }
            .padding(0)
            .background(Color(white: 0.15))
            .cornerRadius(30)
            .shadow(radius: 20)
        }
        .onAppear {
            focusedChoice = selectedChoice
        }
    }
}

#endif
