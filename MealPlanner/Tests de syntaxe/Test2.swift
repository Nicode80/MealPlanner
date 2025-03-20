import Foundation
import SwiftData

@Model
final class TestModelAlt {
    var name: String
    
    // Test sans options spécifiques
    @Relationship
    var items: [TestItemModelAlt]?
    
    init(name: String) {
        self.name = name
    }
}

@Model
final class TestItemModelAlt {
    var details: String
    
    @Relationship
    var parent: TestModelAlt?
    
    init(details: String) {
        self.details = details
    }
}
