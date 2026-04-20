import SwiftUI

@main
struct VeneredApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State var isLoggedIn = false
    @State var currentScreen = "home"
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if !isLoggedIn {
            LoginView(isLoggedIn: $isLoggedIn)
                .preferredColorScheme(nil)
        } else {
            TabView(selection: $currentScreen) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag("home")

                ExploreView()
                    .tabItem {
                        Label("Explorar", systemImage: "magnifyingglass")
                    }
                    .tag("explore")

                MessagesView()
                    .tabItem {
                        Label("Mensajes", systemImage: "message.fill")
                    }
                    .tag("messages")

                ProfileView()
                    .tabItem {
                        Label("Perfil", systemImage: "person.fill")
                    }
                    .tag("profile")
            }
            .preferredColorScheme(nil)
        }
    }
}

struct LoginView: View {
    @State var email = ""
    @State var password = ""
    @State var isLoading = false
    @State var error: String?
    @Binding var isLoggedIn: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Venered")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(
                            colorScheme == .dark 
                                ? VeneredColors.darkPrimary 
                                : VeneredColors.lightPrimary
                        )
                    
                    Text("Red Social")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 32)

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .padding(.horizontal, 16)

                SecureField("Contraseña", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 16)

                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 16)
                }

                Button(action: {
                    isLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isLoggedIn = true
                        isLoading = false
                    }
                }) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Iniciar sesión")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isLoading)
                .buttonStyle(.bordered)
                .padding(.horizontal, 16)

                Spacer()

                HStack {
                    Text("¿No tienes cuenta?")
                    Text("Regístrate")
                        .fontWeight(.bold)
                        .foregroundColor(
                            colorScheme == .dark 
                                ? VeneredColors.darkPrimary 
                                : VeneredColors.lightPrimary
                        )
                }
                .padding(.horizontal, 16)
            }
            .padding(24)
            .background(
                colorScheme == .dark 
                    ? VeneredColors.darkBackground 
                    : VeneredColors.lightBackground
            )
        }
    }
}

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { i in
                        PostCardView(title: "Post \(i+1)", content: "Contenido del post...")
                    }
                }
                .padding(16)
            }
            .navigationTitle("Venered")
            .background(
                colorScheme == .dark 
                    ? VeneredColors.darkBackground 
                    : VeneredColors.lightBackground
            )
        }
    }
}

struct PostCardView: View {
    let title: String
    let content: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(
                        colorScheme == .dark 
                            ? VeneredColors.darkPrimary.opacity(0.3)
                            : VeneredColors.lightPrimary.opacity(0.3)
                    )
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .fontWeight(.bold)
                    Text("hace 2 horas")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            Text(content)
                .font(.body)
            
            HStack(spacing: 16) {
                Label("5", systemImage: "heart")
                    .font(.caption)
                Label("2", systemImage: "bubble.right")
                    .font(.caption)
                Label("1", systemImage: "square.and.arrow.up")
                    .font(.caption)
            }
        }
        .padding(12)
        .background(
            colorScheme == .dark 
                ? VeneredColors.darkSurface 
                : VeneredColors.lightSurface
        )
        .cornerRadius(CGFloat(VeneredCornerRadius.large))
    }
}

struct ExploreView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Explorar")
                    .navigationTitle("Explorar")
            }
        }
    }
}

struct MessagesView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Mensajes")
                    .navigationTitle("Mensajes")
            }
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Mi perfil")
                    .navigationTitle("Perfil")
            }
        }
    }
}

#Preview {
    VeneredApp()
}
