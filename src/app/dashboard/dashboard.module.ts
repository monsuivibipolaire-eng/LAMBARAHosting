import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DashboardRoutingModule } from './dashboard-routing.module';
import { TranslateModule } from '@ngx-translate/core';
import { DashboardComponent } from './dashboard.component';
import { DashboardHomeComponent } from './dashboard-home/dashboard-home.component';
import { LanguageSelectorComponent } from '../components/language-selector/language-selector.component';
import { MockDataComponent } from '../mock-data/mock-data.component';

@NgModule({
  declarations: [
    DashboardComponent,
    DashboardHomeComponent,
    LanguageSelectorComponent,
    MockDataComponent
  ],
  imports: [
    CommonModule,
    DashboardRoutingModule,
    TranslateModule
  ]
})
export class DashboardModule { }
