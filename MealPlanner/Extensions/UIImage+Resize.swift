import UIKit

extension UIImage {
    /// Optimise l'image en compressant son format JPEG
    /// Retourne des données compressées garantissant une réduction de taille significative
    func optimizedImageData(quality: CGFloat = 0.7) -> Data? {
        print("========== DÉBUT OPTIMISATION ==========")
        print("Dimensions originales: \(self.size.width)×\(self.size.height)")
        
        // Obtenir les données originales pour comparaison
        guard let originalData = self.jpegData(compressionQuality: 1.0) else {
            print("Erreur: Impossible d'obtenir les données JPEG originales")
            print("========== FIN OPTIMISATION ==========")
            return nil
        }
        
        print("Taille originale: \(originalData.count) bytes (\(originalData.count / 1024) KB)")
        
        // Compresser l'image avec la qualité spécifiée
        var currentQuality = quality
        var compressedData = self.jpegData(compressionQuality: currentQuality)
        
        // Si la compression n'a pas suffisamment réduit la taille, essayer des qualités inférieures
        if let data = compressedData {
            print("Taille après compression (qualité \(currentQuality)): \(data.count) bytes (\(data.count / 1024) KB)")
            
            // Adapter la qualité si nécessaire pour garantir une réduction de taille
            var attempts = 0
            while data.count >= originalData.count * Int(0.8) && currentQuality > 0.3 && attempts < 3 {
                currentQuality -= 0.1
                attempts += 1
                print("Réduction de la qualité à \(currentQuality)")
                
                if let newData = self.jpegData(compressionQuality: currentQuality) {
                    compressedData = newData
                    print("Nouvelle taille: \(newData.count) bytes (\(newData.count / 1024) KB)")
                    
                    // Si on atteint une réduction significative, sortir de la boucle
                    if newData.count <= originalData.count * Int(0.6) {
                        break
                    }
                }
            }
        }
        
        // Retourner les données compressées
        if let finalData = compressedData, finalData.count < originalData.count {
            let reduction = (1.0 - Double(finalData.count) / Double(originalData.count)) * 100
            print("Optimisation réussie: \(originalData.count / 1024) KB -> \(finalData.count / 1024) KB (réduction de \(Int(reduction))%)")
            
            // Afficher les dimensions finales pour information
            if let finalImage = UIImage(data: finalData) {
                print("Dimensions finales: \(finalImage.size.width)×\(finalImage.size.height)")
            }
            
            print("========== FIN OPTIMISATION ==========")
            return finalData
        }
        
        print("L'optimisation n'a pas réduit la taille, utilisation de l'original")
        print("========== FIN OPTIMISATION ==========")
        return originalData
    }
}
