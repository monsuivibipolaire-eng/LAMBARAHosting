import { Component, OnInit } from '@angular/core';
import { LanguageService } from './services/language.service';

@Component({
  standalone: false,
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent implements OnInit {
  title = 'test';

  constructor(private languageService: LanguageService) {}

  ngOnInit(): void {
    // Initialiser la langue au démarrage de l'application
    this.languageService.initLanguage();
  }
}
