import SwiftUI
import SwiftData

struct AddShoppingItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let shoppingList: ShoppingList
    
    @State private var selectedIngredient: Ingredient?
    @State private var quantity: Double = 1.0
    @State private var showingIngredientSearch = false
    
    @Query private var ingredients: [Ingredient]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ingrédient")) {
                    if let ingredient = selectedIngredient {
                        HStack {
                            Text(ingredient.name)
                            Spacer()
                            Button("Changer") {
                                showingIngredientSearch = true
                            }
                        }
                    } else {
                        Button("Sélectionner un ingrédient") {
                            showingIngredientSearch = true
                        }
                    }
                }
                
                if selectedIngredient != nil {
                    Section(header: Text("Quantité")) {
                        HStack {
                            Text("Quantité")
                            Spacer()
                            TextField("Quantité", value: $quantity, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text(selectedIngredient?.unit ?? "")
                        }
                    }
                }
                
                Section {
                    Button("Ajouter à la liste") {
                        addItemToShoppingList()
                    }
                    .disabled(selectedIngredient == nil)
                }
            }
            .navigationTitle("Ajouter un article")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingIngredientSearch) {
                IngredientSearchView(
                    viewModel: IngredientsViewModel(modelContext: modelContext),
                    onIngredientSelected: { ingredient in
                        selectedIngredient = ingredient
                        showingIngredientSearch = false
                    }
                )
            }
        }
    }
    
    private func addItemToShoppingList() {
        guard let ingredient = selectedIngredient else { return }
        
        // Vérifier si l'ingrédient existe déjà dans la liste
        if let existingItems = shoppingList.items,
           let existingItem = existingItems.first(where: { $0.ingredient?.id == ingredient.id }) {
            // Si oui, augmenter la quantité
            existingItem.quantity += quantity
        } else {
            // Sinon, créer un nouvel élément
            let newItem = ShoppingListItem(
                shoppingList: shoppingList,
                ingredient: ingredient,
                quantity: quantity
            )
            
            modelContext.insert(newItem)
            
            if shoppingList.items == nil {
                shoppingList.items = [newItem]
            } else {
                shoppingList.items?.append(newItem)
            }
        }
        
        // Mettre à jour la date de modification
        shoppingList.modificationDate = Date()
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Recipe.self, Ingredient.self, RecipeIngredient.self,
        ShoppingList.self, ShoppingListItem.self,
        configurations: config
    )
    
    let context = container.mainContext
    
    // Créer un exemple de liste de courses
    let shoppingList = ShoppingList()
    context.insert(shoppingList)
    
    // Créer quelques ingrédients
    let carotte = Ingredient(name: "Carotte", category: "Fruits et légumes", unit: "pièce(s)")
    let tomate = Ingredient(name: "Tomate", category: "Fruits et légumes", unit: "pièce(s)")
    
    context.insert(carotte)
    context.insert(tomate)
    
    return AddShoppingItemView(shoppingList: shoppingList)
        .modelContainer(container)
}
