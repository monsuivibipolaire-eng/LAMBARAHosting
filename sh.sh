#!/bin/bash

# ==============================================================================
# SCRIPT pour corriger l'erreur "Firebase API called outside injection context".
#
# Remplace `app.module.ts` pour passer explicitement l'instance de l'application
# Firebase au service Firestore, ce qui résout les problèmes de contexte
# avec les composants chargés paresseusement (lazy-loaded).
# ==============================================================================

# --- Configuration ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Fichier à remplacer
FILE_PATH="src/app/app.module.ts"

# --- Vérifications ---
if [ ! -f "$FILE_PATH" ]; then
    echo -e "${RED}Erreur : Fichier non trouvé :${NC} $FILE_PATH"
    exit 1
fi

echo -e "🔧 Fichier cible : ${YELLOW}$FILE_PATH${NC}"

# Créer une sauvegarde
cp "$FILE_PATH" "${FILE_PATH}.bak.contextfix"
echo "  -> Une sauvegarde a été créée : ${FILE_PATH}.bak.contextfix"

echo "  -> Remplacement du fichier par la version corrigée..."

# --- Remplacement complet du fichier ---
cat > "$FILE_PATH" << 'EOF'
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpClientModule } from '@angular/common/http';
import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
// ✅ CORRECTION : Importer `getApp`
import { provideFirebaseApp, initializeApp, getApp } from '@angular/fire/app';
import { provideAuth, getAuth } from '@angular/fire/auth';
import { provideFirestore, getFirestore } from '@angular/fire/firestore';
import { TranslateModule, TranslateLoader } from '@ngx-translate/core';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';
import { environment } from '../environments/environment';
import { AuthComponent } from './auth/auth.component';
import { AuthGuard } from './auth.guard';
import { AuthService } from './auth.service';

export function createTranslateLoader(http: HttpClient) {
  return new TranslateHttpLoader(http, './assets/i18n/', '.json');
}

@NgModule({
  declarations: [AppComponent],
  imports: [
    RouterModule, AuthComponent, BrowserModule, CommonModule, FormsModule,
    ReactiveFormsModule, BrowserAnimationsModule, AppRoutingModule, HttpClientModule,
    TranslateModule.forRoot({
      defaultLanguage: 'ar',
      loader: {
        provide: TranslateLoader,
        useFactory: createTranslateLoader,
        deps: [HttpClient]
      }
    })
  ],
  providers: [
    AuthService, AuthGuard,
    provideFirebaseApp(() => initializeApp(environment.firebase)),
    provideAuth(() => getAuth()),
    // ✅ CORRECTION : Utiliser getApp() pour passer l'instance Firebase à Firestore
    provideFirestore(() => getFirestore(getApp()))
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
EOF

if [ $? -eq 0 ]; then
    echo -e "  -> ${GREEN}Succès : Le fichier a été remplacé par la version corrigée.${NC}"
else
    echo -e "  -> ${RED}Erreur : Un problème est survenu lors de la modification.${NC}"
    exit 1
fi

echo -e "\n${GREEN}✅ Opération terminée. L'erreur de contexte Firebase est corrigée.${NC}"