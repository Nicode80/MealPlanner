import Foundation
import SwiftData

class ShoppingListViewModel: ObservableObject {
    private var modelContext: ModelContext
    
    @Published var shoppingLists: [ShoppingList] = []
    @Published var currentShoppingList: ShoppingList?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchShoppingLists()
        
        // Si aucune liste n'existe, en créer une par défaut
        if shoppingLists.isEmpty {
            createNewShoppingList()
        } else {
            currentShoppingList = shoppingLists.first
        }
    }
    
    func fetchShoppingLists() {
        let descriptor = FetchDescriptor<ShoppingList>(sortBy: [SortDescriptor(\.modificationDate, order: .reverse)])
        do {
            shoppingLists = try modelContext.fetch(descriptor)
        } catch {
            print("Erreur lors de la récupération des listes de courses: \(error)")
        }
    }
    
    func createNewShoppingList() {
        let newList = ShoppingList()
        modelContext.insert(newList)
        saveContext()
        currentShoppingList = newList
        fetchShoppingLists()
    }
    
    func addItemToShoppingList(shoppingList: ShoppingList, ingredient: Ingredient, quantity: Double) {
        // Vérifier si l'ingrédient existe déjà dans la liste
        if let existingItem = shoppingList.items?.first(where: { $0.ingredient?.name == ingredient.name }) {
            // Si oui, augmenter la quantité
            existingItem.quantity += quantity
        } else {
            // Sinon, créer un nouvel élément
            let newItem = ShoppingListItem(shoppingList: shoppingList, ingredient: ingredient, quantity: quantity)
            
            if shoppingList.items == nil {
                shoppingList.items = [newItem]
            } else {
                shoppingList.items?.append(newItem)
            }
        }
        
        // Mettre à jour la date de modification
        shoppingList.modificationDate = Date()
        saveContext()
    }
    
    func toggleItemCheck(item: ShoppingListItem) {
        item.isChecked.toggle()
        saveContext()
    }
    
    func removeItemFromShoppingList(item: ShoppingListItem) {
        if let shoppingList = item.shoppingList {
            shoppingList.items?.removeAll(where: { $0.id == item.id })
            modelContext.delete(item)
            saveContext()
        }
    }
    
    func deleteShoppingList(_ shoppingList: ShoppingList) {
        modelContext.delete(shoppingList)
        saveContext()
        fetchShoppingLists()
        
        // Si on a supprimé la liste courante, prendre la première de la liste ou en créer une nouvelle
        if currentShoppingList?.id == shoppingList.id {
            if !shoppingLists.isEmpty {
                currentShoppingList = shoppingLists.first
            } else {
                createNewShoppingList()
            }
        }
    }
    
    func addRecipeToShoppingList(recipe: Recipe, numberOfPeople: Int, shoppingList: ShoppingList? = nil) {
        let targetList = shoppingList ?? currentShoppingList
        
        guard let targetList = targetList, let ingredients = recipe.ingredients else { return }
        
        for recipeIngredient in ingredients {
            if let ingredient = recipeIngredient.ingredient {
                // Calculer la quantité en fonction du nombre de personnes
                let totalQuantity = recipeIngredient.quantity * Double(numberOfPeople)
                
                // Ajouter à la liste de courses
                addItemToShoppingList(shoppingList: targetList, ingredient: ingredient, quantity: totalQuantity)
            }
        }
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de la sauvegarde du contexte: \(error)")
        }
    }
}
