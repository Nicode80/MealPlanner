import SwiftUI
import SwiftData
import PhotosUI

struct AddRecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RecipeViewModel?
    @State private var selectedItem: PhotosPickerItem?
    
    // Ajout de la variable pour le focus
    @FocusState private var isNameFieldFocused: Bool
    
    // États pour le suivi de l'optimisation des images
    @State private var originalImageData: Data?
    @State private var originalImageSize: CGSize = .zero
    @State private var optimizedImageData: Data?
    @State private var optimizedImageSize: CGSize = .zero
    @State private var showOptimizationResult = false
    
    // Nouveau: On utilise un Binding pour contrôler la navigation externe
    var onRecipeCreated: ((Recipe) -> Void)?
    
    var body: some View {
        NavigationView {
            Form {
                if let vm = viewModel {
                    Section(header: Text("Informations générales")) {
                        TextField("Nom de la recette", text: Binding(
                            get: { vm.newRecipeName },
                            set: { vm.newRecipeName = $0 }
                        ))
                        .focused($isNameFieldFocused) // Ajout du modificateur focused
                        
                        TextField("Description (optionnelle)", text: Binding(
                            get: { vm.newRecipeDetails },
                            set: { vm.newRecipeDetails = $0 }
                        ), axis: .vertical)
                        .lineLimit(5...10)
                    }
                    
                    Section(header: Text("Photo (optionnelle)")) {
                        VStack {
                            if let photoData = vm.newRecipePhotoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(8)
                            }
                            
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Label(vm.newRecipePhotoData == nil ? "Ajouter une photo" : "Changer la photo", systemImage: "photo")
                            }
                            .onChange(of: selectedItem) { _, newItem in
                                if let newItem {
                                    Task {
                                        if let data = try? await newItem.loadTransferable(type: Data.self),
                                           let originalImage = UIImage(data: data) {
                                            
                                            // Stocker les informations de l'image originale
                                            await MainActor.run {
                                                originalImageData = data
                                                originalImageSize = originalImage.size
                                            }
                                            
                                            print("Image originale chargée: \(originalImage.size.width) × \(originalImage.size.height), \(data.count) bytes")
                                            
                                            // Optimiser l'image
                                            if let optimizedData = originalImage.optimizedImageData() {
                                                // Récupérer l'image optimisée pour voir ses dimensions
                                                if let optimizedImage = UIImage(data: optimizedData) {
                                                    print("Image optimisée créée: \(optimizedImage.size.width) × \(optimizedImage.size.height), \(optimizedData.count) bytes")
                                                    
                                                    await MainActor.run {
                                                        // Mettre à jour les variables d'état avec les données optimisées
                                                        optimizedImageData = optimizedData
                                                        optimizedImageSize = optimizedImage.size
                                                        
                                                        // Affecter au ViewModel
                                                        vm.newRecipePhotoData = optimizedData
                                                        
                                                        // Afficher les résultats
                                                        showOptimizationResult = true
                                                    }
                                                } else {
                                                    print("Erreur: Impossible de créer l'image optimisée")
                                                    await MainActor.run {
                                                        vm.newRecipePhotoData = data
                                                    }
                                                }
                                            } else {
                                                print("Erreur: Échec de l'optimisation")
                                                await MainActor.run {
                                                    vm.newRecipePhotoData = data
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            if vm.newRecipePhotoData != nil {
                                Button("Supprimer la photo", role: .destructive) {
                                    vm.newRecipePhotoData = nil
                                    selectedItem = nil
                                }
                            }
                        }
                    }
                    
                    Section {
                        Button("Créer la recette") {
                            if let recipe = vm.createRecipe() {
                                dismiss()
                                // Appeler le callback pour naviguer vers la vue détaillée
                                onRecipeCreated?(recipe)
                            }
                        }
                        .disabled(vm.newRecipeName.isEmpty)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Nouvelle recette")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Initialiser le ViewModel avec le modelContext de l'environment
                if viewModel == nil {
                    viewModel = RecipeViewModel(modelContext: modelContext)
                }
                // Activer le focus après un court délai
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isNameFieldFocused = true
                }
            }
            .sheet(isPresented: $showOptimizationResult) {
                OptimizationResultView(
                    originalData: originalImageData,
                    originalSize: originalImageSize,
                    optimizedData: optimizedImageData,
                    optimizedSize: optimizedImageSize
                )
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Recipe.self, Article.self, RecipeArticle.self,
        configurations: config
    )
    return AddRecipeView()
        .modelContainer(container)
}
