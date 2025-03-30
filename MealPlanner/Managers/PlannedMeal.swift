import Foundation
import SwiftData
import Combine

// Structure pour représenter un repas planifié
struct PlannedMeal: Identifiable, Equatable, Codable {
    var id = UUID()
    var recipeId: PersistentIdentifier  // Utiliser PersistentIdentifier pour identifier la recette
    var numberOfPeople: Int
    var dayOfWeek: Int // 0 = Lundi, 1 = Mardi, etc.
    var mealType: MealType
    
    enum MealType: String, CaseIterable, Identifiable, Codable {
        case breakfast = "Petit-déjeuner"
        case lunch = "Déjeuner"
        case dinner = "Dîner"
        
        var id: String { self.rawValue }
    }
    
    // Implémentation de Equatable pour permettre la comparaison
    static func == (lhs: PlannedMeal, rhs: PlannedMeal) -> Bool {
        lhs.id == rhs.id &&
        lhs.recipeId == rhs.recipeId &&
        lhs.numberOfPeople == rhs.numberOfPeople &&
        lhs.dayOfWeek == rhs.dayOfWeek &&
        lhs.mealType == rhs.mealType
    }
    
    // Constructeur qui prend une Recipe au lieu d'un ID
    init(recipe: Recipe, numberOfPeople: Int, dayOfWeek: Int, mealType: MealType) {
        self.recipeId = recipe.persistentModelID
        self.numberOfPeople = numberOfPeople
        self.dayOfWeek = dayOfWeek
        self.mealType = mealType
    }
}

// Classe pour gérer l'état des repas planifiés et la synchronisation entre vues
class PlannerManager: ObservableObject {
    static let shared = PlannerManager()
    
    private init() {
        loadMeals()
    }
    
    // Propriété observable pour les repas planifiés
    @Published var plannedMeals: [PlannedMeal] = []
    
    // Clé pour UserDefaults
    private let plannerKey = "plannedMeals"
    
    // Ajouter un repas planifié
    func addMeal(_ meal: PlannedMeal) {
        plannedMeals.append(meal)
        saveMeals()
    }
    
    // Supprimer un repas planifié
    func removeMeal(_ meal: PlannedMeal) {
        plannedMeals.removeAll { $0.id == meal.id }
        saveMeals()
    }
    
    // Sauvegarder les repas dans UserDefaults
    private func saveMeals() {
        if let encoded = try? JSONEncoder().encode(plannedMeals) {
            UserDefaults.standard.set(encoded, forKey: plannerKey)
        }
    }
    
    // Charger les repas depuis UserDefaults
    private func loadMeals() {
        if let savedMeals = UserDefaults.standard.data(forKey: plannerKey) {
            if let decodedMeals = try? JSONDecoder().decode([PlannedMeal].self, from: savedMeals) {
                plannedMeals = decodedMeals
            }
        }
    }
    
    // Récupérer les repas pour un jour spécifique
    func mealsForDay(_ day: Int) -> [PlannedMeal] {
        return plannedMeals.filter { $0.dayOfWeek == day }
    }
    
    // Récupérer tous les repas
    func getAllMeals() -> [PlannedMeal] {
        return plannedMeals
    }
}
