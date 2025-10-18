import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { RouterModule, Routes } from '@angular/router';
import { TranslateModule } from '@ngx-translate/core';

import { BateauxListComponent } from './bateaux-list.component';
import { BateauFormComponent } from './bateau-form.component';

const routes: Routes = [
  { path: '', component: BateauxListComponent },
  { path: 'add', component: BateauFormComponent },
  { path: 'edit/:id', component: BateauFormComponent }
];

@NgModule({
  declarations: [
    BateauxListComponent,
    BateauFormComponent
  ],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    FormsModule,
    RouterModule.forChild(routes),
    TranslateModule
  ]
})
export class BateauxModule { }
