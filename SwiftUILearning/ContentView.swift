import SwiftUI
import Combine // ← DODAJ OVO

// MARK: - Orbit Manager (Shared State)
class OrbitManager: ObservableObject {
    @Published var isEnabled = false
    
    func toggle() {
        isEnabled.toggle()
    }
}

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var orbitManager = OrbitManager()
  
    var body: some View {
        Group {
            #if os(macOS)
            macOSView()
            #elseif os(iOS)
            iOSView()
            #elseif os(tvOS)
            tvOSView()
            #elseif os(visionOS)
            visionOSView()
            #endif
        }
        .environmentObject(orbitManager)
        .frame(
            minWidth: platformMinWidth(),
            maxWidth: platformMaxWidth(),
            minHeight: platformMinHeight(),
            maxHeight: platformMaxHeight()
        )
    }
    
    // MARK: - Platform Views
    
    #if os(macOS)
    private func macOSView() -> some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
                .toolbar {
                    ToolbarItemGroup(placement: .principal) {
                        HStack(spacing: 20) {
                            Button {
                                // Camera 1
                            } label: {
                                Label("Camera 1", systemImage: "1.circle")
                            }
                            
                            Button {
                                // Camera 2
                            } label: {
                                Label("Camera 2", systemImage: "2.circle")
                            }
                            
                            Button {
                                // Camera 3
                            } label: {
                                Label("Camera 3", systemImage: "3.circle")
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .automatic) {
                        OrbitControlButton()
                    }
                }
        }
    }
    #endif
    
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
        TabView {
            ForEach(MenuItem.allCases.filter { !$0.isToggle }) { item in
                NavigationStack {
                    DetailView()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                
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

#if os(visionOS)
private func visionOSView() -> some View {
    NavigationStack {
        DetailView()
            .toolbar {
                ToolbarItemGroup(placement: .bottomOrnament) {
                    HStack(spacing: 20) {
                        Button {
                            // Camera 1
                        } label: {
                            Label("Camera 1", systemImage: "1.circle")
                                .labelStyle(.iconOnly)
                        }
                        
                        Button {
                            // Camera 2
                        } label: {
                            Label("Camera 2", systemImage: "2.circle")
                                .labelStyle(.iconOnly)
                        }
                        
                        Button {
                            // Camera 3
                        } label: {
                            Label("Camera 3", systemImage: "3.circle")
                                .labelStyle(.iconOnly)
                        }
                        
                        Divider()
                            .frame(height: 20)
                        
                        OrbitControlButton()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
    }
}
#endif
    
    // MARK: - Window Size Configuration
    
    private func platformMinWidth() -> CGFloat? {
        #if os(macOS)
        return 800
        #else
        return nil
        #endif
    }

    private func platformMaxWidth() -> CGFloat? {
        #if os(macOS)
        return 1200
        #else
        return nil
        #endif
    }

    private func platformMinHeight() -> CGFloat? {
        #if os(macOS)
        return 600
        #else
        return nil
        #endif
    }

    private func platformMaxHeight() -> CGFloat? {
        #if os(macOS)
        return 800
        #else
        return nil
        #endif
    }
}

// MARK: - Detail View
struct DetailView: View {
    @EnvironmentObject private var orbitManager: OrbitManager
    
    var body: some View {
        ZStack {
            // Main content
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
struct OrbitControlButton: View {
    @EnvironmentObject private var orbitManager: OrbitManager
    
    var body: some View {
        Button {
            orbitManager.toggle()
        }
        label: {
                Image(systemName: orbitManager.isEnabled ? "globe.desk.fill" : "globe.desk")
                    .font(.title2)
            .foregroundColor(orbitManager.isEnabled ? .blue : .primary)
            .cornerRadius(12)
        }
    }
}

// MARK: - Menu Item Model
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
