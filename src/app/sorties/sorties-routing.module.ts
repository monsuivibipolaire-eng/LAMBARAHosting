import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { SortiesListComponent } from './sorties-list.component';
import { SortieDetailsComponent } from './sortie-details.component';
import { PointageComponent } from './pointage/pointage.component';
import { FacturesComponent } from './factures/factures.component';

const routes: Routes = [
  { path: '', component: SortiesListComponent },
  { path: 'details/:id', component: SortieDetailsComponent },
  { path: 'pointage/:id', component: PointageComponent },
  { path: 'factures/:id', component: FacturesComponent }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class SortiesRoutingModule { }
