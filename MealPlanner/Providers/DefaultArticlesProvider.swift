import Foundation
import SwiftData

/// Classe responsable de la création des articles (ingrédients) par défaut
class DefaultArticlesProvider {
    
    /// Crée tous les articles (ingrédients) nécessaires pour les recettes par défaut
    /// - Parameter modelContext: Contexte SwiftData pour insérer les articles
    /// - Returns: Dictionnaire contenant tous les articles créés, indexés par leur clé
    static func createAllArticles(in modelContext: ModelContext) -> [String: Article] {
        var articles = [String: Article]()
        
        // Épicerie salée
        articles.merge(createGroceryItems(in: modelContext), uniquingKeysWith: { (_, new) in new })
        
        // Viandes
        articles.merge(createMeatItems(in: modelContext), uniquingKeysWith: { (_, new) in new })
        
        // Produits laitiers
        articles.merge(createDairyItems(in: modelContext), uniquingKeysWith: { (_, new) in new })
        
        // Fruits et légumes
        articles.merge(createProduceItems(in: modelContext), uniquingKeysWith: { (_, new) in new })
        
        // Épices et condiments
        articles.merge(createSpicesItems(in: modelContext), uniquingKeysWith: { (_, new) in new })
        
        print("Total d'articles créés: \(articles.count)")
        return articles
    }
    
    // MARK: - Catégories d'articles
    
    /// Crée les articles de la catégorie Épicerie salée
    private static func createGroceryItems(in modelContext: ModelContext) -> [String: Article] {
        var items = [String: Article]()
        
        items["spaghetti"] = createArticle(name: "Spaghetti", category: "Épicerie salée", unit: "g", in: modelContext)
        items["pâte brisée"] = createArticle(name: "Pâte brisée", category: "Épicerie salée", unit: "pièce(s)", in: modelContext)
        items["riz"] = createArticle(name: "Riz", category: "Épicerie salée", unit: "g", in: modelContext)
        items["farine"] = createArticle(name: "Farine", category: "Épicerie salée", unit: "g", in: modelContext)
        items["huile olive"] = createArticle(name: "Huile d'olive", category: "Épicerie salée", unit: "cuillère(s) à soupe", in: modelContext)
        items["bouillon"] = createArticle(name: "Bouillon de légumes", category: "Épicerie salée", unit: "cube(s)", in: modelContext)
        items["lait de coco"] = createArticle(name: "Lait de coco", category: "Épicerie salée", unit: "ml", in: modelContext)
        
        return items
    }
    
    /// Crée les articles de la catégorie Viandes
    private static func createMeatItems(in modelContext: ModelContext) -> [String: Article] {
        var items = [String: Article]()
        
        items["lardons"] = createArticle(name: "Lardons", category: "Viandes", unit: "g", in: modelContext)
        items["veau"] = createArticle(name: "Blanquette de veau", category: "Viandes", unit: "g", in: modelContext)
        items["boeuf haché"] = createArticle(name: "Bœuf haché", category: "Viandes", unit: "g", in: modelContext)
        items["poulet"] = createArticle(name: "Blanc de poulet", category: "Viandes", unit: "g", in: modelContext)
        
        return items
    }
    
    /// Crée les articles de la catégorie Produits laitiers
    private static func createDairyItems(in modelContext: ModelContext) -> [String: Article] {
        var items = [String: Article]()
        
        items["parmesan"] = createArticle(name: "Parmesan", category: "Produits laitiers", unit: "g", in: modelContext)
        items["beurre"] = createArticle(name: "Beurre", category: "Produits laitiers", unit: "g", in: modelContext)
        items["crème fraîche"] = createArticle(name: "Crème fraîche", category: "Produits laitiers", unit: "ml", in: modelContext)
        items["lait"] = createArticle(name: "Lait", category: "Produits laitiers", unit: "ml", in: modelContext)
        items["gruyère"] = createArticle(name: "Gruyère râpé", category: "Produits laitiers", unit: "g", in: modelContext)
        items["œuf"] = createArticle(name: "Œuf", category: "Produits laitiers", unit: "pièce(s)", in: modelContext)
        
        return items
    }
    
    /// Crée les articles de la catégorie Fruits et légumes
    private static func createProduceItems(in modelContext: ModelContext) -> [String: Article] {
        var items = [String: Article]()
        
        items["oignon"] = createArticle(name: "Oignon", category: "Fruits et légumes", unit: "pièce(s)", in: modelContext)
        items["ail"] = createArticle(name: "Gousse d'ail", category: "Fruits et légumes", unit: "pièce(s)", in: modelContext)
        items["carotte"] = createArticle(name: "Carotte", category: "Fruits et légumes", unit: "pièce(s)", in: modelContext)
        items["tomate"] = createArticle(name: "Tomate", category: "Fruits et légumes", unit: "pièce(s)", in: modelContext)
        items["courgette"] = createArticle(name: "Courgette", category: "Fruits et légumes", unit: "pièce(s)", in: modelContext)
        items["aubergine"] = createArticle(name: "Aubergine", category: "Fruits et légumes", unit: "pièce(s)", in: modelContext)
        items["poivron"] = createArticle(name: "Poivron", category: "Fruits et légumes", unit: "pièce(s)", in: modelContext)
        items["pomme de terre"] = createArticle(name: "Pomme de terre", category: "Fruits et légumes", unit: "pièce(s)", in: modelContext)
        items["persil"] = createArticle(name: "Persil", category: "Fruits et légumes", unit: "bouquet(s)", in: modelContext)
        items["champignon"] = createArticle(name: "Champignon de Paris", category: "Fruits et légumes", unit: "g", in: modelContext)
        items["citron"] = createArticle(name: "Citron", category: "Fruits et légumes", unit: "pièce(s)", in: modelContext)
        items["poireau"] = createArticle(name: "Poireau", category: "Fruits et légumes", unit: "pièce(s)", in: modelContext)
        
        return items
    }
    
    /// Crée les articles de la catégorie Épices et herbes
    private static func createSpicesItems(in modelContext: ModelContext) -> [String: Article] {
        var items = [String: Article]()
        
        items["sel"] = createArticle(name: "Sel", category: "Épices et herbes", unit: "pincée(s)", in: modelContext)
        items["poivre"] = createArticle(name: "Poivre", category: "Épices et herbes", unit: "pincée(s)", in: modelContext)
        items["laurier"] = createArticle(name: "Feuille de laurier", category: "Épices et herbes", unit: "pièce(s)", in: modelContext)
        items["thym"] = createArticle(name: "Thym", category: "Épices et herbes", unit: "branche(s)", in: modelContext)
        items["muscade"] = createArticle(name: "Noix de muscade", category: "Épices et herbes", unit: "pincée(s)", in: modelContext)
        items["curry"] = createArticle(name: "Curry en poudre", category: "Épices et herbes", unit: "cuillère(s) à café", in: modelContext)
        items["herbes provence"] = createArticle(name: "Herbes de Provence", category: "Épices et herbes", unit: "cuillère(s) à café", in: modelContext)
        
        return items
    }
    
    // MARK: - Utilitaires
    
    /// Fonction utilitaire pour créer un article
    private static func createArticle(name: String, category: String, unit: String, in modelContext: ModelContext) -> Article {
        let article = Article(name: name, category: category, unit: unit, isFood: true)
        modelContext.insert(article)
        return article
    }
}
