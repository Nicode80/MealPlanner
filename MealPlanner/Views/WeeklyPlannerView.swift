import SwiftUI
import SwiftData

// Structure pour représenter un repas planifié
struct PlannedMeal: Identifiable {
    var id = UUID()
    var recipe: Recipe
    var numberOfPeople: Int
    var dayOfWeek: Int // 0 = Lundi, 1 = Mardi, etc.
    var mealType: MealType
    
    enum MealType: String, CaseIterable, Identifiable {
        case breakfast = "Petit-déjeuner"
        case lunch = "Déjeuner"
        case dinner = "Dîner"
        
        var id: String { self.rawValue }
    }
}

struct WeeklyPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var recipes: [Recipe]
    @Query private var shoppingLists: [ShoppingList]
    
    @State private var plannedMeals: [PlannedMeal] = []
    @State private var showingAddMeal = false
    @State private var selectedDay = 0
    @State private var selectedMealType = PlannedMeal.MealType.dinner
    
    let daysOfWeek = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
    
    var body: some View {
        List {
            ForEach(daysOfWeek.indices, id: \.self) { dayIndex in
                Section(header: Text(daysOfWeek[dayIndex])) {
                    ForEach(PlannedMeal.MealType.allCases) { mealType in
                        VStack(alignment: .leading) {
                            Text(mealType.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            let mealsForThisSlot = plannedMeals.filter {
                                $0.dayOfWeek == dayIndex && $0.mealType == mealType
                            }
                            
                            if mealsForThisSlot.isEmpty {
                                Button(action: {
                                    selectedDay = dayIndex
                                    selectedMealType = mealType
                                    showingAddMeal = true
                                }) {
                                    Text("+ Ajouter un repas")
                                        .foregroundColor(.blue)
                                }
                            } else {
                                ForEach(mealsForThisSlot) { meal in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(meal.recipe.name)
                                                .font(.headline)
                                            Text("Pour \(meal.numberOfPeople) personne(s)")
                                                .font(.caption)
                                        }
                                        
                                        Spacer()
                                        
                                        Button {
                                            removePlannedMeal(meal)
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Planning de la semaine")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    generateShoppingList()
                } label: {
                    Text("Générer la liste")
                }
                .disabled(plannedMeals.isEmpty)
            }
        }
        .sheet(isPresented: $showingAddMeal) {
            AddPlannedMealView(
                recipes: recipes,
                dayOfWeek: selectedDay,
                mealType: selectedMealType,
                onAdd: { recipe, people in
                    addPlannedMeal(recipe: recipe, numberOfPeople: people, dayOfWeek: selectedDay, mealType: selectedMealType)
                }
            )
        }
    }
    
    private func addPlannedMeal(recipe: Recipe, numberOfPeople: Int, dayOfWeek: Int, mealType: PlannedMeal.MealType) {
        let newMeal = PlannedMeal(
            recipe: recipe,
            numberOfPeople: numberOfPeople,
            dayOfWeek: dayOfWeek,
            mealType: mealType
        )
        plannedMeals.append(newMeal)
    }
    
    private func removePlannedMeal(_ meal: PlannedMeal) {
        plannedMeals.removeAll { $0.id == meal.id }
    }
    
    private func generateShoppingList() {
        // Trouve ou crée une liste de courses
        var shoppingList: ShoppingList
        if let existingList = shoppingLists.first {
            shoppingList = existingList
            // Effacer les éléments existants
            if let items = shoppingList.items {
                items.forEach { modelContext.delete($0) }
            }
            shoppingList.items = []
        } else {
            shoppingList = ShoppingList()
            modelContext.insert(shoppingList)
        }
        
        // Un dictionnaire pour regrouper les articles
        var articleQuantities: [Article: Double] = [:]
        
        // Parcourir les repas planifiés
        for meal in plannedMeals {
            if let recipeIngredients = meal.recipe.ingredients {
                for recipeArticle in recipeIngredients {
                    if let article = recipeArticle.article {
                        // Calcule la quantité totale en fonction du nombre de personnes
                        let totalQuantity = recipeArticle.quantity * Double(meal.numberOfPeople)
                        
                        // Ajoute ou met à jour la quantité dans le dictionnaire
                        articleQuantities[article, default: 0] += totalQuantity
                    }
                }
            }
        }
        
        // Créer les éléments de la liste de courses
        for (article, quantity) in articleQuantities {
            let item = ShoppingListItem(
                shoppingList: shoppingList,
                article: article,
                quantity: quantity
            )
            modelContext.insert(item)
        }
        
        // Mettre à jour la date de modification
        shoppingList.modificationDate = Date()
    }
}

struct AddPlannedMealView: View {
    let recipes: [Recipe]
    let dayOfWeek: Int
    let mealType: PlannedMeal.MealType
    let onAdd: (Recipe, Int) -> Void
    
    @State private var selectedRecipe: Recipe?
    @State private var numberOfPeople = 2
    @Environment(\.dismiss) private var dismiss
    
    let daysOfWeek = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Jour et repas")) {
                    Text("\(daysOfWeek[dayOfWeek]) - \(mealType.rawValue)")
                }
                
                Section(header: Text("Recette")) {
                    Picker("Sélectionner une recette", selection: $selectedRecipe) {
                        Text("Choisir une recette").tag(nil as Recipe?)
                        ForEach(recipes) { recipe in
                            Text(recipe.name).tag(recipe as Recipe?)
                        }
                    }
                }
                
                Section(header: Text("Nombre de personnes")) {
                    Stepper("\(numberOfPeople) personne(s)", value: $numberOfPeople, in: 1...10)
                }
                
                Section {
                    Button("Ajouter au planning") {
                        if let recipe = selectedRecipe {
                            onAdd(recipe, numberOfPeople)
                            dismiss()
                        }
                    }
                    .disabled(selectedRecipe == nil)
                }
            }
            .navigationTitle("Ajouter un repas")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Utilisation de l'ancienne syntaxe de prévisualisation pour éviter des problèmes de compilation
struct WeeklyPlannerView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Recipe.self, Article.self, RecipeArticle.self,
            ShoppingList.self, ShoppingListItem.self,
            configurations: config
        )
        let context = container.mainContext
        SampleData.createSampleData(in: context)
        
        return NavigationStack {
            WeeklyPlannerView()
        }
        .modelContainer(container)
    }
}
