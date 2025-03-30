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
            if currentList != nil {
                List {
                    ForEach(sortedCategories, id: \.self) { category in
                        Section(header: Text(category)) {
                            ForEach(groupedItems[category] ?? []) { item in
                                ShoppingListItemRow(item: item)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            removeItem(item)
                                        } label: {
                                            Label("Supprimer", systemImage: "trash")
                                        }
                                    }
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
                // Passage direct à ArticleSelectionView
                ArticleSelectionView(
                    forRecipe: false,
                    onArticleSelected: { article, quantity, _ in
                        addItemToShoppingList(article: article, quantity: quantity, list: list)
                        showingAddItem = false
                    }
                )
            }
        }
        .onAppear {
            if shoppingLists.isEmpty {
                createNewShoppingList()
            }
        }
    }
    
    // Créer une nouvelle liste de courses
    private func createNewShoppingList() {
        let newList = ShoppingList()
        modelContext.insert(newList)
    }
    
    // Ajouter un article à la liste de courses
    private func addItemToShoppingList(article: Article, quantity: Double, list: ShoppingList) {
        // Vérifier si l'article existe déjà dans la liste
        if let existingItems = list.items,
           let existingItem = existingItems.first(where: { $0.article?.id == article.id }) {
            // Si oui, augmenter la quantité
            existingItem.quantity += quantity
            // S'assurer qu'il est marqué comme manuel
            existingItem.isManuallyAdded = true
        } else {
            // Sinon, créer un nouvel élément
            let newItem = ShoppingListItem(
                shoppingList: list,
                article: article,
                quantity: quantity,
                isManuallyAdded: true // Marquer comme manuel
            )
            modelContext.insert(newItem)
            if list.items == nil {
                list.items = [newItem]
            } else {
                list.items?.append(newItem)
            }
        }
        // Mettre à jour la date de modification
        list.modificationDate = Date()
    }
    
    // Supprimer un article de la liste
    private func removeItem(_ item: ShoppingListItem) {
        guard let list = currentList else { return }
        // Retirer l'élément de la liste
        list.items?.removeAll(where: { $0.id == item.id })
        // Supprimer l'élément du contexte
        modelContext.delete(item)
        // Mettre à jour la date de modification
        list.modificationDate = Date()
    }
}
