#!/bin/bash

# ==============================================================================
# SCRIPT FINAL pour ajouter le menu "Marins" et les traductions.
#
# Cette version utilise une méthode plus simple et plus sûre pour modifier
# le fichier HTML, en le découpant et en le reconstruisant, afin d'éviter
# toute erreur de syntaxe avec `sed` ou `awk`.
# ==============================================================================

# --- Configuration ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- 1. Modification du menu principal (HTML) ---
echo -e " Mofification du menu principal..."

HTML_FILE="src/app/dashboard/dashboard.component.html"
TMP_FILE="${HTML_FILE}.tmp"

# Vérification du fichier
if [ ! -f "$HTML_FILE" ]; then
    echo -e "  -> ${RED}Erreur : Fichier non trouvé :${NC} $HTML_FILE"
    exit 1
fi

# Le bloc de code HTML à insérer
read -r -d '' HTML_BLOCK <<'EOF'
        <li *ngIf="selectedBoat">
          <a [routerLink]="['/dashboard/bateaux', selectedBoat.id, 'marins']" routerLinkActive="active" class="nav-item">
            <svg class="nav-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
            <span>{{ 'MENU.SAILORS' | translate }}</span>
          </a>
        </li>
        <li *ngIf="!selectedBoat" class="menu-disabled">
          <div class="nav-item-disabled">
            <svg class="nav-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
            <span>{{ 'MENU.SAILORS' | translate }}</span>
          </div>
          <div class="tooltip-disabled">
            {{ 'MENU.SELECT_BOAT_FIRST' | translate }}
          </div>
        </li>
EOF

# Créer une sauvegarde
cp "$HTML_FILE" "${HTML_FILE}.bak"

# Logique de modification : trouver la ligne de fin du bloc "Bateaux" et insérer après
# 1. Trouver le numéro de ligne contenant le lien des bateaux
BOAT_LINK_LINE=$(grep -n 'routerLink="/dashboard/bateaux"' "$HTML_FILE" | cut -d: -f1)

if [ -z "$BOAT_LINK_LINE" ]; then
    echo -e "  -> ${RED}Erreur : Impossible de trouver la ligne de référence pour le menu 'Bateaux'. Abandon.${NC}"
    exit 1
fi

# 2. Trouver le numéro de ligne du `</li>` qui ferme ce bloc
INSERT_AFTER_LINE=$(awk "NR > $BOAT_LINK_LINE && /<\/li>/ {print NR; exit}" "$HTML_FILE")

if [ -z "$INSERT_AFTER_LINE" ]; then
    echo -e "  -> ${RED}Erreur : Impossible de trouver où insérer le nouveau menu. Abandon.${NC}"
    exit 1
fi

# 3. Reconstruire le fichier
{
  # Copier le début du fichier, jusqu'à la ligne d'insertion
  head -n "$INSERT_AFTER_LINE" "$HTML_FILE"
  # Insérer le nouveau bloc de code
  echo "$HTML_BLOCK"
  # Copier le reste du fichier
  tail -n "+$(($INSERT_AFTER_LINE + 1))" "$HTML_FILE"
} > "$TMP_FILE" && mv "$TMP_FILE" "$HTML_FILE"

echo -e "  -> ${GREEN}Succès :${NC} Le menu 'Marins' a été ajouté à '$HTML_FILE'."

# --- 2. Modification des fichiers de traduction ---
echo -e "\n Mise à jour des fichiers de traduction..."

function add_translation() {
    local file=$1
    local anchor=$2
    local newline=$3
    if [ ! -f "$file" ]; then
        echo -e "  -> ${RED}Erreur : Fichier de traduction non trouvé :${NC} $file"
        return
    fi
    # Ajoute la ligne seulement si la clé "SAILORS" n'existe pas déjà
    if ! grep -q '"SAILORS"' "$file"; then
        sed -i '.bak' "s/${anchor}/${anchor}\
${newline}/" "$file"
        echo -e "  -> ${GREEN}Succès :${NC} Traduction ajoutée à '$file'."
    else
        echo -e "  -> ${YELLOW}Info :${NC} La clé de traduction existe déjà dans '$file'."
    fi
}

add_translation "src/assets/i18n/fr.json" '"BOATS": "Bateaux",' '    "SAILORS": "Marins",'
add_translation "src/assets/i18n/en.json" '"BOATS": "Boats",' '    "SAILORS": "Sailors",'
add_translation "src/assets/i18n/ar.json" '"BOATS": "المراكب",' '    "SAILORS": "البحارة",'

echo -e "\n${GREEN}✅ Opération terminée avec succès !${NC}"