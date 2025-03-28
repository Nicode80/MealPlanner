import SwiftUI
import SwiftData

struct AddShoppingItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let shoppingList: ShoppingList
    
    @State private var selectedArticle: Article?
    @State private var quantity: Double = 1.0
    @State private var showingArticleSelection = false
    
    @Query private var articles: [Article]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Article")) {
                    if let article = selectedArticle {
                        HStack {
                            Text(article.name)
                            Spacer()
                            Button("Changer") {
                                showingArticleSelection = true
                            }
                        }
                    } else {
                        Button("Sélectionner un article") {
                            showingArticleSelection = true
                        }
                    }
                }
                
                if let article = selectedArticle {
                    Section(header: Text("Quantité")) {
                        // Sélecteur de quantité avec boutons + et -
                        HStack {
                            Button(action: {
                                let step = getStepValue(for: article.unit)
                                quantity = max(step, quantity - step)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            if isDecimalUnit(article.unit) {
                                // Pour kg/l, afficher avec une décimale
                                TextField("Quantité", value: $quantity, format: .number.precision(.fractionLength(1)))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 80)
                            } else {
                                // Pour les autres unités, afficher en nombres entiers
                                TextField("Quantité", value: $quantity, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 80)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                let step = getStepValue(for: article.unit)
                                quantity += step
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Unité de mesure
                        Text(article.unit)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                Section {
                    Button("Ajouter à la liste") {
                        addItemToShoppingList()
                    }
                    .disabled(selectedArticle == nil)
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
            .sheet(isPresented: $showingArticleSelection) {
                ArticleSelectionView(
                    forRecipe: false,  // Important: indique qu'on n'est pas dans le contexte d'une recette
                    onArticleSelected: { article, selectedQuantity, _ in
                        selectedArticle = article
                        quantity = selectedQuantity
                        showingArticleSelection = false
                    }
                )
            }
        }
    }
    
    private func addItemToShoppingList() {
        guard let article = selectedArticle else { return }
        
        // Vérifier si l'article existe déjà dans la liste
        if let existingItems = shoppingList.items,
           let existingItem = existingItems.first(where: { $0.article?.id == article.id }) {
            // Si oui, augmenter la quantité
            existingItem.quantity += quantity
        } else {
            // Sinon, créer un nouvel élément
            let newItem = ShoppingListItem(
                shoppingList: shoppingList,
                article: article,
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
    
    // Détermine si une unité utilise des valeurs décimales
    private func isDecimalUnit(_ unit: String) -> Bool {
        return ["kg", "l"].contains(unit)
    }
    
    // Obtient le pas d'incrémentation pour une unité donnée
    private func getStepValue(for unit: String) -> Double {
        return isDecimalUnit(unit) ? 0.1 : 1.0
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Recipe.self, Article.self, RecipeIngredient.self,
        ShoppingList.self, ShoppingListItem.self,
        configurations: config
    )
    
    let context = container.mainContext
    
    // Créer un exemple de liste de courses
    let shoppingList = ShoppingList()
    context.insert(shoppingList)
    
    // Créer quelques articles
    let carotte = Article(name: "Carotte", category: "Fruits et légumes", unit: "pièce(s)", isFood: true)
    let tomate = Article(name: "Tomate", category: "Fruits et légumes", unit: "pièce(s)", isFood: true)
    
    context.insert(carotte)
    context.insert(tomate)
    
    return AddShoppingItemView(shoppingList: shoppingList)
        .modelContainer(container)
}
