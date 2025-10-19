import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { RouterModule, Routes } from '@angular/router';
import { TranslateModule } from '@ngx-translate/core';

// Composants NON-standalone
import { SortiesListComponent } from './sorties-list.component';
import { SortieFormComponent } from './sortie-form.component';
import { SortieDetailsComponent } from './sortie-details.component';

// Composants STANDALONE
import { DepenseFormComponent } from './depense-form/depense-form.component';
import { PointageComponent } from './pointage/pointage.component';

const routes: Routes = [
  { path: '', component: SortiesListComponent },
  { path: 'add', component: SortieFormComponent },
  { path: 'edit/:id', component: SortieFormComponent },
  { path: 'details/:id', component: SortieDetailsComponent },
  { path: 'details/:id/depenses/add', component: DepenseFormComponent },
  { path: 'details/:id/depenses/edit/:depenseId', component: DepenseFormComponent },
  { path: 'details/:id/pointage', component: PointageComponent }
];

@NgModule({
  declarations: [
    SortiesListComponent,
    SortieFormComponent,
    SortieDetailsComponent
  ],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    FormsModule,
    RouterModule.forChild(routes),
    TranslateModule,
    DepenseFormComponent,
    PointageComponent
  ]
})
export class SortiesModule {}
