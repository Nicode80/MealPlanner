import SwiftUI
import SwiftData

// Structure pour représenter un repas planifié
struct PlannedMeal: Identifiable, Equatable {
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
    
    // Implémentation de Equatable pour permettre la comparaison
    static func == (lhs: PlannedMeal, rhs: PlannedMeal) -> Bool {
        lhs.id == rhs.id &&
        lhs.recipe.id == rhs.recipe.id &&
        lhs.numberOfPeople == rhs.numberOfPeople &&
        lhs.dayOfWeek == rhs.dayOfWeek &&
        lhs.mealType == rhs.mealType
    }
}

// Vue principale du planificateur hebdomadaire
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
            ForEach(0..<daysOfWeek.count, id: \.self) { dayIndex in
                DaySection(
                    dayName: daysOfWeek[dayIndex],
                    dayIndex: dayIndex,
                    plannedMeals: plannedMeals,
                    onAddMeal: { dayIdx, mealType in
                        selectedDay = dayIdx
                        selectedMealType = mealType
                        showingAddMeal = true
                    },
                    onDeleteMeal: { meal in
                        removePlannedMeal(meal)
                    }
                )
            }
        }
        .navigationTitle("Planning de la semaine")
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
        .onChange(of: plannedMeals) { _, _ in
            updateShoppingList()
        }
        .onAppear {
            updateShoppingList()
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
    
    private func updateShoppingList() {
        // La logique complète de mise à jour de la liste de courses est déléguée à un service
        ShoppingListUpdater.update(
            with: plannedMeals,
            modelContext: modelContext,
            shoppingLists: shoppingLists
        )
    }
}

// Composant de section pour un jour
struct DaySection: View {
    let dayName: String
    let dayIndex: Int
    let plannedMeals: [PlannedMeal]
    let onAddMeal: (Int, PlannedMeal.MealType) -> Void
    let onDeleteMeal: (PlannedMeal) -> Void
    
    var body: some View {
        Section(header: Text(dayName)) {
            ForEach(PlannedMeal.MealType.allCases) { mealType in
                MealTypeRow(
                    mealType: mealType,
                    dayIndex: dayIndex,
                    plannedMeals: plannedMeals,
                    onAddMeal: onAddMeal,
                    onDeleteMeal: onDeleteMeal
                )
            }
        }
    }
}

// Composant pour un type de repas (petit-déjeuner, déjeuner, dîner)
struct MealTypeRow: View {
    let mealType: PlannedMeal.MealType
    let dayIndex: Int
    let plannedMeals: [PlannedMeal]
    let onAddMeal: (Int, PlannedMeal.MealType) -> Void
    let onDeleteMeal: (PlannedMeal) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(mealType.rawValue)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Filtre les repas pour ce jour et ce type de repas
            let filteredMeals = plannedMeals.filter {
                $0.dayOfWeek == dayIndex && $0.mealType == mealType
            }
            
            if filteredMeals.isEmpty {
                Button {
                    onAddMeal(dayIndex, mealType)
                } label: {
                    Text("+ Ajouter un repas")
                        .foregroundColor(.blue)
                }
            } else {
                ForEach(filteredMeals) { meal in
                    MealRow(
                        meal: meal,
                        onDelete: onDeleteMeal
                    )
                }
            }
        }
    }
}

// Composant pour une ligne de repas
struct MealRow: View {
    let meal: PlannedMeal
    let onDelete: (PlannedMeal) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(meal.recipe.name)
                    .font(.headline)
                Text("Pour \(meal.numberOfPeople) personne(s)")
                    .font(.caption)
            }
            
            Spacer()
            
            Button {
                onDelete(meal)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

// Service pour la mise à jour de la liste de courses
struct ShoppingListUpdater {
    static func update(with plannedMeals: [PlannedMeal], modelContext: ModelContext, shoppingLists: [ShoppingList]) {
        // Créer ou récupérer la liste de courses
        let shoppingList = getOrCreateShoppingList(from: shoppingLists, modelContext: modelContext)
        
        // Mettre à jour les articles
        updateShoppingItems(
            shoppingList: shoppingList,
            plannedMeals: plannedMeals,
            modelContext: modelContext
        )
    }
    
    private static func getOrCreateShoppingList(from shoppingLists: [ShoppingList], modelContext: ModelContext) -> ShoppingList {
        if let existingList = shoppingLists.first {
            return existingList
        } else {
            let newList = ShoppingList()
            modelContext.insert(newList)
            return newList
        }
    }
    
    private static func updateShoppingItems(shoppingList: ShoppingList, plannedMeals: [PlannedMeal], modelContext: ModelContext) {
        // 1. Créer un dictionnaire des articles existants
        var existingItemsByArticle = [Article: ShoppingListItem]()
        if let items = shoppingList.items {
            for item in items {
                if let article = item.article {
                    existingItemsByArticle[article] = item
                }
            }
        }
        
        // 2. Calculer les quantités des recettes
        var recipeQuantities = [Article: Double]()
        for meal in plannedMeals {
            if let ingredients = meal.recipe.ingredients {
                for ingredient in ingredients {
                    if let article = ingredient.article {
                        let quantity = ingredient.quantity * Double(meal.numberOfPeople)
                        recipeQuantities[article, default: 0] += quantity
                    }
                }
            }
        }
        
        // 3. Traiter tous les articles existants
        var processedArticles = Set<Article>()
        
        // 3a. D'abord, mettre à jour les articles qui sont dans les recettes
        for (article, recipeQuantity) in recipeQuantities {
            if let existingItem = existingItemsByArticle[article] {
                // Calculer la nouvelle quantité totale: recette + ajustement manuel
                let newTotalQuantity = recipeQuantity + existingItem.manualQuantity
                
                // Mettre à jour la quantité totale
                existingItem.quantity = max(0, newTotalQuantity) // Éviter les quantités négatives
                
                // Marquer comme traité
                processedArticles.insert(article)
            } else {
                // L'article n'existe pas encore, donc créer un nouvel élément
                let newItem = ShoppingListItem(
                    shoppingList: shoppingList,
                    article: article,
                    quantity: recipeQuantity,
                    isManuallyAdded: false,
                    manualQuantity: 0.0
                )
                modelContext.insert(newItem)
                if shoppingList.items == nil {
                    shoppingList.items = [newItem]
                } else {
                    shoppingList.items?.append(newItem)
                }
                
                // Marquer comme traité
                processedArticles.insert(article)
            }
        }
        
        // 3b. Ensuite, conserver les articles ajoutés manuellement qui ne sont plus dans les recettes
        if let items = shoppingList.items {
            for item in items {
                if let article = item.article, !processedArticles.contains(article) {
                    if item.isManuallyAdded && item.manualQuantity > 0 {
                        // Garder les articles manuels avec une quantité positive
                        // La quantité totale devient simplement la quantité manuelle
                        item.quantity = item.manualQuantity
                    } else if !item.isManuallyAdded {
                        // Supprimer les articles non manuels qui ne sont plus nécessaires
                        modelContext.delete(item)
                        shoppingList.items?.removeAll(where: { $0.id == item.id })
                    }
                }
            }
        }
        
        // 4. Mettre à jour la date de modification
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

// Prévisualisation
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
