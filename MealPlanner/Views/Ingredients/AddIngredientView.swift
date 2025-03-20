import SwiftUI
import SwiftData

struct AddIngredientView: View {
    @Binding var name: String
    @Binding var category: String
    @Binding var unit: String
    
    var onAdd: (String, String, String) -> Void
    var onCancel: () -> Void
    
    // Liste prédéfinie de catégories pour éviter les variations
    let categories = [
        "Fruits et légumes", "Viandes", "Poissons et fruits de mer",
        "Produits laitiers", "Boulangerie", "Épicerie sucrée",
        "Épicerie salée", "Boissons", "Surgelés", "Hygiène"
    ]
    
    // Liste prédéfinie d'unités pour éviter les variations
    let units = ["g", "kg", "ml", "l", "pièce(s)", "tranche(s)", "cuillère(s) à café", "cuillère(s) à soupe"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informations de l'ingrédient")) {
                    TextField("Nom", text: $name)
                    
                    Picker("Catégorie", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    Picker("Unité", selection: $unit) {
                        ForEach(units, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                }
            }
            .navigationTitle("Nouvel ingrédient")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        onAdd(name, category, unit)
                    }
                    .disabled(name.isEmpty || category.isEmpty || unit.isEmpty)
                }
            }
        }
    }
}

// Structure pour prévisualiser avec des State plutôt que des Binding
struct AddIngredientViewPreview: View {
    @State private var name = "Oignon"
    @State private var category = "Fruits et légumes"
    @State private var unit = "pièce(s)"
    
    var body: some View {
        AddIngredientView(
            name: $name,
            category: $category,
            unit: $unit,
            onAdd: { _, _, _ in },
            onCancel: { }
        )
    }
}

#Preview {
    AddIngredientViewPreview()
}
