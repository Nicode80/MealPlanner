import Foundation
import SwiftData
import SwiftUI
import Observation

@Observable
class IngredientsViewModel {
    private var modelContext: ModelContext
    
    // Liste des ingrédients existants
    var ingredients: [Ingredient] = []
    var selectedIngredient: Ingredient?
    
    // Champs pour la création d'un nouvel ingrédient
    var newIngredientName: String = ""
    var newIngredientCategory: String = "Fruits et légumes"
    var newIngredientUnit: String = "pièce(s)"
    
    // Recherche et filtrage
    var searchText: String = ""
    var searchResults: [Ingredient] = []
    var similarIngredientSuggestions: [Ingredient] = []
    
    // Catégories prédéfinies
    let categories = [
        "Fruits et légumes", "Viandes", "Poissons et fruits de mer",
        "Produits laitiers", "Boulangerie", "Épicerie sucrée",
        "Épicerie salée", "Boissons", "Surgelés", "Hygiène"
    ]
    
    // Unités prédéfinies
    let units = ["g", "kg", "ml", "l", "pièce(s)", "tranche(s)", "cuillère(s) à café", "cuillère(s) à soupe"]
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchIngredients()
    }
    
    func fetchIngredients() {
        let descriptor = FetchDescriptor<Ingredient>(sortBy: [SortDescriptor(\.name)])
        do {
            ingredients = try modelContext.fetch(descriptor)
            // Initialiser les résultats de recherche avec tous les ingrédients
            searchResults = ingredients
        } catch {
            print("Erreur lors de la récupération des ingrédients: \(error)")
        }
    }
    
    // Recherche d'ingrédients avec gestion des similitudes
    func searchIngredient(query: String) {
        searchText = query
        
        guard !query.isEmpty else {
            searchResults = ingredients
            similarIngredientSuggestions = []
            return
        }
        
        let normalizedQuery = normalizeString(query)
        
        // Recherche exacte d'abord (insensible à la casse)
        searchResults = ingredients.filter {
            normalizeString($0.name).contains(normalizedQuery)
        }
        
        // Si pas de résultat exact, chercher des similitudes
        if searchResults.isEmpty {
            findSimilarIngredients(to: query)
        } else {
            similarIngredientSuggestions = []
        }
    }
    
    // Vérification de l'existence d'un nom similaire
    func checkForSimilarIngredient(name: String) -> Ingredient? {
        guard !name.isEmpty else { return nil }
        
        let normalizedName = normalizeString(name)
        
        // Vérifier d'abord les correspondances exactes ou très proches
        if let exactMatch = ingredients.first(where: {
            let ingredientName = normalizeString($0.name)
            return ingredientName == normalizedName ||
                   ingredientName.replacingOccurrences(of: "s", with: "") == normalizedName.replacingOccurrences(of: "s", with: "") // Gère singulier/pluriel
        }) {
            return exactMatch
        }
        
        // Vérifier les noms similaires avec une distance plus stricte
        let similarIngredients = ingredients.filter { ingredient in
            let distance = levenshteinDistance(normalizedName, normalizeString(ingredient.name))
            return distance <= 1 && distance > 0 // Plus strict : seulement 1 caractère de différence
        }
        
        // Si aucun résultat avec distance 1, essayer avec une distance de 2
        if similarIngredients.isEmpty {
            let lessSimilarIngredients = ingredients.filter { ingredient in
                let distance = levenshteinDistance(normalizedName, normalizeString(ingredient.name))
                // Pour les noms plus longs, une distance de 2 peut être pertinente
                return distance <= 2 && distance > 1 && normalizedName.count > 4
            }
            return lessSimilarIngredients.first
        }
        
        return similarIngredients.first
    }
    
    // Trouve des ingrédients similaires à une chaîne donnée
    private func findSimilarIngredients(to query: String) {
        let normalizedQuery = normalizeString(query)
        
        // Filtre les ingrédients dont la distance de Levenshtein est faible
        similarIngredientSuggestions = ingredients.filter { ingredient in
            let normalizedName = normalizeString(ingredient.name)
            return levenshteinDistance(normalizedQuery, normalizedName) <= 2 // Tolérance de 2 caractères
        }
    }
    
    // Ajoute un nouvel ingrédient
    func addIngredient(name: String, category: String, unit: String) -> Ingredient? {
        guard !name.isEmpty && !category.isEmpty && !unit.isEmpty else {
            return nil
        }
        
        // Vérifier doublon avant création - utilise la même logique que checkForSimilarIngredient
        if let existingIngredient = checkForSimilarIngredient(name: name) {
            return existingIngredient
        }
        
        // Si l'ingrédient n'existe pas, le créer
        let newIngredient = Ingredient(name: name, category: category, unit: unit)
        modelContext.insert(newIngredient)
        try? modelContext.save()
        fetchIngredients()
        
        // Réinitialiser les champs
        resetNewIngredientFields()
        
        return newIngredient
    }
    
    func resetNewIngredientFields() {
        newIngredientName = ""
        newIngredientCategory = "Fruits et légumes"
        newIngredientUnit = "pièce(s)"
    }
    
    // Fusionne deux ingrédients (conserve le premier et supprime le second)
    func mergeIngredients(keep: Ingredient, remove: Ingredient) {
        // Transférer toutes les recettes de l'ingrédient à supprimer vers celui à conserver
        if let recipeIngredients = remove.recipeIngredients {
            for recipeIngredient in recipeIngredients {
                recipeIngredient.ingredient = keep
            }
        }
        
        // Transférer tous les éléments de liste de courses
        if let shoppingItems = remove.shoppingListItems {
            for item in shoppingItems {
                item.ingredient = keep
            }
        }
        
        // Supprimer l'ingrédient en double
        modelContext.delete(remove)
        try? modelContext.save()
        fetchIngredients()
    }
    
    // Récupérer les ingrédients groupés par catégorie
    var ingredientsByCategory: [String: [Ingredient]] {
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
