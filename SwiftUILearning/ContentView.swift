import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
   
  
    var body: some View {
        Group {
            #if os(macOS)
            macOSView()
            #elseif os(iOS)
            iOSView()
            #elseif os(tvOS)
            tvOSView()
            #elseif os(visionOS)
            visionOSView()  // ← DODAJ
            #endif
        }
        .frame(
            minWidth: platformMinWidth(),
            maxWidth: platformMaxWidth(),
            minHeight: platformMinHeight(),
            maxHeight: platformMaxHeight()
        )
    }
    
    // MARK: - Platform Views
    
    private func macOSView() -> some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
            
        }
    }
    
    private func iOSView() -> some View {
        TabView {
            ForEach(MenuItem.allCases) { item in  // ← MAKNI .filter
                NavigationView {
                    DetailView()
                        .navigationTitle(item.title)
                }
                .tabItem {
                    Label(item.title, systemImage: item.icon)
                }
                .tag(item)
            }
        }
    }

    private func tvOSView() -> some View {
        TabView {
            ForEach(MenuItem.allCases) { item in  // ← MAKNI .filter
                NavigationView {
                    DetailView()
                        .navigationTitle(item.title)
                }
                .tabItem {
                    VStack {
                        Image(systemName: item.icon)
                        Text(item.title)
                    }
                }
                .tag(item)
            }
        }
    }

    private func visionOSView() -> some View {
        TabView {
            ForEach(MenuItem.allCases) { item in  // ← MAKNI .filter
                NavigationView {
                    DetailView()
                        .navigationTitle(item.title)
                }
                .tabItem {
                    Label(item.title, systemImage: item.icon)
                }
                .tag(item)
            }
        }
    }
    
    // MARK: - Window Size Configuration
    
    private func platformMinWidth() -> CGFloat? {
        #if os(macOS)
        return 800
        #else
        return nil  // iOS, tvOS, visionOS - puni ekran
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
}  // ← ZATVORI ContentView OVDJE!

// MARK: - Sidebar View (macOS)
struct SidebarView: View {
    @State private var toggleValue: Bool = false
    
    var body: some View {
        List(MenuItem.allCases) { item in
            if item.isToggle {
                Toggle(item.title, isOn: $toggleValue)
            } else {
                NavigationLink {
                    DetailView()
                        .navigationTitle(item.title)
                } label: {
                    Label(item.title, systemImage: item.icon)
                }
            }
        }
        #if os(macOS)
        .listStyle(SidebarListStyle())
        .transaction { transaction in  transaction.animation = .spring()}
        #endif
        .navigationTitle("Menu")
        .transaction { transaction in  transaction.animation = .bouncy()}
    }
}

// MARK: - Detail View
struct DetailView: View {
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "car.rear.fill")
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.blue)
                .frame(width: 96)
            
            Divider()
            
            Text("Hello, world!")
                .font(.title)
            
            Text("3 of something")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
