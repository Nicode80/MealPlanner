import SwiftUI
import SwiftData
import PhotosUI

struct EditRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var recipe: Recipe
    @State private var name: String
    @State private var details: String
    @State private var selectedItem: PhotosPickerItem?
    @State private var photoData: Data?
    
    init(recipe: Recipe) {
        self.recipe = recipe
        _name = State(initialValue: recipe.name)
        _details = State(initialValue: recipe.details ?? "")
        _photoData = State(initialValue: recipe.photo)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informations générales")) {
                    TextField("Nom de la recette", text: $name)
                    TextField("Description (optionnelle)", text: $details, axis: .vertical)
                        .lineLimit(5...10)
                }
                
                Section(header: Text("Photo (optionnelle)")) {
                    VStack {
                        if let photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                        }
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Label(photoData == nil ? "Ajouter une photo" : "Changer la photo", systemImage: "photo")
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            if let newItem {
                                Task {
                                    if let data = try? await newItem.loadTransferable(type: Data.self),
                                       let originalImage = UIImage(data: data) {
                                        // Optimiser l'image
                                        if let optimizedData = originalImage.optimizedImageData() {
                                            await MainActor.run {
                                                photoData = optimizedData
                                            }
                                        } else {
                                            await MainActor.run {
                                                photoData = data
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        if photoData != nil {
                            Button("Supprimer la photo", role: .destructive) {
                                photoData = nil
                                selectedItem = nil
                            }
                        }
                    }
                }
                
                Section {
                    Button("Enregistrer les modifications") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("Modifier la recette")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        recipe.name = name
        recipe.details = details.isEmpty ? nil : details
        recipe.photo = photoData
        dismiss()
    }
}

struct EditRecipeView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Recipe.self, Article.self, RecipeArticle.self,
            configurations: config
        )
        let context = container.mainContext
        // Créer un exemple de recette
        let recipe = Recipe(name: "Pâtes à la carbonara", details: "Un classique italien facile et délicieux.")
        context.insert(recipe)
        return EditRecipeView(recipe: recipe)
            .modelContainer(container)
    }
}
