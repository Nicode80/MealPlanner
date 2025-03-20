import Foundation
import SwiftData

@Model
final class ShoppingList {
    var creationDate: Date
    var modificationDate: Date
    
    // Relations - supprime les ShoppingListItem quand une liste est supprimée
    @Relationship(deleteRule: .cascade, inverse: \ShoppingListItem.shoppingList)
    var items: [ShoppingListItem]?
    
    init(creationDate: Date = Date(), modificationDate: Date = Date()) {
        self.creationDate = creationDate
        self.modificationDate = modificationDate
    }
}
