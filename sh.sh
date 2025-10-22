#!/bin/bash

# ==============================================================================
#  Script pour supprimer la fonctionnalité de création de compte (Sign Up).
# ==============================================================================

# --- Fichiers à modifier ---
AUTH_TS="src/app/auth/auth.component.ts"
AUTH_HTML="src/app/auth/auth.component.html"
AUTH_SERVICE="src/app/auth.service.ts"

# --- Vérification des fichiers ---
for file in $AUTH_TS $AUTH_HTML $AUTH_SERVICE; do
    if [ ! -f "$file" ]; then
        echo "❌ Erreur : Fichier manquant -> $file"
        echo "Veuillez exécuter ce script depuis la racine de votre projet."
        exit 1
    fi
done

echo "🔧 Début de la suppression de la fonctionnalité d'inscription..."

# --- 1. Remplacement du fichier TypeScript (auth.component.ts) ---
echo "🔄 1/3 - Simplification du composant d'authentification..."
cp "$AUTH_TS" "$AUTH_TS.bak"
cat > "$AUTH_TS" << 'EOF'
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../auth.service';
import { LanguageService } from '../services/language.service';
import { TranslateModule } from '@ngx-translate/core';

@Component({
  standalone: true,
  selector: 'app-auth',
  templateUrl: './auth.component.html',
  styleUrls: ['./auth.component.scss'],
  imports: [CommonModule, ReactiveFormsModule, TranslateModule]
})
export class AuthComponent implements OnInit {
  authForm!: FormGroup;
  loading = false;
  error: string = '';
  languageDropdownOpen = false;
  languages = [
    { code: 'ar', name: 'العربية', flag: '🇹🇳' },
    { code: 'fr', name: 'Français', flag: '🇫🇷' },
    { code: 'en', name: 'English', flag: '🇬🇧' }
  ];

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router,
    public languageService: LanguageService
  ) {}

  ngOnInit(): void {
    this.initForm();
  }

  initForm(): void {
    this.authForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]]
    });
  }

  async onSubmit(): Promise<void> {
    if (this.authForm.valid) {
      this.loading = true;
      this.error = '';
      const { email, password } = this.authForm.value;
      try {
        await this.authService.login(email, password);
        this.router.navigate(['/dashboard']);
      } catch (error: any) {
        this.error = error.message || 'Une erreur est survenue';
      } finally {
        this.loading = false;
      }
    }
  }

  toggleLanguageDropdown(): void {
    this.languageDropdownOpen = !this.languageDropdownOpen;
  }

  changeLanguage(langCode: string): void {
    this.languageService.setLanguage(langCode);
    this.languageDropdownOpen = false;
  }

  getCurrentLanguageFlag(): string {
    const currentLang = this.languageService.getCurrentLanguage();
    return this.languages.find(lang => lang.code === currentLang)?.flag || '🇹🇳';
  }

  getCurrentLanguageName(): string {
    const currentLang = this.languageService.getCurrentLanguage();
    return this.languages.find(lang => lang.code === currentLang)?.name || 'العربية';
  }

  isCurrentLanguage(code: string): boolean {
    return code === this.languageService.getCurrentLanguage();
  }
}
EOF

# --- 2. Remplacement du fichier HTML (auth.component.html) ---
echo "🔄 2/3 - Simplification du template HTML..."
cp "$AUTH_HTML" "$AUTH_HTML.bak"
cat > "$AUTH_HTML" << 'EOF'
<div class="auth-container">
  <div class="language-selector-top">
    <div class="language-dropdown" [class.open]="languageDropdownOpen">
      <button class="language-button" (click)="toggleLanguageDropdown()">
        <span class="flag">{{ getCurrentLanguageFlag() }}</span>
        <span class="lang-name">{{ getCurrentLanguageName() }}</span>
        <svg class="chevron" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>
      </button>
      <div class="dropdown-menu" *ngIf="languageDropdownOpen">
        <button *ngFor="let lang of languages" class="language-option" [class.active]="isCurrentLanguage(lang.code)" (click)="changeLanguage(lang.code)">
          <span class="flag">{{ lang.flag }}</span>
          <span class="lang-name">{{ lang.name }}</span>
          <svg *ngIf="isCurrentLanguage(lang.code)" class="check-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" /></svg>
        </button>
      </div>
    </div>
  </div>
  <div class="auth-box">
    <div class="auth-header">
      <h1 class="auth-title">{{ 'AUTH.WELCOME' | translate }}</h1>
      <p class="auth-subtitle">{{ 'AUTH.SIGN_IN' | translate }}</p>
    </div>
    <form [formGroup]="authForm" (ngSubmit)="onSubmit()" class="auth-form">
      <div class="form-group">
        <label class="form-label">{{ 'AUTH.EMAIL' | translate }}</label>
        <input type="email" formControlName="email" class="form-input" [placeholder]="'AUTH.EMAIL' | translate"/>
        <span class="error-message" *ngIf="authForm.get('email')?.hasError('required') && authForm.get('email')?.touched">{{ 'FORM.REQUIRED' | translate }}</span>
        <span class="error-message" *ngIf="authForm.get('email')?.hasError('email') && authForm.get('email')?.touched">{{ 'FORM.INVALID_EMAIL' | translate }}</span>
      </div>
      <div class="form-group">
        <label class="form-label">{{ 'AUTH.PASSWORD' | translate }}</label>
        <input type="password" formControlName="password" class="form-input" [placeholder]="'AUTH.PASSWORD' | translate"/>
        <span class="error-message" *ngIf="authForm.get('password')?.hasError('required') && authForm.get('password')?.touched">{{ 'FORM.REQUIRED' | translate }}</span>
      </div>
      <button type="submit" class="auth-button" [disabled]="!authForm.valid || loading">
        <span *ngIf="!loading">{{ 'AUTH.LOGIN' | translate }}</span>
        <span *ngIf="loading">{{ 'MESSAGES.LOADING' | translate }}</span>
      </button>
      <div class="auth-error" *ngIf="error">{{ error }}</div>
    </form>
  </div>
</div>
EOF

# --- 3. Remplacement du service d'authentification (auth.service.ts) ---
echo "🔄 3/3 - Nettoyage du service d'authentification..."
cp "$AUTH_SERVICE" "$AUTH_SERVICE.bak"
cat > "$AUTH_SERVICE" << 'EOF'
import { Injectable } from '@angular/core';
import { Auth, signInWithEmailAndPassword, signOut, authState, User } from '@angular/fire/auth';
import { Router } from '@angular/router';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  user$: Observable<User | null>;

  constructor(private auth: Auth, private router: Router) {
    this.user$ = authState(this.auth);
  }

  async login(email: string, password: string): Promise<void> {
    try {
      await signInWithEmailAndPassword(this.auth, email, password);
      this.router.navigate(['/dashboard']);
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    }
  }

  async logout(): Promise<void> {
    try {
      await signOut(this.auth);
      this.router.navigate(['/auth']);
    } catch (error) {
      console.error('Logout error:', error);
      throw error;
    }
  }

  get isLoggedIn(): boolean {
    return this.auth.currentUser !== null;
  }

  get currentUser(): User | null {
    return this.auth.currentUser;
  }
}
EOF

# --- Nettoyage et confirmation ---
rm -f "$AUTH_TS.bak" "$AUTH_HTML.bak" "$AUTH_SERVICE.bak"
echo "✅ Modifications terminées avec succès !"
echo "La page d'authentification ne propose désormais plus que la connexion."