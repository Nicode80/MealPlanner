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
                        .aspectRatio(contentMode: .fill) // Remplir tout l'espace disponible
                        .frame(maxWidth: .infinity, maxHeight: 200) // Largeur infinie, hauteur fixe
                        .clipped() // Rogner ce qui dépasse
                        .cornerRadius(10) // Conserver les coins arrondis
                } else {
                    // Placeholder quand il n'y a pas d'image
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color(.systemGray6))
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .cornerRadius(10)
                        
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.secondary)
                    }
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
