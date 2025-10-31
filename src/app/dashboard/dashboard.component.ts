import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../auth.service';
import { SelectedBoatService } from '../services/selected-boat.service';
import { Bateau } from '../models/bateau.model';
import { User } from '@angular/fire/auth';

@Component({
  standalone: false,
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.scss']
})
export class DashboardComponent implements OnInit {
  userEmail?: string;
  selectedBoat: Bateau | null = null;
  isSidebarOpen = false; // <-- DOIT ÊTRE PRÉSENT
  constructor(
    private authService: AuthService,
    private selectedBoatService: SelectedBoatService,
    private router: Router
  ) {}

  async ngOnInit(): Promise<void> {
    // ✅ CORRECTION: utiliser user$ au lieu de user
    this.authService.user$.subscribe((user: User | null) => {
      if (user) {
        this.userEmail = user.email || undefined;
      }
    });

    // Écouter les changements du bateau sélectionné
    this.selectedBoatService.selectedBoat$.subscribe((boat: Bateau | null) => {
      this.selectedBoat = boat;
    });
  }
  toggleSidebar(): void {
    this.isSidebarOpen = !this.isSidebarOpen;
  }
  goToBoatSelection(): void {
    this.router.navigate(['/dashboard/bateaux']);
  }

  async logout(): Promise<void> {
    try {
      await this.authService.logout();
    } catch (error) {
      console.error('Erreur logout', error);
    }
  }
}


