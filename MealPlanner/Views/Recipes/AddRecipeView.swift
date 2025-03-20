import SwiftUI
import SwiftData
import PhotosUI

struct AddRecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var details = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var photoData: Data?
    
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
                        .onChange(of: selectedItem) { newItem, _ in
                            if let newItem {
                                Task {
                                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                                        photoData = data
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
                    Button("Créer la recette") {
                        addRecipe()
                    }
                    .disabled(name.isEmpty)
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
        }
    }
    
    private func addRecipe() {
        let newRecipe = Recipe(
            name: name,
            details: details.isEmpty ? nil : details,
            photo: photoData
        )
        
        modelContext.insert(newRecipe)
        dismiss()
    }
}

#Preview {
    AddRecipeView()
}
