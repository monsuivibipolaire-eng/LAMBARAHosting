import{b as G,c as R}from"./chunk-Z7HEBSRN.js";import"./chunk-5SMMQZVJ.js";import{a as $}from"./chunk-E7ROQ3IM.js";import{a as J,b as q}from"./chunk-IKMWHSPF.js";import{$ as y,$b as z,Ab as m,Bb as P,Ia as C,Na as B,Ra as M,Xb as D,Yb as L,aa as E,ab as f,ac as j,ba as x,bb as a,ca as O,cb as i,db as _,e as U,eb as I,f as S,fb as k,gb as g,gc as N,hc as A,ic as H,nb as s,ob as v,pb as u,qb as F,u as V,ya as r,zb as d}from"./chunk-S7C4YWPX.js";var b=U(J());function K(o,t){if(o&1){let e=I();a(0,"button",7),k("click",function(){y(e);let l=g();return E(l.ajouterFactureGlobale())}),x(),a(1,"svg",8),_(2,"path",9),i(),s(3),d(4,"translate"),i()}o&2&&(r(3),u(" ",m(4,1,"VENTES.ADD_INVOICE")," "))}function Q(o,t){o&1&&(a(0,"div",10),_(1,"div",11),a(2,"p"),s(3),d(4,"translate"),i()()),o&2&&(r(3),v(m(4,1,"MESSAGES.LOADING")))}function X(o,t){o&1&&(a(0,"div",12),x(),a(1,"svg",13),_(2,"path",14),i(),O(),a(3,"p"),s(4),d(5,"translate"),i()()),o&2&&(r(4),v(m(5,1,"BOATS.NO_BOAT_SELECTED")))}function Z(o,t){o&1&&(a(0,"div",12),x(),a(1,"svg",13),_(2,"path",22),i(),O(),a(3,"p"),s(4),d(5,"translate"),i()()),o&2&&(r(4),v(m(5,1,"VENTES.NO_TRIPS_AVAILABLE")))}function ee(o,t){o&1&&(a(0,"div",35)(1,"p"),s(2),d(3,"translate"),i()()),o&2&&(r(2),v(m(3,1,"VENTES.NO_INVOICES_FOR_TRIP")))}function te(o,t){if(o&1&&(a(0,"p",49)(1,"strong"),s(2),d(3,"translate"),i(),s(4),i()),o&2){let e=g().$implicit;r(2),u("",m(3,2,"COMMON.DETAILS"),":"),r(2),u(" ",e.details)}}function ne(o,t){if(o&1){let e=I();a(0,"div",38)(1,"div",39)(2,"span",40),s(3),i(),a(4,"span",41),s(5),d(6,"number"),i()(),a(7,"div",42)(8,"p")(9,"strong"),s(10),d(11,"translate"),i(),s(12),i(),a(13,"p")(14,"strong"),s(15),d(16,"translate"),i(),s(17),i(),M(18,te,5,4,"p",43),i(),a(19,"div",44)(20,"button",45),k("click",function(){let l=y(e).$implicit,c=g(5);return E(c.modifierFacture(l))}),x(),a(21,"svg",8),_(22,"path",46),i(),s(23),d(24,"translate"),i(),O(),a(25,"button",47),k("click",function(){let l=y(e).$implicit,c=g(5);return E(c.supprimerFacture(l))}),x(),a(26,"svg",8),_(27,"path",48),i(),s(28),d(29,"translate"),i()()()}if(o&2){let e=t.$implicit,n=g(5);r(3),v(e.numeroFacture),r(2),u("",P(6,9,e.montant,"1.2-2")," DT"),r(5),u("",m(11,12,"VENTES.DETAILS_MODAL.CLIENT"),":"),r(2),u(" ",e.client),r(3),u("",m(16,14,"COMMON.DATE"),":"),r(2),u(" ",n.formatDisplayDate(e.dateVente)),r(),f("ngIf",e.details),r(5),u(" ",m(24,16,"FORM.EDIT")," "),r(5),u(" ",m(29,18,"FORM.DELETE")," ")}}function ie(o,t){if(o&1&&(a(0,"div",36),M(1,ne,30,20,"div",37),i()),o&2){let e=g().$implicit;r(),f("ngForOf",e.factures)}}function re(o,t){if(o&1){let e=I();a(0,"div",25)(1,"div",26)(2,"div",27)(3,"h2"),s(4),i(),a(5,"p",28),s(6),i()(),a(7,"div",29)(8,"span",30),s(9),d(10,"translate"),i(),a(11,"span",31),s(12),d(13,"number"),i()(),a(14,"button",32),k("click",function(){let l=y(e).$implicit,c=g(3);return E(c.ajouterFacture(l.sortie))}),x(),a(15,"svg",8),_(16,"path",9),i(),s(17),d(18,"translate"),i()(),M(19,ee,4,3,"div",33)(20,ie,2,1,"div",34),i()}if(o&2){let e=t.$implicit,n=g(3);r(4),v(e.sortie.destination),r(2),F("",n.formatDisplayDate(e.sortie.dateDepart)," - ",n.formatDisplayDate(e.sortie.dateRetour)),r(3),v(m(10,8,"VENTES.TRIP_TOTAL")),r(3),u("",P(13,10,e.totalVentes,"1.2-2")," DT"),r(5),u(" ",m(18,13,"FORM.ADD")," "),r(2),f("ngIf",e.factures.length===0),r(),f("ngIf",e.factures.length>0)}}function ae(o,t){if(o&1&&(a(0,"div",23),M(1,re,21,15,"div",24),i()),o&2){let e=g(2);r(),f("ngForOf",e.sortiesWithFactures)}}function oe(o,t){if(o&1&&(a(0,"div",15)(1,"div",16)(2,"div",17),x(),a(3,"svg",8),_(4,"path",18),i()(),O(),a(5,"div",19)(6,"h3"),s(7),d(8,"translate"),i(),a(9,"p",20),s(10),d(11,"number"),i()()(),M(12,Z,6,3,"div",5)(13,ae,2,1,"div",21),i()),o&2){let e=g();r(7),v(m(8,4,"VENTES.GENERAL_TOTAL")),r(3),u("",P(11,6,e.getTotalGeneral(),"1.2-2")," DT"),r(2),f("ngIf",e.sortiesWithFactures.length===0),r(),f("ngIf",e.sortiesWithFactures.length>0)}}var w=class w{constructor(t,e,n,l,c){this.sortieService=t;this.factureService=e;this.selectedBoatService=n;this.alertService=l;this.translate=c;this.selectedBoat=null;this.sortiesWithFactures=[];this.loading=!0}ngOnInit(){this.selectedBoat=this.selectedBoatService.getSelectedBoat(),this.selectedBoat?this.loadData():this.loading=!1}loadData(){this.selectedBoat&&this.sortieService.getSortiesByBateau(this.selectedBoat.id).subscribe(t=>{let e=t.map(n=>this.factureService.getFacturesBySortie(n.id));V(e).subscribe(n=>{this.sortiesWithFactures=t.map((l,c)=>{let p=n[c],h=p.reduce((T,Y)=>T+Y.montant,0);return{sortie:l,factures:p,totalVentes:h}}),this.loading=!1})})}getTotalGeneral(){return this.sortiesWithFactures.reduce((t,e)=>t+e.totalVentes,0)}ajouterFactureGlobale(){return S(this,null,function*(){if(this.sortiesWithFactures.length===0){this.alertService.error("Aucune sortie en mer disponible");return}let t=this.sortiesWithFactures.reduce((n,l)=>{let c=this.formatDisplayDate(l.sortie.dateDepart),p=this.formatDisplayDate(l.sortie.dateRetour);return n[l.sortie.id]=`${l.sortie.destination} (${c} - ${p})`,n},{}),{value:e}=yield b.default.fire({title:`<div style="text-align: center;">
                <div style="font-size: 1.5rem; font-weight: 700; color: #1f2937; margin-bottom: 0.5rem;">
                  Nouvelle facture de vente
                </div>
              </div>`,html:`
        <style>
          .facture-form {
            text-align: left;
            padding: 1rem 0;
          }
          .form-group {
            margin-bottom: 1.25rem;
          }
          .form-label {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            margin-bottom: 0.625rem;
            font-weight: 600;
            color: #374151;
            font-size: 0.9rem;
          }
          .form-label svg {
            width: 18px;
            height: 18px;
            color: #10b981;
          }
          .required-star {
            color: #ef4444;
            font-weight: 700;
          }
          .custom-input, .custom-textarea, .custom-select {
            width: 100%;
            padding: 0.75rem 0.875rem;
            border: 2px solid #e5e7eb;
            border-radius: 0.5rem;
            font-size: 0.95rem;
            transition: all 0.3s;
            font-family: inherit;
            background: white;
          }
          .custom-input:focus, .custom-textarea:focus, .custom-select:focus {
            outline: none;
            border-color: #10b981;
            box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1);
          }
          .custom-textarea {
            resize: vertical;
            min-height: 80px;
          }
          .input-helper {
            display: flex;
            align-items: center;
            gap: 0.4rem;
            margin-top: 0.4rem;
            font-size: 0.8rem;
            color: #6b7280;
          }
        </style>
        <div class="facture-form">
          <!-- \u2705 S\xC9LECTION DE SORTIE -->
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
              </svg>
              Sortie en mer <span class="required-star">*</span>
            </label>
            <select id="swal-sortie" class="custom-select">
              <option value="">S\xE9lectionner une sortie</option>
              ${Object.keys(t).map(n=>`<option value="${n}">${t[n]}</option>`).join("")}
            </select>
          </div>

          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14"/>
              </svg>
              N\xB0 Facture <span class="required-star">*</span>
            </label>
            <input id="swal-numero" type="text" class="custom-input" placeholder="Ex: F-001" autocomplete="off">
            <div class="input-helper">Num\xE9ro unique de la facture</div>
          </div>
          
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
              </svg>
              Client <span class="required-star">*</span>
            </label>
            <input id="swal-client" type="text" class="custom-input" placeholder="Nom du client" autocomplete="off">
          </div>
          
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
              </svg>
              Date de vente <span class="required-star">*</span>
            </label>
            <input id="swal-date" type="date" class="custom-input" value="${this.getTodayDate()}">
          </div>
          
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              Montant total (DT) <span class="required-star">*</span>
            </label>
            <input id="swal-montant" type="number" class="custom-input" placeholder="0.00" step="0.01" min="0" autocomplete="off">
            <div class="input-helper">Montant en dinars tunisiens</div>
          </div>
          
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z"/>
              </svg>
              D\xE9tails (poissons vendus)
            </label>
            <textarea id="swal-details" class="custom-textarea" placeholder="Ex: 50 kg de dorade, 30 kg de loup, 20 kg de rouget..."></textarea>
          </div>
        </div>
      `,focusConfirm:!1,showCancelButton:!0,confirmButtonText:"Ajouter la facture",cancelButtonText:"Annuler",confirmButtonColor:"#10b981",cancelButtonColor:"#6b7280",width:"650px",preConfirm:()=>{let n=document.getElementById("swal-sortie").value,l=document.getElementById("swal-numero").value.trim(),c=document.getElementById("swal-client").value.trim(),p=document.getElementById("swal-date").value,h=parseFloat(document.getElementById("swal-montant").value),T=document.getElementById("swal-details").value.trim();return n?!l||!c||!p||!h?(b.default.showValidationMessage("Veuillez remplir tous les champs obligatoires"),!1):h<=0?(b.default.showValidationMessage("Le montant doit \xEAtre sup\xE9rieur \xE0 0"),!1):{sortieId:n,numero:l,client:c,date:p,montant:h,details:T}:(b.default.showValidationMessage("Veuillez s\xE9lectionner une sortie en mer"),!1)}});if(e)try{this.alertService.loading("Ajout de la facture...");let n={sortieId:e.sortieId,numeroFacture:e.numero,client:e.client,dateVente:new Date(e.date),montant:e.montant,details:e.details||void 0};yield this.factureService.addFacture(n),this.alertService.close(),this.alertService.success("Facture ajout\xE9e avec succ\xE8s!")}catch(n){console.error("Erreur:",n),this.alertService.close(),this.alertService.error("Erreur lors de l'ajout")}})}ajouterFacture(t){return S(this,null,function*(){let{value:e}=yield b.default.fire({title:`<div style="text-align: center;">
                <div style="font-size: 1.5rem; font-weight: 700; color: #1f2937; margin-bottom: 0.5rem;">
                  Nouvelle facture de vente
                </div>
                <div style="font-size: 0.875rem; color: #6b7280;">
                  ${t.destination}
                </div>
              </div>`,html:`
        <style>
          .facture-form {
            text-align: left;
            padding: 1rem 0;
          }
          .form-group {
            margin-bottom: 1.25rem;
          }
          .form-label {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            margin-bottom: 0.625rem;
            font-weight: 600;
            color: #374151;
            font-size: 0.9rem;
          }
          .form-label svg {
            width: 18px;
            height: 18px;
            color: #10b981;
          }
          .required-star {
            color: #ef4444;
            font-weight: 700;
          }
          .custom-input, .custom-textarea {
            width: 100%;
            padding: 0.75rem 0.875rem;
            border: 2px solid #e5e7eb;
            border-radius: 0.5rem;
            font-size: 0.95rem;
            transition: all 0.3s;
            font-family: inherit;
          }
          .custom-input:focus, .custom-textarea:focus {
            outline: none;
            border-color: #10b981;
            box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1);
          }
          .custom-textarea {
            resize: vertical;
            min-height: 80px;
          }
          .input-helper {
            display: flex;
            align-items: center;
            gap: 0.4rem;
            margin-top: 0.4rem;
            font-size: 0.8rem;
            color: #6b7280;
          }
        </style>
        <div class="facture-form">
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14"/>
              </svg>
              N\xB0 Facture <span class="required-star">*</span>
            </label>
            <input id="swal-numero" type="text" class="custom-input" placeholder="Ex: F-001" autocomplete="off">
            <div class="input-helper">Num\xE9ro unique de la facture</div>
          </div>
          
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
              </svg>
              Client <span class="required-star">*</span>
            </label>
            <input id="swal-client" type="text" class="custom-input" placeholder="Nom du client" autocomplete="off">
          </div>
          
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
              </svg>
              Date de vente <span class="required-star">*</span>
            </label>
            <input id="swal-date" type="date" class="custom-input" value="${this.getTodayDate()}">
          </div>
          
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              Montant total (DT) <span class="required-star">*</span>
            </label>
            <input id="swal-montant" type="number" class="custom-input" placeholder="0.00" step="0.01" min="0" autocomplete="off">
            <div class="input-helper">Montant en dinars tunisiens</div>
          </div>
          
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z"/>
              </svg>
              D\xE9tails (poissons vendus)
            </label>
            <textarea id="swal-details" class="custom-textarea" placeholder="Ex: 50 kg de dorade, 30 kg de loup, 20 kg de rouget..."></textarea>
          </div>
        </div>
      `,focusConfirm:!1,showCancelButton:!0,confirmButtonText:"Ajouter la facture",cancelButtonText:"Annuler",confirmButtonColor:"#10b981",cancelButtonColor:"#6b7280",width:"600px",preConfirm:()=>{let n=document.getElementById("swal-numero").value.trim(),l=document.getElementById("swal-client").value.trim(),c=document.getElementById("swal-date").value,p=parseFloat(document.getElementById("swal-montant").value),h=document.getElementById("swal-details").value.trim();return!n||!l||!c||!p?(b.default.showValidationMessage("Veuillez remplir tous les champs obligatoires"),!1):p<=0?(b.default.showValidationMessage("Le montant doit \xEAtre sup\xE9rieur \xE0 0"),!1):{numero:n,client:l,date:c,montant:p,details:h}}});if(e)try{this.alertService.loading("Ajout de la facture...");let n={sortieId:t.id,numeroFacture:e.numero,client:e.client,dateVente:new Date(e.date),montant:e.montant,details:e.details||void 0};yield this.factureService.addFacture(n),this.alertService.close(),this.alertService.success("Facture ajout\xE9e avec succ\xE8s!")}catch(n){console.error("Erreur:",n),this.alertService.close(),this.alertService.error("Erreur lors de l'ajout")}})}modifierFacture(t){return S(this,null,function*(){let{value:e}=yield b.default.fire({title:"Modifier la facture",html:`
        <style>
          .facture-form { text-align: left; padding: 1rem 0; }
          .form-group { margin-bottom: 1.25rem; }
          .form-label { display: block; margin-bottom: 0.625rem; font-weight: 600; color: #374151; font-size: 0.9rem; }
          .custom-input, .custom-textarea { width: 100%; padding: 0.75rem 0.875rem; border: 2px solid #e5e7eb; border-radius: 0.5rem; font-size: 0.95rem; transition: all 0.3s; font-family: inherit; }
          .custom-input:focus, .custom-textarea:focus { outline: none; border-color: #f59e0b; box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.1); }
          .custom-textarea { resize: vertical; min-height: 80px; }
        </style>
        <div class="facture-form">
          <div class="form-group">
            <label class="form-label">N\xB0 Facture</label>
            <input id="swal-numero" type="text" class="custom-input" value="${t.numeroFacture}">
          </div>
          <div class="form-group">
            <label class="form-label">Client</label>
            <input id="swal-client" type="text" class="custom-input" value="${t.client}">
          </div>
          <div class="form-group">
            <label class="form-label">Date de vente</label>
            <input id="swal-date" type="date" class="custom-input" value="${this.formatDate(t.dateVente)}">
          </div>
          <div class="form-group">
            <label class="form-label">Montant total (DT)</label>
            <input id="swal-montant" type="number" class="custom-input" value="${t.montant}" step="0.01" min="0">
          </div>
          <div class="form-group">
            <label class="form-label">D\xE9tails</label>
            <textarea id="swal-details" class="custom-textarea">${t.details||""}</textarea>
          </div>
        </div>
      `,focusConfirm:!1,showCancelButton:!0,confirmButtonText:"Modifier",cancelButtonText:"Annuler",confirmButtonColor:"#f59e0b",width:"600px",preConfirm:()=>{let n=document.getElementById("swal-numero").value.trim(),l=document.getElementById("swal-client").value.trim(),c=document.getElementById("swal-date").value,p=parseFloat(document.getElementById("swal-montant").value),h=document.getElementById("swal-details").value.trim();return{numero:n,client:l,date:c,montant:p,details:h}}});if(e)try{this.alertService.loading("Modification..."),yield this.factureService.updateFacture(t.id,{numeroFacture:e.numero,client:e.client,dateVente:new Date(e.date),montant:e.montant,details:e.details||void 0}),this.alertService.close(),this.alertService.success("Facture modifi\xE9e!")}catch(n){console.error("Erreur:",n),this.alertService.close(),this.alertService.error("Erreur lors de la modification")}})}supprimerFacture(t){return S(this,null,function*(){if(yield this.alertService.confirmDelete(`la facture ${t.numeroFacture} (${t.montant} DT)`))try{this.alertService.loading("Suppression..."),yield this.factureService.deleteFacture(t.id),this.alertService.close(),this.alertService.toast("Facture supprim\xE9e","success")}catch(n){console.error("Erreur:",n),this.alertService.close(),this.alertService.error("Erreur lors de la suppression")}})}getTodayDate(){let t=new Date,e=t.getFullYear(),n=String(t.getMonth()+1).padStart(2,"0"),l=String(t.getDate()).padStart(2,"0");return`${e}-${n}-${l}`}formatDate(t){return t?.toDate?t.toDate().toISOString().split("T")[0]:t instanceof Date?t.toISOString().split("T")[0]:""}formatDisplayDate(t){return t?.toDate?t.toDate().toLocaleDateString("fr-FR"):t instanceof Date?t.toLocaleDateString("fr-FR"):""}};w.\u0275fac=function(e){return new(e||w)(C(R),C(G),C($),C(q),C(N))},w.\u0275cmp=B({type:w,selectors:[["app-ventes-list"]],decls:9,vars:7,consts:[[1,"ventes-container"],[1,"header"],[1,"title"],["class","btn btn-primary",3,"click",4,"ngIf"],["class","loading",4,"ngIf"],["class","no-data",4,"ngIf"],["class","content",4,"ngIf"],[1,"btn","btn-primary",3,"click"],["fill","none","viewBox","0 0 24 24","stroke","currentColor"],["stroke-linecap","round","stroke-linejoin","round","stroke-width","2","d","M12 6v6m0 0v6m0-6h6m-6 0H6"],[1,"loading"],[1,"spinner"],[1,"no-data"],["fill","none","viewBox","0 0 24 24","stroke","currentColor",1,"no-data-icon"],["stroke-linecap","round","stroke-linejoin","round","stroke-width","2","d","M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"],[1,"content"],[1,"total-general-card"],[1,"total-icon"],["stroke-linecap","round","stroke-linejoin","round","stroke-width","2","d","M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"],[1,"total-content"],[1,"total-amount"],["class","sorties-list",4,"ngIf"],["stroke-linecap","round","stroke-linejoin","round","stroke-width","2","d","M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"],[1,"sorties-list"],["class","sortie-section",4,"ngFor","ngForOf"],[1,"sortie-section"],[1,"sortie-header"],[1,"sortie-info"],[1,"sortie-dates"],[1,"sortie-total"],[1,"total-label"],[1,"total-value"],[1,"btn","btn-secondary",3,"click"],["class","no-factures",4,"ngIf"],["class","factures-grid",4,"ngIf"],[1,"no-factures"],[1,"factures-grid"],["class","facture-card",4,"ngFor","ngForOf"],[1,"facture-card"],[1,"facture-header-card"],[1,"facture-numero"],[1,"facture-montant"],[1,"facture-body"],["class","facture-details",4,"ngIf"],[1,"facture-actions"],[1,"btn","btn-sm","btn-warning",3,"click"],["stroke-linecap","round","stroke-linejoin","round","stroke-width","2","d","M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"],[1,"btn","btn-sm","btn-danger",3,"click"],["stroke-linecap","round","stroke-linejoin","round","stroke-width","2","d","M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"],[1,"facture-details"]],template:function(e,n){e&1&&(a(0,"div",0)(1,"div",1)(2,"h1",2),s(3),d(4,"translate"),i(),M(5,K,5,3,"button",3),i(),M(6,Q,5,3,"div",4)(7,X,6,3,"div",5)(8,oe,14,9,"div",6),i()),e&2&&(r(3),v(m(4,5,"MENU.VENTES")),r(2),f("ngIf",!n.loading&&n.sortiesWithFactures.length>0),r(),f("ngIf",n.loading),r(),f("ngIf",!n.loading&&!n.selectedBoat),r(),f("ngIf",!n.loading&&n.selectedBoat))},dependencies:[j,D,L,H,z,A],styles:[".ventes-container[_ngcontent-%COMP%]{max-width:1600px;margin:0 auto;padding:2rem}.header[_ngcontent-%COMP%]{margin-bottom:2rem}.title[_ngcontent-%COMP%]{font-size:2rem;font-weight:700;color:#1f2937;margin:0}.loading[_ngcontent-%COMP%]{text-align:center;padding:3rem}.loading[_ngcontent-%COMP%]   .spinner[_ngcontent-%COMP%]{width:40px;height:40px;margin:0 auto 1rem;border:4px solid #f3f4f6;border-top-color:#10b981;border-radius:50%;animation:_ngcontent-%COMP%_spin 1s linear infinite}@keyframes _ngcontent-%COMP%_spin{to{transform:rotate(360deg)}}.no-data[_ngcontent-%COMP%]{text-align:center;padding:3rem;color:#9ca3af}.no-data[_ngcontent-%COMP%]   .no-data-icon[_ngcontent-%COMP%]{width:64px;height:64px;margin:0 auto 1rem;opacity:.5}.total-general-card[_ngcontent-%COMP%]{background:linear-gradient(135deg,#10b981,#059669);color:#fff;padding:2rem;border-radius:.75rem;box-shadow:0 4px 6px #10b9814d;margin-bottom:2rem;display:flex;align-items:center;gap:1.5rem}.total-general-card[_ngcontent-%COMP%]   .total-icon[_ngcontent-%COMP%]{width:80px;height:80px;background:#fff3;border-radius:.75rem;display:flex;align-items:center;justify-content:center}.total-general-card[_ngcontent-%COMP%]   .total-icon[_ngcontent-%COMP%]   svg[_ngcontent-%COMP%]{width:48px;height:48px}.total-general-card[_ngcontent-%COMP%]   .total-content[_ngcontent-%COMP%]{flex:1}.total-general-card[_ngcontent-%COMP%]   .total-content[_ngcontent-%COMP%]   h3[_ngcontent-%COMP%]{margin:0 0 .5rem;font-size:1.125rem;font-weight:600;opacity:.95}.total-general-card[_ngcontent-%COMP%]   .total-content[_ngcontent-%COMP%]   .total-amount[_ngcontent-%COMP%]{margin:0;font-size:2.5rem;font-weight:700}.sorties-list[_ngcontent-%COMP%]{display:flex;flex-direction:column;gap:2rem}.sortie-section[_ngcontent-%COMP%]{background:#fff;border-radius:.75rem;padding:1.5rem;box-shadow:0 1px 3px #0000001a}.sortie-header[_ngcontent-%COMP%]{display:flex;justify-content:space-between;align-items:center;gap:1rem;margin-bottom:1.5rem;padding-bottom:1.5rem;border-bottom:2px solid #e5e7eb;flex-wrap:wrap}.sortie-header[_ngcontent-%COMP%]   .sortie-info[_ngcontent-%COMP%]{flex:1}.sortie-header[_ngcontent-%COMP%]   .sortie-info[_ngcontent-%COMP%]   h2[_ngcontent-%COMP%]{margin:0 0 .5rem;font-size:1.5rem;font-weight:700;color:#1f2937}.sortie-header[_ngcontent-%COMP%]   .sortie-info[_ngcontent-%COMP%]   .sortie-dates[_ngcontent-%COMP%]{margin:0;color:#6b7280;font-size:.875rem}.sortie-header[_ngcontent-%COMP%]   .sortie-total[_ngcontent-%COMP%]{display:flex;flex-direction:column;align-items:flex-end}.sortie-header[_ngcontent-%COMP%]   .sortie-total[_ngcontent-%COMP%]   .total-label[_ngcontent-%COMP%]{font-size:.875rem;color:#6b7280;font-weight:500}.sortie-header[_ngcontent-%COMP%]   .sortie-total[_ngcontent-%COMP%]   .total-value[_ngcontent-%COMP%]{font-size:1.75rem;font-weight:700;color:#10b981}.btn[_ngcontent-%COMP%]{display:inline-flex;align-items:center;gap:.5rem;padding:.75rem 1.5rem;border:none;border-radius:.5rem;font-weight:600;cursor:pointer;transition:all .3s}.btn[_ngcontent-%COMP%]   svg[_ngcontent-%COMP%]{width:20px;height:20px}.btn-primary[_ngcontent-%COMP%]{background-color:#10b981;color:#fff}.btn-primary[_ngcontent-%COMP%]:hover{background-color:#059669;transform:translateY(-2px);box-shadow:0 4px 6px #10b9814d}.btn-sm[_ngcontent-%COMP%]{padding:.5rem 1rem;font-size:.875rem}.btn-sm[_ngcontent-%COMP%]   svg[_ngcontent-%COMP%]{width:16px;height:16px}.btn-warning[_ngcontent-%COMP%]{background-color:#fef3c7;color:#92400e}.btn-warning[_ngcontent-%COMP%]:hover{background-color:#fde68a}.btn-danger[_ngcontent-%COMP%]{background-color:#fee2e2;color:#991b1b}.btn-danger[_ngcontent-%COMP%]:hover{background-color:#fecaca}.no-factures[_ngcontent-%COMP%]{text-align:center;padding:2rem;color:#9ca3af;font-style:italic}.factures-grid[_ngcontent-%COMP%]{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:1.5rem}.facture-card[_ngcontent-%COMP%]{background:#f9fafb;border-radius:.5rem;padding:1.25rem;border:1px solid #e5e7eb;transition:all .3s}.facture-card[_ngcontent-%COMP%]:hover{transform:translateY(-2px);box-shadow:0 4px 6px #0000001a}.facture-header-card[_ngcontent-%COMP%]{display:flex;justify-content:space-between;align-items:center;margin-bottom:1rem;padding-bottom:1rem;border-bottom:2px solid #e5e7eb}.facture-header-card[_ngcontent-%COMP%]   .facture-numero[_ngcontent-%COMP%]{font-weight:700;color:#1f2937;font-size:1.125rem}.facture-header-card[_ngcontent-%COMP%]   .facture-montant[_ngcontent-%COMP%]{font-size:1.5rem;font-weight:700;color:#10b981}.facture-body[_ngcontent-%COMP%]{margin-bottom:1rem}.facture-body[_ngcontent-%COMP%]   p[_ngcontent-%COMP%]{margin:.5rem 0;color:#6b7280;font-size:.875rem}.facture-body[_ngcontent-%COMP%]   p[_ngcontent-%COMP%]   strong[_ngcontent-%COMP%]{color:#1f2937}.facture-body[_ngcontent-%COMP%]   .facture-details[_ngcontent-%COMP%]{font-style:italic}.facture-actions[_ngcontent-%COMP%]{display:flex;gap:.5rem}@media (max-width: 768px){.ventes-container[_ngcontent-%COMP%]{padding:1rem}.title[_ngcontent-%COMP%]{font-size:1.5rem}.total-general-card[_ngcontent-%COMP%]{flex-direction:column;text-align:center}.sortie-header[_ngcontent-%COMP%]{flex-direction:column;align-items:flex-start}.factures-grid[_ngcontent-%COMP%]{grid-template-columns:1fr}}.btn-secondary[_ngcontent-%COMP%]{background-color:#3b82f6;color:#fff}.btn-secondary[_ngcontent-%COMP%]:hover{background-color:#2563eb;transform:translateY(-2px);box-shadow:0 4px 6px #3b82f64d}"]});var W=w;export{W as VentesListComponent};
