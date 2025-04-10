import SwiftUI
import PhotosUI

/// Vue dédiée au test et à la démonstration de l'optimisation d'images
struct ImageOptimizationTestView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var originalImageData: Data?
    @State private var originalImageSize: CGSize = .zero
    @State private var optimizedImageData: Data?
    @State private var optimizedImageSize: CGSize = .zero
    @State private var isOptimizing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Section de sélection d'image
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Sélectionner une image", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    if let data = originalImageData, let image = UIImage(data: data) {
                        // Afficher l'image sélectionnée
                        Text("Image originale")
                            .font(.headline)
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 250)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                        
                        // Afficher les statistiques de diagnostic
                        if isOptimizing {
                            ProgressView("Optimisation en cours...")
                        } else if let optimizedData = optimizedImageData {
                            OptimizationResultView(
                                originalData: originalImageData,
                                originalSize: originalImageSize,
                                optimizedData: optimizedData,
                                optimizedSize: optimizedImageSize
                            )
                            .padding(.horizontal)
                        }
                    } else {
                        // Message quand aucune image n'est sélectionnée
                        ContentUnavailableView(
                            "Aucune image sélectionnée",
                            systemImage: "photo.badge.plus",
                            description: Text("Sélectionnez une image pour tester l'optimisation")
                        )
                        .frame(height: 300)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Test d'optimisation")
            .onChange(of: selectedItem) { _, newItem in
                if let newItem {
                    isOptimizing = true
                    
                    // Réinitialiser les données
                    originalImageData = nil
                    optimizedImageData = nil
                    
                    Task {
                        // Charger l'image sélectionnée
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let originalImage = UIImage(data: data) {
                            
                            // Stocker les informations de l'image originale
                            await MainActor.run {
                                originalImageData = data
                                originalImageSize = originalImage.size
                            }
                            
                            // Optimiser l'image
                            if let optimizedData = originalImage.optimizedImageData(),
                               let optimizedImage = UIImage(data: optimizedData) {
                                
                                // Léger délai pour l'effet visuel
                                try? await Task.sleep(nanoseconds: 500_000_000)
                                
                                await MainActor.run {
                                    optimizedImageData = optimizedData
                                    optimizedImageSize = optimizedImage.size
                                    isOptimizing = false
                                }
                            } else {
                                await MainActor.run {
                                    isOptimizing = false
                                }
                            }
                        } else {
                            await MainActor.run {
                                isOptimizing = false
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ImageOptimizationTestView()
}
