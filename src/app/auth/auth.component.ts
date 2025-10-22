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
