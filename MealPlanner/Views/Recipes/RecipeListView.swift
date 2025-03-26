import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: RecipeViewModel?
    @State private var showingAddRecipe = false
    @State private var selectedRecipe: Recipe?
    @State private var navigateToDetail = false
    
    var body: some View {
        List {
            if let vm = viewModel {
                ForEach(vm.recipes) { recipe in
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
                }
                .onDelete(perform: deleteRecipes)
            } else {
                ProgressView()
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
        for index in offsets {
            vm.deleteRecipe(vm.recipes[index])
        }
    }
}

