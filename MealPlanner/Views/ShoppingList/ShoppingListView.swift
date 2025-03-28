import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var shoppingLists: [ShoppingList]
    @State private var showingAddItem = false
    
    // Si plusieurs listes existent, on prend la plus récente
    private var currentList: ShoppingList? {
        shoppingLists.sorted(by: { $0.modificationDate > $1.modificationDate }).first
    }
    
    // Regrouper les items par catégorie
    private var groupedItems: [String: [ShoppingListItem]] {
        guard let list = currentList, let items = list.items else {
            return [:]
        }
        
        // Simplification de l'expression pour éviter l'erreur de type-checking
        var result = [String: [ShoppingListItem]]()
        for item in items {
            let category = item.article?.category ?? "Autre"
            if result[category] == nil {
                result[category] = []
            }
            result[category]?.append(item)
        }
        return result
    }
    
    // Trier les catégories
    private var sortedCategories: [String] {
        groupedItems.keys.sorted()
    }
    
    var body: some View {
        Group {
            if let _ = currentList {
                List {
                    ForEach(sortedCategories, id: \.self) { category in
                        Section(header: Text(category)) {
                            ForEach(groupedItems[category] ?? []) { item in
                                ShoppingListItemRow(item: item)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("Pas de liste de courses", systemImage: "cart")
                } description: {
                    Text("Ajoutez des recettes à votre planning pour créer une liste de courses.")
                } actions: {
                    Button("Créer une liste vide") {
                        createNewShoppingList()
                    }
                }
            }
        }
        .navigationTitle("Liste de courses")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddItem = true
                } label: {
                    Label("Ajouter", systemImage: "plus")
                }
                .disabled(currentList == nil)
            }
        }
        .sheet(isPresented: $showingAddItem) {
            if let list = currentList {
                AddShoppingItemView(shoppingList: list)
            }
        }
        .onAppear {
            if shoppingLists.isEmpty {
                createNewShoppingList()
            }
        }
    }
    
    private func createNewShoppingList() {
        let newList = ShoppingList()
        modelContext.insert(newList)
    }
}

struct ShoppingListItemRow: View {
    @Bindable var item: ShoppingListItem
    
    var body: some View {
        HStack {
            Button {
                item.isChecked.toggle()
            } label: {
                Image(systemName: item.isChecked ? "checkmark.square" : "square")
                    .foregroundColor(item.isChecked ? .green : .primary)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            VStack(alignment: .leading) {
                Text(item.article?.name ?? "Article inconnu")
                    .strikethrough(item.isChecked)
                    .foregroundColor(item.isChecked ? .secondary : .primary)
            }
            
            Spacer()
            
            Text("\(String(format: "%.1f", item.quantity)) \(item.article?.unit ?? "")")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Recipe.self, Article.self, RecipeArticle.self,
        ShoppingList.self, ShoppingListItem.self,
        configurations: config
    )
    
    let context = container.mainContext
    
    // Créer des exemples de données
    let shoppingList = ShoppingList()
    context.insert(shoppingList)
    
    let carotte = Article(name: "Carotte", category: "Fruits et légumes", unit: "pièce(s)", isFood: true)
    let tomate = Article(name: "Tomate", category: "Fruits et légumes", unit: "pièce(s)", isFood: true)
    let lessive = Article(name: "Lessive", category: "Produits d'entretien", unit: "bouteille(s)", isFood: false)
    
    context.insert(carotte)
    context.insert(tomate)
    context.insert(lessive)
    
    let item1 = ShoppingListItem(shoppingList: shoppingList, article: carotte, quantity: 3)
    let item2 = ShoppingListItem(shoppingList: shoppingList, article: tomate, quantity: 4)
    let item3 = ShoppingListItem(shoppingList: shoppingList, article: lessive, quantity: 1)
    
    context.insert(item1)
    context.insert(item2)
    context.insert(item3)
    
    return NavigationStack {
        ShoppingListView()
    }
    .modelContainer(container)
}
