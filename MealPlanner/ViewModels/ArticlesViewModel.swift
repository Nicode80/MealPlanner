import Foundation
import SwiftData
import SwiftUI
import Observation

@Observable
class ArticlesViewModel {
    private var modelContext: ModelContext
    
    // Liste des articles existants
    var articles: [Article] = []
    var selectedArticle: Article?
    
    // Champs pour la création d'un nouvel article
    var newArticleName: String = ""
    var newArticleCategory: String = "Fruits et légumes"
    var newArticleUnit: String = "pièce(s)"
    var newArticleIsFood: Bool = true
    
    // Recherche et filtrage
    var searchText: String = ""
    var searchResults: [Article] = []
    var similarArticleSuggestions: [Article] = []
    
    // Catégories alimentaires
    let foodCategories = [
        "Fruits et légumes", "Viandes", "Poissons et fruits de mer",
        "Produits laitiers", "Boulangerie", "Épicerie sucrée",
        "Épicerie salée", "Boissons", "Surgelés", "Épices et herbes"
    ]
    
    // Catégories non-alimentaires
    let nonFoodCategories = [
        "Hygiène et beauté", "Produits d'entretien", "Maison et déco",
        "Vêtements", "Ustensiles et cuisine", "Papeterie",
        "Électronique", "Jardinage", "Animalerie"
    ]
    
    // Toutes les catégories
    var allCategories: [String] {
        return foodCategories + nonFoodCategories
    }
    
    // Unités prédéfinies
    let units = ["g", "kg", "ml", "l", "pièce(s)", "tranche(s)", "cuillère(s) à café", "cuillère(s) à soupe", "boîte(s)", "paquet(s)"]
    
    // Unités qui doivent utiliser des valeurs décimales (pas de 0.1)
    let decimalUnits = ["kg", "l"]
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchArticles()
    }
    
    func fetchArticles() {
        let descriptor = FetchDescriptor<Article>(sortBy: [SortDescriptor(\.name)])
        do {
            articles = try modelContext.fetch(descriptor)
            // Initialiser les résultats de recherche avec tous les articles
            searchResults = articles
        } catch {
            print("Erreur lors de la récupération des articles: \(error)")
        }
    }
    
    // Obtenir les catégories appropriées selon le contexte
    func getCategories(forRecipe: Bool = true) -> [String] {
        return forRecipe ? foodCategories : allCategories
    }
    
    // Déterminer si une unité utilise des valeurs décimales
    func isDecimalUnit(_ unit: String) -> Bool {
        return decimalUnits.contains(unit)
    }
    
    // Obtenir le pas d'incrémentation pour une unité donnée
    func getStepValue(for unit: String) -> Double {
        return isDecimalUnit(unit) ? 0.1 : 1.0
    }
    
    // Obtenir les articles alimentaires uniquement
    func getFoodArticles() -> [Article] {
        return articles.filter { $0.isFood }
    }
    
    // Recherche d'articles avec gestion des similitudes
    func searchArticle(query: String, forRecipe: Bool = true) {
        searchText = query
        
        // Base d'articles à filtrer (tous ou seulement alimentaires)
        let baseArticles = forRecipe ? getFoodArticles() : articles
        
        guard !query.isEmpty else {
            searchResults = baseArticles
            similarArticleSuggestions = []
            return
        }
        
        let normalizedQuery = normalizeString(query)
        
        // Recherche exacte d'abord (insensible à la casse)
        searchResults = baseArticles.filter {
            normalizeString($0.name).contains(normalizedQuery)
        }
        
        // Si pas de résultat exact, chercher des similitudes
        if searchResults.isEmpty {
            findSimilarArticles(to: query, in: baseArticles)
        } else {
            similarArticleSuggestions = []
        }
    }
    
    // Vérification de l'existence d'un nom similaire
    func checkForSimilarArticle(name: String, forRecipe: Bool = true) -> Article? {
        guard !name.isEmpty else { return nil }
        
        // Base d'articles pour la recherche
        let baseArticles = forRecipe ? getFoodArticles() : articles
        
        let normalizedName = normalizeString(name)
        
        // Vérifier d'abord les correspondances exactes ou très proches
        if let exactMatch = baseArticles.first(where: {
            let articleName = normalizeString($0.name)
            return articleName == normalizedName ||
                   articleName.replacingOccurrences(of: "s", with: "") == normalizedName.replacingOccurrences(of: "s", with: "") // Gère singulier/pluriel
        }) {
            return exactMatch
        }
        
        // Vérifier les noms similaires avec une distance plus stricte
        let similarArticles = baseArticles.filter { article in
            let distance = levenshteinDistance(normalizedName, normalizeString(article.name))
            return distance <= 1 && distance > 0 // Plus strict : seulement 1 caractère de différence
        }
        
        // Si aucun résultat avec distance 1, essayer avec une distance de 2
        if similarArticles.isEmpty {
            let lessSimilarArticles = baseArticles.filter { article in
                let distance = levenshteinDistance(normalizedName, normalizeString(article.name))
                // Pour les noms plus longs, une distance de 2 peut être pertinente
                return distance <= 2 && distance > 1 && normalizedName.count > 4
            }
            return lessSimilarArticles.first
        }
        
        return similarArticles.first
    }
    
    // Trouve des articles similaires à une chaîne donnée
    private func findSimilarArticles(to query: String, in baseArticles: [Article]) {
        let normalizedQuery = normalizeString(query)
        
        // Filtre les articles dont la distance de Levenshtein est faible
        similarArticleSuggestions = baseArticles.filter { article in
            let normalizedName = normalizeString(article.name)
            return levenshteinDistance(normalizedQuery, normalizedName) <= 2 // Tolérance de 2 caractères
        }
    }
    
    // Ajoute un nouvel article
    func addArticle(name: String, category: String, unit: String, isFood: Bool = true) -> Article? {
        guard !name.isEmpty && !category.isEmpty && !unit.isEmpty else {
            return nil
        }
        
        // Vérifier doublon avant création
        if let existingArticle = checkForSimilarArticle(name: name, forRecipe: isFood) {
            return existingArticle
        }
        
        // Si l'article n'existe pas, le créer
        let newArticle = Article(name: name, category: category, unit: unit, isFood: isFood)
        modelContext.insert(newArticle)
        try? modelContext.save()
        fetchArticles()
        
        // Réinitialiser les champs
        resetNewArticleFields()
        
        return newArticle
    }
    
    func resetNewArticleFields() {
        newArticleName = ""
        newArticleCategory = "Fruits et légumes"
        newArticleUnit = "pièce(s)"
        newArticleIsFood = true
    }
    
    // Fusionne deux articles (conserve le premier et supprime le second)
    func mergeArticles(keep: Article, remove: Article) {
        // Transférer toutes les recettes de l'article à supprimer vers celui à conserver
        if let recipeIngredients = remove.recipeIngredients {
            for recipeIngredient in recipeIngredients {
                recipeIngredient.article = keep
            }
        }
        
        // Transférer tous les éléments de liste de courses
        if let shoppingItems = remove.shoppingListItems {
            for item in shoppingItems {
                item.article = keep
            }
        }
        
        // Supprimer l'article en double
        modelContext.delete(remove)
        try? modelContext.save()
        fetchArticles()
    }
    
    // Récupérer les articles groupés par catégorie
    var articlesByCategory: [String: [Article]] {
        Dictionary(grouping: searchResults) { $0.category }
    }
    
    // Normalisation des chaînes pour comparaisons
    private func normalizeString(_ input: String) -> String {
        return input
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current) // Supprime les accents
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Implémentation de la distance de Levenshtein pour détecter les similitudes
    private func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let aCount = a.count
        let bCount = b.count
        
        // Cas spéciaux
        if aCount == 0 { return bCount }
        if bCount == 0 { return aCount }
        
        // Créer la matrice
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: bCount + 1), count: aCount + 1)
        
        // Initialiser la première ligne et la première colonne
        for i in 0...aCount {
            matrix[i][0] = i
        }
        
        for j in 0...bCount {
            matrix[0][j] = j
        }
        
        // Remplir la matrice
        let aChars = Array(a)
        let bChars = Array(b)
        
        for i in 1...aCount {
            for j in 1...bCount {
                let cost = aChars[i-1] == bChars[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // suppression
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }
        
        return matrix[aCount][bCount]
    }
}
