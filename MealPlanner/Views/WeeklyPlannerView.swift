import SwiftUI
import SwiftData
import Combine

// Vue principale du planificateur hebdomadaire
struct WeeklyPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var recipes: [Recipe]
    @Query private var shoppingLists: [ShoppingList]
    
    // Utiliser ObservedObject pour observer les changements de PlannerManager
    @ObservedObject private var plannerManager = PlannerManager.shared
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
                    plannedMeals: plannerManager.mealsForDay(dayIndex),
                    recipes: recipes,
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
        plannerManager.addMeal(newMeal)
        updateShoppingList()
    }
    
    private func removePlannedMeal(_ meal: PlannedMeal) {
        plannerManager.removeMeal(meal)
        updateShoppingList()
    }
    
    private func updateShoppingList() {
        // Mettre à jour la liste de courses avec les repas planifiés
        ShoppingListUpdater.update(
            with: plannerManager.getAllMeals(),
            modelContext: modelContext,
            shoppingLists: shoppingLists,
            recipes: recipes
        )
    }
}

// Composant de section pour un jour
struct DaySection: View {
    let dayName: String
    let dayIndex: Int
    let plannedMeals: [PlannedMeal]
    let recipes: [Recipe]
    let onAddMeal: (Int, PlannedMeal.MealType) -> Void
    let onDeleteMeal: (PlannedMeal) -> Void
    
    var body: some View {
        Section(header: Text(dayName)) {
            ForEach(PlannedMeal.MealType.allCases) { mealType in
                MealTypeRow(
                    mealType: mealType,
                    dayIndex: dayIndex,
                    plannedMeals: plannedMeals.filter { $0.mealType == mealType },
                    recipes: recipes,
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
    let recipes: [Recipe]
    let onAddMeal: (Int, PlannedMeal.MealType) -> Void
    let onDeleteMeal: (PlannedMeal) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(mealType.rawValue)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if plannedMeals.isEmpty {
                Button {
                    onAddMeal(dayIndex, mealType)
                } label: {
                    Text("+ Ajouter un repas")
                        .foregroundColor(.blue)
                }
            } else {
                ForEach(plannedMeals) { meal in
                    if let recipe = recipes.first(where: { $0.persistentModelID == meal.recipeId }) {
                        MealRow(
                            meal: meal,
                            recipeName: recipe.name,
                            onDelete: onDeleteMeal
                        )
                    } else {
                        Text("Recette non trouvée")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
        }
    }
}

// Composant pour une ligne de repas
struct MealRow: View {
    let meal: PlannedMeal
    let recipeName: String
    let onDelete: (PlannedMeal) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(recipeName)
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

struct AddPlannedMealView: View {
    let recipes: [Recipe]
    let dayOfWeek: Int
    let mealType: PlannedMeal.MealType
    let onAdd: (Recipe, Int) -> Void
    
    @State private var selectedRecipe: Recipe?
    @State private var numberOfPeople = 2
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    let daysOfWeek = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
    
    // Filtrer les recettes pour n'afficher que celles avec des ingrédients
    private var recipesWithIngredients: [Recipe] {
        return recipes.filter { $0.hasIngredients }
    }
    
    // Filtrer les recettes en fonction du texte de recherche
    private var filteredRecipes: [Recipe] {
        guard !searchText.isEmpty else {
            return recipesWithIngredients
        }
        
        return recipesWithIngredients.filter { recipe in
            recipe.name.localizedCaseInsensitiveContains(searchText) ||
            (recipe.details?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Jour et repas")) {
                    Text("\(daysOfWeek[dayOfWeek]) - \(mealType.rawValue)")
                }
                
                Section(header: Text("Recette")) {
                    if recipesWithIngredients.isEmpty {
                        Text("Aucune recette complète disponible")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        // Barre de recherche
                        SearchBar(text: $searchText, placeholder: "Rechercher une recette")
                            .padding(.vertical, 4)
                        
                        if filteredRecipes.isEmpty {
                            Text("Aucune recette ne correspond à votre recherche")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            // Liste scrollable avec hauteur fixe
                            ScrollView(.vertical, showsIndicators: true) {
                                LazyVStack(alignment: .leading, spacing: 8) {
                                    ForEach(filteredRecipes) { recipe in
                                        RecipeSelectionRow(
                                            recipe: recipe,
                                            isSelected: selectedRecipe?.id == recipe.id,
                                            onSelect: {
                                                selectedRecipe = recipe
                                            }
                                        )
                                    }
                                }
                            }
                            .frame(height: 150) // Hauteur fixe pour éviter de prendre trop de place
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
                    .frame(maxWidth: .infinity, alignment: .center)
                    .buttonStyle(.borderedProminent)
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

// Composant pour représenter une ligne de recette sélectionnable
struct RecipeSelectionRow: View {
    let recipe: Recipe
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(recipe.name)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

