import Foundation
import SwiftData

@Model
final class TestModel {
    var name: String
    
    // Test avec deleteRule
    @Relationship(deleteRule: .cascade)
    var items: [TestItemModel]?
    
    init(name: String) {
        self.name = name
    }
}

@Model
final class TestItemModel {
    var details: String
    
    @Relationship(deleteRule: .cascade)
    var parent: TestModel?
    
    init(details: String) {
        self.details = details
    }
}
