import Foundation
import SwiftData

@Model
final class ShoppingListItem {
    var quantity: Double
    var isChecked: Bool
    
    // Relations - ne supprime pas les entités liées
    @Relationship(deleteRule: .nullify)
    var shoppingList: ShoppingList?
    
    @Relationship(deleteRule: .nullify)
    var ingredient: Ingredient?
    
    init(shoppingList: ShoppingList? = nil, ingredient: Ingredient? = nil, quantity: Double, isChecked: Bool = false) {
        self.shoppingList = shoppingList
        self.ingredient = ingredient
        self.quantity = quantity
        self.isChecked = isChecked
    }
}
