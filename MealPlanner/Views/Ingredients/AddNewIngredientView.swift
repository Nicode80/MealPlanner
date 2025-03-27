import SwiftUI
import SwiftData

struct AddNewIngredientView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var viewModel: IngredientsViewModel
    var onIngredientCreated: (Ingredient) -> Void
    
    @State private var name: String = ""
    @State private var category: String = "Fruits et légumes"
    @State private var unit: String = "pièce(s)"
    @State private var showingSimilarIngredientAlert = false
    @State private var similarIngredient: Ingredient?
    @State private var nameEdited = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informations de l'ingrédient")) {
                    TextField("Nom", text: $name)
                        .onChange(of: name) { oldValue, newValue in
                            nameEdited = true
                        }
                        .onSubmit {
                            checkForSimilarIngredient()
                        }
                    
                    Picker("Catégorie", selection: $category) {
                        ForEach(viewModel.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .onChange(of: category) { _, _ in
                        if nameEdited {
                            checkForSimilarIngredient()
                        }
                    }
                    
                    Picker("Unité", selection: $unit) {
                        ForEach(viewModel.units, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .onChange(of: unit) { _, _ in
                        if nameEdited {
                            checkForSimilarIngredient()
                        }
                    }
                }
            }
            .navigationTitle("Nouvel ingrédient")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        if let ingredient = addIngredient() {
                            onIngredientCreated(ingredient)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || category.isEmpty || unit.isEmpty)
                }
            }
            .alert(isPresented: $showingSimilarIngredientAlert) {
                Alert(
                    title: Text("Ingrédient similaire trouvé"),
                    message: Text("Vouliez-vous dire \"\(similarIngredient?.name ?? "")\"?"),
                    primaryButton: .default(Text("Oui")) {
                        if let ingredient = similarIngredient {
                            // Utiliser l'ingrédient existant
                            onIngredientCreated(ingredient)
                            dismiss()
                        }
                    },
                    secondaryButton: .cancel(Text("Non, créer nouveau"))
                )
            }
        }
    }
    
    private func addIngredient() -> Ingredient? {
        // Utilisez le ViewModel pour ajouter l'ingrédient
        return viewModel.addIngredient(name: name, category: category, unit: unit)
    }
    
    private func checkForSimilarIngredient() {
        if let similar = viewModel.checkForSimilarIngredient(name: name) {
            similarIngredient = similar
            showingSimilarIngredientAlert = true
            nameEdited = false
        }
    }
}
