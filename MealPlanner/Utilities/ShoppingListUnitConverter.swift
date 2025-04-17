import Foundation
import SwiftData

/// Classe utilitaire pour convertir les unités des recettes en unités pour les courses
class ShoppingListUnitConverter {
    
    /// Convertit la quantité d'un ingrédient depuis l'unité de recette vers l'unité de courses
    /// - Parameters:
    ///   - item: L'élément de la liste de courses
    /// - Returns: Une paire (quantité, unité) adaptée pour l'affichage dans la liste de courses
    static func convertToShoppingUnit(item: ShoppingListItem) -> (quantity: Double, unit: String) {
        guard let article = item.article else {
            return (item.quantity, "")
        }
        
        // Récupérer les informations de base
        let ingredientName = article.name
        let recipeUnit = article.unit
        var quantity = item.quantity
        
        // Traiter les ingrédients qui nécessitent une conversion spéciale
        return convertSpecialCases(ingredientName: ingredientName, recipeUnit: recipeUnit, quantity: quantity)
    }
    
    /// Fonction de conversion pour les cas spéciaux
    private static func convertSpecialCases(ingredientName: String, recipeUnit: String, quantity: Double) -> (quantity: Double, unit: String) {
        
        // ===== Conversions vers litre =====
        if ingredientName == "Huile d'olive" {
            if recipeUnit == "cuillère(s) à soupe" {
                // 1 c. à soupe ≈ 15 ml
                let liters = quantity * 0.015
                return (roundLiquidQuantity(liters), "L")
            } else if recipeUnit == "ml" {
                let liters = quantity / 1000
                return (roundLiquidQuantity(liters), "L")
            }
        }
        
        if ingredientName == "Lait" {
            if recipeUnit == "cl" {
                let liters = quantity / 100
                return (roundLiquidQuantity(liters), "L")
            } else if recipeUnit == "ml" {
                let liters = quantity / 1000
                return (roundLiquidQuantity(liters), "L")
            }
        }
        
        if ingredientName == "Eau" && recipeUnit == "cl" {
            let liters = quantity / 100
            return (roundLiquidQuantity(liters), "L")
        }
        
        // ===== Conversions vers kilogramme =====
        if (ingredientName == "Farine" || ingredientName == "Farine de sarrasin" ||
            ingredientName == "Pomme de terre" || ingredientName == "Viande de bœuf hachée" ||
            ingredientName == "Veau pour blanquette" || ingredientName == "Poulet") && recipeUnit == "g" {
            
            if quantity < 1000 {
                return (quantity, "g")
            } else {
                let kg = quantity / 1000
                return (roundWeightQuantity(kg), "kg")
            }
        }
        
        // ===== Cas particulier des œufs =====
        if (ingredientName == "Œuf" || ingredientName == "Œuf (pour la garniture)" || ingredientName == "Jaune d'œuf") && recipeUnit == "pièce(s)" {
            return (quantity, "pièce(s)")
        }
        
        // ==== Gestion des unités inchangées =====
        
        // Garder certaines unités telles quelles
        if ingredientName == "Crème fraîche" && recipeUnit == "cl" {
            return (quantity, "cl")
        }
        
        if ingredientName == "Lait de coco" && recipeUnit == "ml" {
            return (quantity / 10, "cl") // Conversion ml -> cl
        }
        
        // Par défaut, garder l'unité d'origine pour les ingrédients qui n'ont pas besoin de conversion
        if ["g", "pièce(s)", "tranche(s)", "sachet(s)"].contains(recipeUnit) {
            return (quantity, recipeUnit)
        }
        
        // ===== Cas spécifiques =====
        
        // Vin
        if ingredientName == "Vin blanc" && recipeUnit == "ml" {
            // Une bouteille = 750ml
            if quantity <= 200 {
                return (quantity, "ml")
            } else {
                return (1, "bouteille")
            }
        }
        
        // Beurre
        if ingredientName == "Beurre" && recipeUnit == "g" {
            if quantity <= 100 {
                return (quantity, "g")
            } else {
                // Une plaquette = 250g
                let plaquettes = quantity / 250
                if plaquettes < 0.5 {
                    return (quantity, "g")
                } else {
                    return (ceil(plaquettes * 2) / 2, "plaquette(s)") // Arrondi au 0.5 supérieur
                }
            }
        }
        
        // ===== Autres conversions =====
        
        // Épices en pincées -> paquet
        if (ingredientName == "Sel" || ingredientName == "Poivre") && recipeUnit == "pincée(s)" {
            return (1, "paquet")
        }
        
        // Épices en cuillères -> sachet
        if (ingredientName == "Herbes de Provence" || ingredientName == "Paprika" ||
            ingredientName == "Curry") && recipeUnit == "cuillère(s) à café" {
            return (1, "sachet")
        }
        
        if ingredientName == "Muscade" && recipeUnit == "pincée(s)" {
            return (1, "sachet")
        }
        
        // Miel, moutarde -> pot
        if (ingredientName == "Miel" || ingredientName == "Moutarde") &&
           (recipeUnit == "cuillère(s) à café" || recipeUnit == "cuillère(s) à soupe") {
            return (1, "pot")
        }
        
        // Vinaigrette, vinaigre -> bouteille
        if (ingredientName == "Vinaigrette" || ingredientName == "Vinaigre balsamique") &&
           recipeUnit == "cuillère(s) à soupe" {
            return (1, "bouteille")
        }
        
        // Herbes fraîches en branches -> bouquet
        if (ingredientName == "Thym" || ingredientName == "Romarin" || ingredientName == "Persil") &&
           recipeUnit == "branche(s)" {
            return (1, "bouquet")
        }
        
        if ingredientName == "Laurier" && recipeUnit == "feuille(s)" {
            return (1, "sachet")
        }
        
        // Jus de citron en cuillères -> citrons
        if ingredientName == "Jus de citron" && recipeUnit == "cuillère(s) à café" {
            // 1 citron donne environ 2-3 cuillères à café de jus
            return (ceil(quantity / 3), "citron(s)")
        }
        
        // Salade
        if ingredientName == "Salade verte" && recipeUnit == "g" {
            return (1, "pièce")
        }
        
        // Tomates cerises
        if ingredientName == "Tomates cerises" && recipeUnit == "pièce(s)" {
            return (1, "barquette")
        }
        
        // Par défaut, conserver l'unité d'origine
        return (quantity, recipeUnit)
    }
    
    // Arrondit intelligemment les quantités de liquides
    private static func roundLiquidQuantity(_ liters: Double) -> Double {
        if liters < 0.1 {
            // Moins de 100ml, arrondir aux 25ml supérieurs
            return ceil(liters * 40) / 40
        } else if liters < 0.5 {
            // Entre 100ml et 500ml, arrondir aux 50ml supérieurs
            return ceil(liters * 20) / 20
        } else if liters < 1 {
            // Entre 500ml et 1L, arrondir aux 100ml supérieurs
            return ceil(liters * 10) / 10
        } else {
            // 1L ou plus, arrondir aux 0.25L supérieurs
            return ceil(liters * 4) / 4
        }
    }
    
    // Arrondit intelligemment les quantités de poids
    private static func roundWeightQuantity(_ kg: Double) -> Double {
        if kg < 0.1 {
            // Moins de 100g, arrondir aux 25g supérieurs
            return ceil(kg * 40) / 40
        } else if kg < 0.5 {
            // Entre 100g et 500g, arrondir aux 50g supérieurs
            return ceil(kg * 20) / 20
        } else if kg < 1 {
            // Entre 500g et 1kg, arrondir aux 100g supérieurs
            return ceil(kg * 10) / 10
        } else {
            // 1kg ou plus, arrondir aux 0.25kg supérieurs
            return ceil(kg * 4) / 4
        }
    }
}

// Extension à ShoppingListItem pour faciliter son utilisation
extension ShoppingListItem {
    /// Obtient la quantité et l'unité adaptées pour l'affichage dans la liste de courses
    var shoppingDisplay: (quantity: Double, unit: String) {
        return ShoppingListUnitConverter.convertToShoppingUnit(item: self)
    }
    
    /// Format la quantité et l'unité pour l'affichage
    var formattedShoppingQuantity: String {
        let converted = self.shoppingDisplay
        
        // Formatter la quantité en fonction de son type
        let isInteger = converted.quantity.truncatingRemainder(dividingBy: 1) == 0
        
        if isInteger {
            return "\(Int(converted.quantity)) \(converted.unit)"
        } else {
            // Pour 0.5, 0.25, etc., utiliser une fraction
            if converted.quantity == 0.5 {
                return "½ \(converted.unit)"
            } else if converted.quantity == 0.25 {
                return "¼ \(converted.unit)"
            } else if converted.quantity == 0.75 {
                return "¾ \(converted.unit)"
            } else if converted.quantity == 0.33 || converted.quantity.rounded(.toNearestOrEven) == 0.33 {
                return "⅓ \(converted.unit)"
            } else if converted.quantity == 0.67 || converted.quantity.rounded(.toNearestOrEven) == 0.67 {
                return "⅔ \(converted.unit)"
            } else {
                // Utiliser 1 décimale pour les autres valeurs
                return String(format: "%.1f \(converted.unit)", converted.quantity)
            }
        }
    }
}
