import { Component } from '@angular/core';
import { LanguageService } from '../../services/language.service';

@Component({
  standalone: false,
  selector: 'app-language-selector',
  templateUrl: './language-selector.component.html',
  styleUrls: ['./language-selector.component.scss']
})
export class LanguageSelectorComponent {
  languages = [
    { code: 'ar', name: 'العربية', flag: '🇹🇳' },
    { code: 'fr', name: 'Français', flag: '🇫🇷' },
    { code: 'en', name: 'English', flag: '🇬🇧' }
  ];

  isOpen = false;

  constructor(public languageService: LanguageService) {}

  getCurrentLanguage() {
    const currentLang = this.languageService.getCurrentLanguage();
    return this.languages.find(lang => lang.code === currentLang) || this.languages[0];
  }

  toggleDropdown(): void {
    this.isOpen = !this.isOpen;
  }

  selectLanguage(langCode: string): void {
    this.languageService.setLanguage(langCode);
    this.isOpen = false;
  }

  isCurrentLanguage(code: string): boolean {
    return code === this.languageService.getCurrentLanguage();
  }
}
