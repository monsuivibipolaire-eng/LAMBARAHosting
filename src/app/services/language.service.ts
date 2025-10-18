import { Injectable } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';

@Injectable({
  providedIn: 'root'
})
export class LanguageService {
  private readonly STORAGE_KEY = 'app_language';
  private readonly DEFAULT_LANGUAGE = 'ar';

  constructor(private translate: TranslateService) {}

  initLanguage(): void {
    const savedLang = localStorage.getItem(this.STORAGE_KEY) || this.DEFAULT_LANGUAGE;
    this.setLanguage(savedLang);
  }

  setLanguage(langCode: string): void {
    this.translate.use(langCode);
    localStorage.setItem(this.STORAGE_KEY, langCode);
    
    // Appliquer direction RTL/LTR sur le body
    const isRTL = langCode === 'ar';
    document.body.classList.toggle('rtl', isRTL);
    document.body.classList.toggle('ltr', !isRTL);
    document.body.setAttribute('dir', isRTL ? 'rtl' : 'ltr');
    
    // Appliquer sur html aussi pour compatibilité totale
    document.documentElement.setAttribute('dir', isRTL ? 'rtl' : 'ltr');
    document.documentElement.setAttribute('lang', langCode);
  }

  getCurrentLanguage(): string {
    return this.translate.currentLang || localStorage.getItem(this.STORAGE_KEY) || this.DEFAULT_LANGUAGE;
  }

  isRTL(): boolean {
    return this.getCurrentLanguage() === 'ar';
  }
}
