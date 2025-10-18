import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { RouterModule, Routes } from '@angular/router';
import { TranslateModule } from '@ngx-translate/core';

import { MarinsListComponent } from './marins-list.component';
import { MarinFormComponent } from './marin-form.component';

const routes: Routes = [
  { path: '', component: MarinsListComponent },
  { path: 'add', component: MarinFormComponent },
  { path: 'edit/:id', component: MarinFormComponent }
];

@NgModule({
  declarations: [
    MarinsListComponent,
    MarinFormComponent
  ],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    FormsModule,
    RouterModule.forChild(routes),
    TranslateModule
  ]
})
export class MarinsModule { }
