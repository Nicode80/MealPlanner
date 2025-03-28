import Foundation
import SwiftData

@Model
final class ShoppingListItem {
    var quantity: Double
    var isChecked: Bool
    var isManuallyAdded: Bool
    var manualQuantity: Double // Nouvel attribut pour stocker les ajustements manuels
    
    // Relations - ne supprime pas les entités liées
    @Relationship(deleteRule: .nullify)
    var shoppingList: ShoppingList?
    
    @Relationship(deleteRule: .nullify)
    var article: Article?
    
    init(shoppingList: ShoppingList? = nil, article: Article? = nil, quantity: Double, isChecked: Bool = false, isManuallyAdded: Bool = false, manualQuantity: Double = 0.0) {
        self.shoppingList = shoppingList
        self.article = article
        self.quantity = quantity
        self.isChecked = isChecked
        self.isManuallyAdded = isManuallyAdded
        self.manualQuantity = manualQuantity
    }
}
