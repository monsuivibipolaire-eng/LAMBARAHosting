import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { CommonModule } from '@angular/common';
import { TranslateModule } from '@ngx-translate/core';

import { DashboardComponent } from './dashboard.component';
import { DashboardHomeComponent } from './dashboard-home/dashboard-home.component';
import { BoatSelectionGuard } from '../guards/boat-selection.guard';
import { MockDataComponent } from '../mock-data/mock-data.component';

const routes: Routes = [
  {
    path: '',
    component: DashboardComponent,
    children: [
      { path: '', component: DashboardHomeComponent },
      {
        path: 'bateaux',
        loadChildren: () => import('../bateaux/bateaux.module').then(m => m.BateauxModule)
      },
      {
        path: 'sorties',
        loadChildren: () => import('../sorties/sorties.module').then(m => m.SortiesModule),
        canActivate: [BoatSelectionGuard]
      },
      {
        path: 'ventes',
        loadComponent: () => import('../ventes/ventes-list.component').then(m => m.VentesListComponent),
        canActivate: [BoatSelectionGuard]
      },
      {
        path: 'avances',
        loadComponent: () => import('../avances/avances.component').then(m => m.AvancesComponent),
        canActivate: [BoatSelectionGuard]
      },
      {
        path: 'salaires',
        loadComponent: () => import('../salaires/salaires-list.component').then(m => m.SalairesListComponent),
        canActivate: [BoatSelectionGuard]
      },
      { path: 'mock-data', component: MockDataComponent },

      { path: '', redirectTo: '', pathMatch: 'full' }
    ]
  }
];

@NgModule({
  imports: [
    CommonModule,
    RouterModule.forChild(routes),
    TranslateModule
  ],
  exports: [RouterModule]
})
export class DashboardRoutingModule { }
