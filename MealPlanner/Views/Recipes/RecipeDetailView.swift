import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recipe: Recipe  // Remplacé @ObservedObject par @Bindable
    @State private var showingAddIngredient = false
    @State private var showingEditRecipe = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Photo de la recette
                if let photoData = recipe.photo, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(10)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .padding()
                        .foregroundColor(.secondary)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                // Description
                if let details = recipe.details, !details.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Description")
                            .font(.headline)
                        Text(details)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal)
                }
                
                // Ingrédients
                VStack(alignment: .leading) {
                    HStack {
                        Text("Ingrédients par personne")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            showingAddIngredient = true
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                    }
                    
                    if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                        ForEach(ingredients) { recipeIngredient in
                            if let ingredient = recipeIngredient.ingredient {
                                HStack {
                                    Text("\(ingredient.name)")
                                    
                                    Spacer()
                                    
                                    Text("\(String(format: "%.1f", recipeIngredient.quantity)) \(ingredient.unit)")
                                        .foregroundColor(.secondary)
                                    
                                    if recipeIngredient.isOptional {
                                        Text("(optionnel)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .italic()
                                    }
                                    
                                    Button {
                                        removeIngredient(recipeIngredient)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } else {
                        Text("Aucun ingrédient")
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(recipe.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEditRecipe = true
                } label: {
                    Text("Modifier")
                }
            }
        }
        .sheet(isPresented: $showingAddIngredient) {
            AddRecipeIngredientView(recipe: recipe)
        }
        .sheet(isPresented: $showingEditRecipe) {
            EditRecipeView(recipe: recipe)
        }
    }
    
    private func removeIngredient(_ recipeIngredient: RecipeIngredient) {
        if let index = recipe.ingredients?.firstIndex(where: { $0.id == recipeIngredient.id }) {
            recipe.ingredients?.remove(at: index)
            modelContext.delete(recipeIngredient)
        }
    }
}

struct AddRecipeIngredientView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var recipe: Recipe  // Remplacé @ObservedObject par @Bindable
    
    @State private var selectedIngredient: Ingredient?
    @State private var quantity: Double = 1.0
    @State private var isOptional: Bool = false
    @State private var searchText = ""
    
    @Query private var ingredients: [Ingredient]
    
    var filteredIngredients: [Ingredient] {
        if searchText.isEmpty {
            return ingredients
        } else {
            return ingredients.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Rechercher un ingrédient")) {
                    TextField("Nom de l'ingrédient", text: $searchText)
                }
                
                Section(header: Text("Ingrédients")) {
                    List(filteredIngredients) { ingredient in
                        Button {
                            selectedIngredient = ingredient
                        } label: {
                            HStack {
                                Text(ingredient.name)
                                Spacer()
                                if selectedIngredient?.id == ingredient.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section(header: Text("Quantité")) {
                    HStack {
                        Text("Quantité par personne")
                        Spacer()
                        TextField("Quantité", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(selectedIngredient?.unit ?? "")
                    }
                    
                    Toggle("Ingrédient optionnel", isOn: $isOptional)
                }
                
                Section {
                    Button("Ajouter à la recette") {
                        addIngredientToRecipe()
                    }
                    .disabled(selectedIngredient == nil)
                }
            }
            .navigationTitle("Ajouter un ingrédient")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addIngredientToRecipe() {
        guard let ingredient = selectedIngredient else { return }
        
        let recipeIngredient = RecipeIngredient(
            recipe: recipe,
            ingredient: ingredient,
            quantity: quantity,
            isOptional: isOptional
        )
        
        modelContext.insert(recipeIngredient)
        
        if recipe.ingredients == nil {
            recipe.ingredients = [recipeIngredient]
        } else {
            recipe.ingredients?.append(recipeIngredient)
        }
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Recipe.self, Ingredient.self, RecipeIngredient.self,
        configurations: config
    )
    
    let context = container.mainContext
    
    // Créer un exemple de recette
    let recipe = Recipe(name: "Pâtes à la carbonara", details: "Un classique italien facile et délicieux.")
    
    let spaghettiIngredient = Ingredient(name: "Spaghetti", category: "Pâtes", unit: "g")
    let baconIngredient = Ingredient(name: "Lardons", category: "Viandes", unit: "g")
    let eggIngredient = Ingredient(name: "Œuf", category: "Produits laitiers", unit: "pièce(s)")
    let cheeseIngredient = Ingredient(name: "Parmesan", category: "Produits laitiers", unit: "g")
    
    context.insert(recipe)
    context.insert(spaghettiIngredient)
    context.insert(baconIngredient)
    context.insert(eggIngredient)
    context.insert(cheeseIngredient)
    
    let ingredient1 = RecipeIngredient(recipe: recipe, ingredient: spaghettiIngredient, quantity: 100, isOptional: false)
    let ingredient2 = RecipeIngredient(recipe: recipe, ingredient: baconIngredient, quantity: 50, isOptional: false)
    let ingredient3 = RecipeIngredient(recipe: recipe, ingredient: eggIngredient, quantity: 1, isOptional: false)
    let ingredient4 = RecipeIngredient(recipe: recipe, ingredient: cheeseIngredient, quantity: 20, isOptional: false)
    
    context.insert(ingredient1)
    context.insert(ingredient2)
    context.insert(ingredient3)
    context.insert(ingredient4)
    
    return NavigationStack {
        RecipeDetailView(recipe: recipe)
    }
    .modelContainer(container)
}
