#!/bin/bash
PROJECT_DIR="/Users/nicolasconstantin/Documents/Projets/Application_Iphone_Courses/Claude/MealPlanner"
OUTPUT_DIR="/Users/nicolasconstantin/Documents/Projets/Application_Iphone_Courses/CodePDF"

# Création du dossier de sortie s'il n'existe pas
mkdir -p "$OUTPUT_DIR"

# Recherche de tous les fichiers source Swift, Objective-C et headers
find "$PROJECT_DIR" -name "*.swift" -o -name "*.h" -o -name "*.m" | while read file; do
    # Extraction du nom du fichier
    filename=$(basename "$file")
    # Conversion en PDF
    enscript -p - "$file" | ps2pdf - "$OUTPUT_DIR/${filename}.pdf"
    echo "Converti: $filename"
done

echo "Conversion terminée. Les PDF se trouvent dans $OUTPUT_DIR"
