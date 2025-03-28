import SwiftUI
import SwiftData
import PhotosUI

struct AddRecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: RecipeViewModel?
    @State private var selectedItem: PhotosPickerItem?
    
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
                                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                                            vm.newRecipePhotoData = data
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
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Recipe.self, Article.self, RecipeIngredient.self,
        configurations: config
    )
    
    AddRecipeView()
        .modelContainer(container)
}
