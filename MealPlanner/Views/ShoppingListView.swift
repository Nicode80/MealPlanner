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
            let category = item.ingredient?.category ?? "Autre"
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
    @Bindable var item: ShoppingListItem  // Remplacé @ObservedObject par @Bindable
    
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
                Text(item.ingredient?.name ?? "Ingrédient inconnu")
                    .strikethrough(item.isChecked)
                    .foregroundColor(item.isChecked ? .secondary : .primary)
            }
            
            Spacer()
            
            Text("\(String(format: "%.1f", item.quantity)) \(item.ingredient?.unit ?? "")")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Recipe.self, Ingredient.self, RecipeIngredient.self,
        ShoppingList.self, ShoppingListItem.self,
        configurations: config
    )
    
    let context = container.mainContext
    SampleData.createSampleData(in: context)
    
    return NavigationStack {
        ShoppingListView()
    }
    .modelContainer(container)
}
