import { Injectable } from '@angular/core';
import { CanActivate, Router, ActivatedRouteSnapshot, RouterStateSnapshot } from '@angular/router';
import { SelectedBoatService } from '../services/selected-boat.service';

@Injectable({
  providedIn: 'root'
})
export class BoatSelectionGuard implements CanActivate {
  constructor(
    private selectedBoatService: SelectedBoatService,
    private router: Router
  ) {}

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): boolean {
    if (this.selectedBoatService.hasSelectedBoat()) {
      return true;
    } else {
      // Rediriger vers la liste des bateaux pour sélectionner un bateau
      this.router.navigate(['/dashboard/bateaux']);
      return false;
    }
  }
}
