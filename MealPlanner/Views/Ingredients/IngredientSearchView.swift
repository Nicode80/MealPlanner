import SwiftUI
import SwiftData

struct IngredientSearchView: View {
    @ObservedObject var viewModel: IngredientsViewModel
    @State private var searchText = ""
    @State private var showingAddForm = false
    @State private var newIngredientName = ""
    @State private var newIngredientCategory = ""
    @State private var newIngredientUnit = ""
    
    var onIngredientSelected: (Ingredient) -> Void
    
    var body: some View {
        VStack {
            // Barre de recherche
            TextField("Rechercher un ingrédient", text: $searchText)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .onChange(of: searchText) { _, newValue in
                    viewModel.searchIngredient(query: newValue)
                }
            
            // Résultats de recherche
            List {
                // Section pour les résultats exacts
                if !viewModel.searchResults.isEmpty {
                    Section(header: Text("Ingrédients")) {
                        ForEach(viewModel.searchResults) { ingredient in
                            IngredientRow(ingredient: ingredient)
                                .onTapGesture {
                                    onIngredientSelected(ingredient)
                                }
                        }
                    }
                }
                
                // Section pour les suggestions similaires
                if !viewModel.similarIngredientSuggestions.isEmpty {
                    Section(header: Text("Vouliez-vous dire...")) {
                        ForEach(viewModel.similarIngredientSuggestions) { ingredient in
                            IngredientRow(ingredient: ingredient)
                                .onTapGesture {
                                    onIngredientSelected(ingredient)
                                }
                        }
                    }
                }
                
                // Option pour ajouter un nouvel ingrédient si aucun résultat satisfaisant
                if !searchText.isEmpty && (viewModel.searchResults.isEmpty || !viewModel.searchResults.contains(where: { $0.name.lowercased() == searchText.lowercased() })) {
                    Button(action: {
                        newIngredientName = searchText
                        showingAddForm = true
                    }) {
                        Label("Ajouter \"\(searchText)\"", systemImage: "plus")
                    }
                }
            }
        }
        .navigationTitle("Ingrédients")
        .sheet(isPresented: $showingAddForm) {
            AddIngredientView(
                name: $newIngredientName,
                category: $newIngredientCategory,
                unit: $newIngredientUnit,
                onAdd: { name, category, unit in
                    if let newIngredient = viewModel.addIngredient(name: name, category: category, unit: unit) {
                        onIngredientSelected(newIngredient)
                    }
                    showingAddForm = false
                },
                onCancel: {
                    showingAddForm = false
                }
            )
        }
    }
}

#Preview {
    // Création d'un environnement de prévisualisation avec un ModelContainer en mémoire
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Ingredient.self, configurations: config)
    
    // Ajout de quelques ingrédients pour la prévisualisation
    let context = container.mainContext
    
    let carotte = Ingredient(name: "Carotte", category: "Fruits et légumes", unit: "pièce(s)")
    let tomate = Ingredient(name: "Tomate", category: "Fruits et légumes", unit: "pièce(s)")
    let farine = Ingredient(name: "Farine", category: "Épicerie", unit: "g")
    
    context.insert(carotte)
    context.insert(tomate)
    context.insert(farine)
    
    // Création d'un viewModel pour la prévisualisation
    let viewModel = IngredientsViewModel(modelContext: context)
    
    // Retourne la vue avec le ViewModel et une fonction vide pour onIngredientSelected
    return NavigationView {
        IngredientSearchView(
            viewModel: viewModel,
            onIngredientSelected: { _ in }
        )
    }
    .modelContainer(container)
}
