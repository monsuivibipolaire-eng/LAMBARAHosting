#!/bin/bash

# ==============================================================================
#  Script pour ajouter un bouton de déconnexion au tableau de bord.
# ==============================================================================

# --- Fichiers à modifier ---
DASH_HTML="src/app/dashboard/dashboard.component.html"
DASH_SCSS="src/app/dashboard/dashboard.component.scss"
I18N_AR="src/assets/i18n/ar.json"
I18N_EN="src/assets/i18n/en.json"
I18N_FR="src/assets/i18n/fr.json"

# --- Vérification des fichiers ---
for file in $DASH_HTML $DASH_SCSS $I18N_AR $I18N_EN $I18N_FR; do
    if [ ! -f "$file" ]; then
        echo "❌ Erreur : Fichier manquant -> $file"
        echo "Veuillez exécuter ce script depuis la racine de votre projet."
        exit 1
    fi
done

echo "🔧 Début de l'ajout du bouton de déconnexion..."

# --- 1. Remplacement du fichier HTML (dashboard.component.html) ---
echo "🔄 1/3 - Mise à jour du template HTML du tableau de bord..."
cp "$DASH_HTML" "$DASH_HTML.bak"
cat > "$DASH_HTML" << 'EOF'
<div class="dashboard-layout">
  <aside class="sidebar">
    <div class="logo">
      <h2>LAMBARA</h2>
    </div>
    <nav class="sidebar-nav">
      <ul>
        <li>
          <a routerLink="/dashboard" routerLinkActive="active" [routerLinkActiveOptions]="{exact: true}" class="nav-item">
            <svg class="nav-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
            </svg>
            <span>{{ 'MENU.HOME' | translate }}</span>
          </a>
        </li>
        <li>
          <a routerLink="/dashboard/bateaux" routerLinkActive="active" class="nav-item">
            <svg class="nav-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z"/>
            </svg>
            <span>{{ 'MENU.BOATS' | translate }}</span>
          </a>
        </li>
        <li *ngIf="selectedBoat">
          <a [routerLink]="['/dashboard/bateaux', selectedBoat.id, 'marins']" routerLinkActive="active" class="nav-item">
            <svg class="nav-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
            <span>{{ 'MENU.SAILORS' | translate }}</span>
          </a>
        </li>
        <li *ngIf="selectedBoat">
          <a routerLink="/dashboard/sorties" routerLinkActive="active" class="nav-item">
            <svg class="nav-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
            </svg>
            <span>{{ 'MENU.SORTIES' | translate }}</span>
          </a>
        </li>
        <li *ngIf="selectedBoat">
          <a routerLink="/dashboard/ventes" routerLinkActive="active" class="nav-item">
            <svg class="nav-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
            </svg>
            <span>{{ 'MENU.VENTES' | translate }}</span>
          </a>
        </li>
        <li *ngIf="selectedBoat">
          <a routerLink="/dashboard/avances" routerLinkActive="active" class="nav-item">
            <svg class="nav-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <span>{{ 'MENU.AVANCES' | translate }}</span>
          </a>
        </li>
        <li *ngIf="selectedBoat">
          <a routerLink="/dashboard/salaires" routerLinkActive="active" class="nav-item">
            <svg class="nav-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"/>
            </svg>
            <span>{{ 'MENU.SALAIRES' | translate }}</span>
          </a>
        </li>
        <li>
          <a routerLink="/dashboard/mock-data" routerLinkActive="active" class="nav-item">
            <svg class="nav-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4"/>
            </svg>
            <span>🎲 {{ 'MENU.MOCK_DATA' | translate }}</span>
          </a>
        </li>
      </ul>
    </nav>
  </aside>

  <main class="main-content">
    <header class="header">
      <div class="boat-selector">
        <div *ngIf="selectedBoat" class="selected-boat-badge" (click)="goToBoatSelection()">
          <svg class="boat-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
          <div class="boat-info">
            <span class="boat-label">{{ 'BOATS.SELECTED_BOAT' | translate }}</span>
            <span class="boat-name">{{ selectedBoat.nom }}</span>
            <span class="boat-registration">({{ selectedBoat.immatriculation }})</span>
          </div>
          <svg class="change-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"/>
          </svg>
        </div>
        <div *ngIf="!selectedBoat" class="no-boat-badge" (click)="goToBoatSelection()">
          <svg class="warning-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
          </svg>
          <div class="no-boat-info">
            <span class="no-boat-label">{{ 'BOATS.NO_BOAT_SELECTED' | translate }}</span>
            <span class="no-boat-action">{{ 'BOATS.CLICK_TO_SELECT' | translate }}</span>
          </div>
        </div>
      </div>
      
      <div class="header-right">
        <div class="user-info" *ngIf="userEmail">
          <svg class="user-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
          <span>{{ userEmail }}</span>
        </div>
        <app-language-selector></app-language-selector>
        <button class="btn-logout" (click)="logout()" [title]="'MENU.LOGOUT' | translate">
          <svg fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" /></svg>
        </button>
      </div>
    </header>

    <div class="content">
      <router-outlet></router-outlet>
    </div>
  </main>
</div>
EOF

# --- 2. Remplacement du fichier SCSS (dashboard.component.scss) ---
echo "🔄 2/3 - Ajout des styles pour les nouveaux éléments..."
cp "$DASH_SCSS" "$DASH_SCSS.bak"
cat > "$DASH_SCSS" << 'EOF'
.dashboard-layout {
  display: flex;
  min-height: 100vh;
  background-color: #f5f7fa;
}

.sidebar {
  width: 260px;
  background: linear-gradient(180deg, #1e3a8a 0%, #1e40af 100%);
  color: white;
  position: fixed;
  height: 100vh;
  left: 0;
  top: 0;
  box-shadow: 2px 0 8px rgba(0, 0, 0, 0.1);
  z-index: 1000;
  transition: all 0.3s ease;
  overflow-y: auto;
}

.logo {
  padding: 1.5rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  h2 {
    margin: 0;
    font-size: 1.5rem;
    font-weight: 700;
  }
}

.sidebar-nav {
  padding: 1rem 0;
  ul {
    list-style: none;
    padding: 0;
    margin: 0;
  }

  li {
    margin: 0.25rem 0;
  }

  .nav-item {
    display: flex;
    align-items: center;
    padding: 0.875rem 1.5rem;
    color: rgba(255, 255, 255, 0.8);
    text-decoration: none;
    transition: all 0.3s ease;
    border-left: 3px solid transparent;
    &:hover {
      background-color: rgba(255, 255, 255, 0.1);
      color: white;
    }

    &.active {
      background-color: rgba(255, 255, 255, 0.15);
      border-left-color: #60a5fa;
      color: white;
      font-weight: 600;
    }

    span {
      margin-left: 0.75rem;
      font-weight: 500;
    }
  }

  .nav-icon {
    width: 20px;
    height: 20px;
    flex-shrink: 0;
  }
}

.main-content {
  margin-left: 260px;
  flex: 1;
  display: flex;
  flex-direction: column;
  width: calc(100% - 260px);
  min-width: 0;
  transition: margin 0.3s ease;
}

.header {
  background: white;
  padding: 1rem 2rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1.5rem;
  position: sticky;
  top: 0;
  z-index: 900;
}

.boat-selector {
  flex: 1;
}

.selected-boat-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.75rem;
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  color: white;
  padding: 0.75rem 1.25rem;
  border-radius: 0.75rem;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(16, 185, 129, 0.2);

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(16, 185, 129, 0.3);
  }

  .boat-icon {
    width: 24px;
    height: 24px;
    flex-shrink: 0;
  }

  .boat-info {
    display: flex;
    flex-direction: column;
    gap: 0.125rem;
    .boat-label {
      font-size: 0.75rem;
      opacity: 0.9;
      font-weight: 500;
    }

    .boat-name {
      font-size: 1rem;
      font-weight: 700;
    }

    .boat-registration {
      font-size: 0.875rem;
      opacity: 0.9;
    }
  }

  .change-icon {
    width: 20px;
    height: 20px;
    flex-shrink: 0;
    margin-left: auto;
    opacity: 0.8;
  }
}

.no-boat-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.75rem;
  background: #fee2e2;
  color: #991b1b;
  padding: 0.75rem 1.25rem;
  border-radius: 0.75rem;
  border: 2px solid #ef4444;
  cursor: pointer;
  transition: all 0.3s ease;
  animation: pulse 2s ease-in-out infinite;
  &:hover {
    background: #fecaca;
    transform: scale(1.02);
  }

  .warning-icon {
    width: 24px;
    height: 24px;
    flex-shrink: 0;
    animation: shake 1s ease-in-out infinite;
  }

  .no-boat-info {
    display: flex;
    flex-direction: column;
    gap: 0.125rem;
    .no-boat-label {
      font-size: 0.875rem;
      font-weight: 700;
    }

    .no-boat-action {
      font-size: 0.75rem;
      opacity: 0.8;
    }
  }
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.85; }
}

@keyframes shake {
  0%, 100% { transform: rotate(0deg); }
  25% { transform: rotate(-5deg); }
  75% { transform: rotate(5deg); }
}

.content {
  padding: 2rem;
  flex: 1;
  width: 100%;
  overflow-x: hidden;
}

// ✅ NOUVEAUX STYLES AJOUTÉS
.header-right {
  display: flex;
  align-items: center;
  gap: 1.5rem;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: #4b5563;
  font-weight: 500;
  font-size: 0.875rem;
  
  .user-icon {
    width: 20px;
    height: 20px;
    color: #9ca3af;
  }
}

.btn-logout {
  background: none;
  border: none;
  color: #6b7280;
  cursor: pointer;
  padding: 0.5rem;
  border-radius: 9999px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;

  svg {
    width: 24px;
    height: 24px;
  }
  
  &:hover {
    background-color: #fee2e2;
    color: #ef4444;
  }
}
// FIN DES NOUVEAUX STYLES

@media (max-width: 1024px) {
  .sidebar { width: 220px; }
  .main-content { margin-left: 220px; width: calc(100% - 220px); }
  .content { padding: 1.5rem; }
  .boat-info .boat-name { font-size: 0.9rem; }
  .boat-info .boat-registration { font-size: 0.8rem; }
  .user-info span { display: none; } // Cache l'email sur les écrans moyens
}

@media (max-width: 768px) {
  .sidebar { transform: translateX(-100%); width: 260px; }
  .main-content { margin-left: 0; width: 100%; }
  .header { padding: 0.75rem 1rem; flex-wrap: wrap; }
  .boat-selector { width: 100%; order: 2; margin-top: 0.75rem; }
  .header-right { order: 1; width: 100%; justify-content: flex-end; }
  .selected-boat-badge, .no-boat-badge { width: 100%; justify-content: flex-start; }
  .content { padding: 1rem; }
}

@media (max-width: 480px) {
  .content { padding: 0.75rem; }
  .selected-boat-badge, .no-boat-badge { padding: 0.625rem 1rem; }
  .boat-info .boat-name { font-size: 0.875rem; }
  .boat-info .boat-registration { font-size: 0.75rem; }
  .no-boat-info .no-boat-label { font-size: 0.8125rem; }
  .no-boat-info .no-boat-action { font-size: 0.6875rem; }
}

body.rtl, :host-context(.rtl) {
  .sidebar { left: auto; right: 0; box-shadow: -2px 0 8px rgba(0, 0, 0, 0.1); }
  .nav-item { border-left: none; border-right: 3px solid transparent;
    &.active { border-right-color: #60a5fa; }
    span { margin-left: 0; margin-right: 0.75rem; }
  }
  .main-content { margin-left: 0; margin-right: 260px; }

  @media (max-width: 1024px) {
    .main-content { margin-right: 220px; }
  }

  @media (max-width: 768px) {
    .sidebar { transform: translateX(100%); }
    .main-content { margin-right: 0; }
  }
}

.menu-disabled {
  position: relative;
  .nav-item-disabled {
    display: flex;
    align-items: center;
    padding: 0.875rem 1.5rem;
    color: rgba(255, 255, 255, 0.4);
    cursor: not-allowed;
    position: relative;
    span { margin-left: 0.75rem; font-weight: 500; }
  }
  .tooltip-disabled {
    position: absolute;
    left: 100%;
    top: 50%;
    transform: translateY(-50%);
    background: #1f2937;
    color: white;
    padding: 0.5rem 0.75rem;
    border-radius: 0.375rem;
    font-size: 0.875rem;
    white-space: nowrap;
    margin-left: 0.5rem;
    opacity: 0;
    visibility: hidden;
    transition: all 0.3s ease;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.3);
    z-index: 1001;
    pointer-events: none;
    &::before {
      content: '';
      position: absolute;
      right: 100%;
      top: 50%;
      transform: translateY(-50%);
      border: 6px solid transparent;
      border-right-color: #1f2937;
    }
  }
  &:hover .tooltip-disabled {
    opacity: 1;
    visibility: visible;
  }
}

body.rtl, :host-context(.rtl) {
  .menu-disabled {
    .nav-item-disabled {
      span { margin-left: 0; margin-right: 0.75rem; }
    }
    .tooltip-disabled {
      left: auto;
      right: 100%;
      margin-left: 0;
      margin-right: 0.5rem;
      &::before {
        right: auto;
        left: 100%;
        border-right-color: transparent;
        border-left-color: #1f2937;
      }
    }
  }
}

@media (max-width: 768px) {
  .menu-disabled .tooltip-disabled {
    position: fixed; left: 50%; right: auto; top: auto; bottom: 20px; transform: translateX(-50%); margin-left: 0;
    &::before { display: none; }
  }
}
EOF

# --- 3. Ajout des clés de traduction ---
echo "🔄 3/3 - Ajout des clés de traduction..."
# fr.json
sed -i'' '/"HOME": "Accueil",/a \
    "LOGOUT": "Déconnexion",' "$I18N_FR"
# en.json
sed -i'' '/"HOME": "Home",/a \
    "LOGOUT": "Logout",' "$I18N_EN"
# ar.json
sed -i'' '/"HOME": "الرئيسية",/a \
    "LOGOUT": "تسجيل الخروج",' "$I18N_AR"


# --- Nettoyage et confirmation ---
rm -f "$DASH_HTML.bak" "$DASH_SCSS.bak"
echo "✅ Modifications terminées avec succès !"
echo "Un bouton de déconnexion a été ajouté à l'en-tête du tableau de bord."