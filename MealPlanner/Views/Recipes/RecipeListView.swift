import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: RecipeViewModel?
    @State private var showingAddRecipe = false
    @State private var selectedRecipe: Recipe?
    @State private var navigateToDetail = false
    @State private var recipeToAddToPlanner: Recipe? = nil
    @State private var searchText = ""
    
    // Accéder au gestionnaire partagé du planning
    @ObservedObject private var plannerManager = PlannerManager.shared
    @Query private var shoppingLists: [ShoppingList]
    @Query private var allRecipes: [Recipe]
    
    var filteredRecipes: [Recipe] {
        guard let vm = viewModel else {
            return []
        }
        if searchText.isEmpty {
            return vm.recipes
        }
        return vm.recipes.filter { recipe in
            recipe.name.localizedCaseInsensitiveContains(searchText) ||
            (recipe.details?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        VStack {
            // Barre de recherche
            SearchBar(text: $searchText, placeholder: "Rechercher une recette")
                .padding(.horizontal)
            
            List {
                if let vm = viewModel {
                    ForEach(filteredRecipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(recipe.name)
                                        .font(.headline)
                                    if !recipe.hasIngredients {
                                        Text("Incomplet")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.orange.opacity(0.2))
                                            )
                                    }
                                }
                                if let details = recipe.details, !details.isEmpty {
                                    Text(details)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .contextMenu {
                            if recipe.hasIngredients {
                                Button {
                                    // Définir directement la recette à ajouter au planning
                                    recipeToAddToPlanner = recipe
                                } label: {
                                    Label("Ajouter au planning", systemImage: "calendar.badge.plus")
                                }
                            } else {
                                Text("Recette incomplète")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteRecipes)
                } else {
                    ProgressView()
                }
            }
        }
        .navigationTitle("Mes Recettes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddRecipe = true
                } label: {
                    Label("Ajouter", systemImage: "plus")
                }
                .disabled(viewModel == nil)
            }
        }
        .sheet(isPresented: $showingAddRecipe) {
            AddRecipeView(onRecipeCreated: { recipe in
                // Quand une recette est créée, on la sélectionne et active la navigation
                selectedRecipe = recipe
                navigateToDetail = true
                // Rafraîchir la liste
                viewModel?.fetchRecipes()
            })
        }
        // Utiliser la présence de recipeToAddToPlanner comme déclencheur pour afficher la sheet
        .sheet(item: $recipeToAddToPlanner) { recipe in
            PlannerAddView(recipe: recipe) { day, mealType, people in
                addToPlannerAndUpdateList(recipe: recipe, day: day, mealType: mealType, people: people)
            }
        }
        .onAppear {
            // Initialiser le ViewModel avec le modelContext de l'environment
            if viewModel == nil {
                viewModel = RecipeViewModel(modelContext: modelContext)
            } else {
                // Actualiser si déjà initialisé
                viewModel?.fetchRecipes()
            }
        }
        // Ajouter une navigation programmée vers la vue détaillée
        .navigationDestination(isPresented: $navigateToDetail) {
            if let recipe = selectedRecipe {
                RecipeDetailView(recipe: recipe)
            }
        }
    }
    
    private func deleteRecipes(at offsets: IndexSet) {
        guard let vm = viewModel else { return }
        
        // Convertir les indices de la liste filtrée en indices réels
        let recipesToDelete = offsets.map { filteredRecipes[$0] }
        
        for recipe in recipesToDelete {
            vm.deleteRecipe(recipe)
        }
    }
    
    private func addToPlannerAndUpdateList(recipe: Recipe, day: Int, mealType: PlannedMeal.MealType, people: Int) {
        // Créer un nouveau repas planifié
        let newMeal = PlannedMeal(
            recipe: recipe,
            numberOfPeople: people,
            dayOfWeek: day,
            mealType: mealType
        )
        
        // Ajouter au planificateur
        plannerManager.addMeal(newMeal)
        
        // Mettre à jour la liste de courses
        updateShoppingList()
        
        // Fermer la modale en réinitialisant la recette
        recipeToAddToPlanner = nil
    }
    
    private func updateShoppingList() {
        // Mettre à jour la liste de courses avec les repas planifiés
        ShoppingListUpdater.update(
            with: plannerManager.getAllMeals(),
            modelContext: modelContext,
            shoppingLists: shoppingLists,
            recipes: allRecipes
        )
    }
}

// Extension pour permettre d'utiliser Recipe avec .sheet(item:)
extension Recipe: Identifiable {}

// Vue simplifiée pour ajouter une recette au planning
struct PlannerAddView: View {
    let recipe: Recipe
    let onAdd: (Int, PlannedMeal.MealType, Int) -> Void
    @State private var selectedDay = 0
    @State private var selectedMealType = PlannedMeal.MealType.dinner
    @State private var numberOfPeople = 2
    @Environment(\.dismiss) private var dismiss
    
    let daysOfWeek = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Recette")) {
                    Text(recipe.name)
                        .font(.headline)
                }
                
                Section(header: Text("Jour")) {
                    Picker("Jour", selection: $selectedDay) {
                        ForEach(0..<daysOfWeek.count, id: \.self) { index in
                            Text(daysOfWeek[index]).tag(index)
                        }
                    }
                }
                
                Section(header: Text("Type de repas")) {
                    Picker("Type de repas", selection: $selectedMealType) {
                        ForEach(PlannedMeal.MealType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Nombre de personnes")) {
                    Stepper("\(numberOfPeople) personne(s)", value: $numberOfPeople, in: 1...10)
                }
                
                Section {
                    Button("Ajouter au planning") {
                        onAdd(selectedDay, selectedMealType, numberOfPeople)
                    }
                }
            }
            .navigationTitle("Ajouter au planning")
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
