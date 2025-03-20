import Foundation
import SwiftData

class IngredientsViewModel: ObservableObject {
    private var modelContext: ModelContext
    
    @Published var ingredients: [Ingredient] = []
    @Published var searchResults: [Ingredient] = []
    @Published var similarIngredientSuggestions: [Ingredient] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchIngredients()
    }
    
    func fetchIngredients() {
        let descriptor = FetchDescriptor<Ingredient>(sortBy: [SortDescriptor(\.name)])
        do {
            ingredients = try modelContext.fetch(descriptor)
        } catch {
            print("Erreur lors de la récupération des ingrédients: \(error)")
        }
    }
    
    // Recherche d'ingrédients avec gestion des similitudes
    func searchIngredient(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            similarIngredientSuggestions = []
            return
        }
        
        let normalizedQuery = normalizeString(query)
        
        // Recherche exacte d'abord (insensible à la casse)
        let exactResults = ingredients.filter {
            normalizeString($0.name).contains(normalizedQuery)
        }
        
        searchResults = exactResults
        
        // Si pas de résultat exact, chercher des similitudes
        if exactResults.isEmpty {
            findSimilarIngredients(to: query)
        } else {
            similarIngredientSuggestions = []
        }
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
    
    // Ajoute un nouvel ingrédient avec vérification des similitudes
    func addIngredient(name: String, category: String, unit: String) -> Ingredient? {
        // Vérifier si l'ingrédient existe déjà (correspondance exacte)
        let normalizedName = normalizeString(name)
        if let existingIngredient = ingredients.first(where: { normalizeString($0.name) == normalizedName }) {
            return existingIngredient
        }
        
        // Si l'ingrédient n'existe pas, le créer
        let newIngredient = Ingredient(name: name, category: category, unit: unit)
        modelContext.insert(newIngredient)
        saveContext()
        fetchIngredients()
        return newIngredient
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
        saveContext()
        fetchIngredients()
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
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de la sauvegarde du contexte: \(error)")
        }
    }
}
