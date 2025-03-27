import SwiftUI
import SwiftData

struct AddNewIngredientView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var viewModel: IngredientsViewModel
    var forRecipe: Bool = true
    var onIngredientCreated: (Ingredient) -> Void
    
    @State private var name: String = ""
    @State private var category: String = "Fruits et légumes"
    @State private var unit: String = "pièce(s)"
    @State private var showingSimilarIngredientAlert = false
    @State private var similarIngredient: Ingredient?
    @State private var nameEdited = false
    @State private var attemptedToAdd = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informations de l'ingrédient")) {
                    TextField("Nom", text: $name)
                        .onChange(of: name) { oldValue, newValue in
                            nameEdited = true
                            // Vérifier les similitudes dès que le nom change
                            // si l'utilisateur a tapé au moins 3 caractères
                            if newValue.count >= 3 {
                                checkForSimilarIngredient()
                            }
                        }
                        .onSubmit {
                            checkForSimilarIngredient()
                        }
                    
                    Picker("Catégorie", selection: $category) {
                        ForEach(viewModel.getCategories(forRecipe: forRecipe), id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .onChange(of: category) { _, _ in
                        if nameEdited && name.count >= 3 {
                            checkForSimilarIngredient()
                        }
                    }
                    
                    Picker("Unité", selection: $unit) {
                        ForEach(viewModel.units, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .onChange(of: unit) { _, _ in
                        if nameEdited && name.count >= 3 {
                            checkForSimilarIngredient()
                        }
                    }
                }
                
                if forRecipe {
                    Section(header: Text("Remarque")) {
                        Text("Cet ingrédient sera utilisé dans les recettes. Assurez-vous qu'il s'agit bien d'un aliment.")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                        attemptedToAdd = true
                        // Vérifier une dernière fois avant d'ajouter
                        if let similar = viewModel.checkForSimilarIngredient(name: name) {
                            similarIngredient = similar
                            showingSimilarIngredientAlert = true
                        } else {
                            // Aucun doublon, on peut ajouter
                            if let ingredient = addIngredient() {
                                onIngredientCreated(ingredient)
                                dismiss()
                            }
                        }
                    }
                    .disabled(name.isEmpty || category.isEmpty || unit.isEmpty)
                }
            }
            .alert(isPresented: $showingSimilarIngredientAlert) {
                Alert(
                    title: Text("Ingrédient similaire trouvé"),
                    message: Text("Vouliez-vous dire \"\(similarIngredient?.name ?? "")\"?"),
                    primaryButton: .default(Text("Oui, utiliser existant")) {
                        if let ingredient = similarIngredient {
                            // Utiliser l'ingrédient existant
                            onIngredientCreated(ingredient)
                            dismiss()
                        }
                    },
                    secondaryButton: .cancel(Text("Non, créer nouveau")) {
                        if attemptedToAdd {
                            // L'utilisateur a explicitement refusé la suggestion lors de l'ajout
                            // On force la création d'un nouvel ingrédient
                            let newIngredient = Ingredient(name: name, category: category, unit: unit)
                            modelContext.insert(newIngredient)
                            try? modelContext.save()
                            viewModel.fetchIngredients()
                            onIngredientCreated(newIngredient)
                            dismiss()
                        }
                    }
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
