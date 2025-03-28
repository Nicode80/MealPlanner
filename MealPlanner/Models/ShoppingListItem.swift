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
    var article: Article?
    
    init(shoppingList: ShoppingList? = nil, article: Article? = nil, quantity: Double, isChecked: Bool = false) {
        self.shoppingList = shoppingList
        self.article = article
        self.quantity = quantity
        self.isChecked = isChecked
    }
}
