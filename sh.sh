#!/bin/bash

echo "🚀 Démarrage du correctif pour le menu mobile..."

# 1. Mettre à jour src/app/dashboard/dashboard.component.ts
echo "Updating dashboard.component.ts..."
if ! grep -q "isSidebarOpen" "src/app/dashboard/dashboard.component.ts"; then
  # Ajouter la propriété isSidebarOpen
  sed -i "s/selectedBoat: Bateau | null = null;/selectedBoat: Bateau | null = null;\\n  isSidebarOpen = false;/g" src/app/dashboard/dashboard.component.ts
  
  # Ajouter la méthode toggleSidebar() après la méthode logout()
  sed -i "/async logout(): Promise<void> {/,/}/ { /}/a \\
    \\n  toggleSidebar(): void {\\n    this.isSidebarOpen = !this.isSidebarOpen;\\n  }\\n
  }" src/app/dashboard/dashboard.component.ts
  echo "✅ dashboard.component.ts mis à jour."
else
  echo "⚠️ dashboard.component.ts semble déjà modifié."
fi


# 2. Mettre à jour src/app/dashboard/dashboard.component.html
echo "Updating dashboard.component.html..."
if ! grep -q "sidebar-open" "src/app/dashboard/dashboard.component.html"; then
  # Ajouter la classe binding au layout principal
  sed -i 's/<div class="dashboard-layout">/<div class="dashboard-layout" [class.sidebar-open]="isSidebarOpen">/g' src/app/dashboard/dashboard.component.html
  
  # Ajouter l'overlay après la sidebar
  sed -i "/<\/aside>/a \\  \\n  <div class=\"sidebar-overlay\" (click)=\"toggleSidebar()\"></div>" src/app/dashboard/dashboard.component.html
  
  # Ajouter le bouton hamburger dans le header
  sed -i "/<header class=\"header\">/a \\    \\n    <button class=\"btn-menu-mobile\" (click)=\"toggleSidebar()\">\\n      <svg fill=\"none\" viewBox=\"0 0 24 24\" stroke=\"currentColor\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M4 6h16M4 12h16M4 18h16\" \/><\/svg>\\n    <\/button>" src/app/dashboard/dashboard.component.html
  echo "✅ dashboard.component.html mis à jour."
else
  echo "⚠️ dashboard.component.html semble déjà modifié."
fi


# 3. Mettre à jour src/app/dashboard/dashboard.component.scss
echo "Updating dashboard.component.scss..."
if ! grep -q "STYLES MENU MOBILE AJOUTÉS" "src/app/dashboard/dashboard.component.scss"; then
  # Ajouter tous les nouveaux styles CSS à la FIN du fichier .scss
  cat << 'EOF' >> src/app/dashboard/dashboard.component.scss
/* ===================================
   STYLES MENU MOBILE AJOUTÉS
   =================================== */

.btn-menu-mobile {
  display: none; /* Caché par défaut sur grand écran */
  background: none;
  border: none;
  color: #374151;
  padding: 0.5rem;
  cursor: pointer;
  border-radius: 0.375rem;
  transition: background-color 0.2s;
  svg { width: 28px; height: 28px; }
  &:hover {
    background-color: #f3f4f6;
  }
}

.sidebar-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5);
  z-index: 999; /* Juste en dessous du sidebar (1000) */
  opacity: 0;
  visibility: hidden;
  transition: opacity 0.3s ease, visibility 0.3s ease;
}

@media (max-width: 768px) {
  .btn-menu-mobile {
    display: block; /* Afficher le bouton */
  }

  /* Styles quand le menu LTR est ouvert */
  .dashboard-layout.sidebar-open {
    .sidebar {
      transform: translateX(0); /* Afficher le menu */
    }
    .sidebar-overlay {
      opacity: 1;
      visibility: visible;
    }
  }
}

:host-context(.rtl) {
  @media (max-width: 768px) {
    /* Styles quand le menu RTL est ouvert */
    .dashboard-layout.sidebar-open {
      .sidebar {
        transform: translateX(0); /* Afficher le menu */
      }
      .sidebar-overlay {
        opacity: 1;
        visibility: visible;
      }
    }
  }
}
EOF
  echo "✅ dashboard.component.scss mis à jour."
else
  echo "⚠️ dashboard.component.scss semble déjà modifié."
fi

echo "🎉 Correctif terminé. N'oubliez pas de redémarrer 'ng serve'."