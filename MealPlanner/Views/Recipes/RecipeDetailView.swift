import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recipe: Recipe
    
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
                        ForEach(ingredients) { recipeArticle in
                            if let article = recipeArticle.article {
                                HStack {
                                    Text("\(article.name)")
                                    Spacer()
                                    Text("\(String(format: "%.1f", recipeArticle.quantity)) \(article.unit)")
                                        .foregroundColor(.secondary)
                                    if recipeArticle.isOptional {
                                        Text("(optionnel)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .italic()
                                    }
                                    Button {
                                        removeIngredient(recipeArticle)
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
            // Utilisation de ArticleSelectionView avec le nom de la recette
            ArticleSelectionView(
                forRecipe: true,
                recipeName: recipe.name,
                onArticleSelected: { article, quantity, isOptional in
                    // Utiliser le modelContext pour ajouter l'ingrédient à la recette
                    let recipeArticle = RecipeArticle(
                        recipe: recipe,
                        article: article,
                        quantity: quantity,
                        isOptional: isOptional
                    )
                    modelContext.insert(recipeArticle)
                    if recipe.ingredients == nil {
                        recipe.ingredients = [recipeArticle]
                    } else {
                        recipe.ingredients?.append(recipeArticle)
                    }
                }
            )
        }
        .sheet(isPresented: $showingEditRecipe) {
            EditRecipeView(recipe: recipe)
        }
    }
    
    private func removeIngredient(_ recipeArticle: RecipeArticle) {
        if let index = recipe.ingredients?.firstIndex(where: { $0.id == recipeArticle.id }) {
            recipe.ingredients?.remove(at: index)
            modelContext.delete(recipeArticle)
        }
    }
}

struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Recipe.self, Article.self, RecipeArticle.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Créer un exemple de recette
        let recipe = Recipe(name: "Pâtes à la carbonara", details: "Un classique italien facile et délicieux.")
        let spaghetti = Article(name: "Spaghetti", category: "Épicerie salée", unit: "g", isFood: true)
        let bacon = Article(name: "Lardons", category: "Viandes", unit: "g", isFood: true)
        let egg = Article(name: "Œuf", category: "Produits laitiers", unit: "pièce(s)", isFood: true)
        let cheese = Article(name: "Parmesan", category: "Produits laitiers", unit: "g", isFood: true)
        
        context.insert(recipe)
        context.insert(spaghetti)
        context.insert(bacon)
        context.insert(egg)
        context.insert(cheese)
        
        let ingredient1 = RecipeArticle(recipe: recipe, article: spaghetti, quantity: 100, isOptional: false)
        let ingredient2 = RecipeArticle(recipe: recipe, article: bacon, quantity: 50, isOptional: false)
        let ingredient3 = RecipeArticle(recipe: recipe, article: egg, quantity: 1, isOptional: false)
        let ingredient4 = RecipeArticle(recipe: recipe, article: cheese, quantity: 20, isOptional: false)
        
        context.insert(ingredient1)
        context.insert(ingredient2)
        context.insert(ingredient3)
        context.insert(ingredient4)
        
        return NavigationStack {
            RecipeDetailView(recipe: recipe)
        }
        .modelContainer(container)
    }
}
