# CAHIER DES CHARGES TECHNIQUE
## Projet : Plateforme de Traçabilité Marbrerie Funéraire
### Version 1.0 - Infrastructure 100% Gratuite
### Date : Février 2026

---

## 1. CONTEXTE ET OBJECTIFS

### 1.1 Contexte métier
- **Activité** : Importation de marbre tunisien pour monuments funéraires en France
- **Modèle** : B2B (fourniture aux pompes funèbres) + prestation de pose/renovation
- **Enjeu** : Transformer une activité informelle en entreprise traçable et conforme
- **Différenciation** : Traçabilité complète pierre carrière → monument posé

### 1.2 Objectifs du système
1. **Traçabilité irréprochable** : Chaque bloc de marbre traçable de la carrière tunisienne au cimetière français
2. **Conformité réglementaire** : Devis funéraires conformes à l'arrêté du 23/08/2010, gestion des habilitations
3. **Contrôle financier** : Suivi des marges par lot, traçabilité des paiements, séparation des rôles
4. **Transparence associative** : Vous (France) et votre oncle (Tunisie) avec visibilité mutuelle sur les flux

### 1.3 Utilisateurs du système

| Rôle | Localisation | Besoin principal |
|------|--------------|------------------|
| **Administrateur** (vous) | France | Contrôle total, validation des entrées, reporting |
| **Importateur** (oncle) | Tunisie/France | Saisie des arrivages, documents douaniers, photos |
| **Client Pomme Funèbre** | France | Consultation catalogue, devis, suivi commande |
| **Client Famille** (optionnel) | France | Devis direct (si vente en service libre) |

---

## 2. ARCHITECTURE TECHNIQUE (Gratuite)

### 2.1 Stack MVP

| Couche | Service | Fonction | Limites gratuites |
|--------|---------|----------|-------------------|
| **Frontend** | Netlify (Next.js/Nuxt.js) | Interface web, dashboard | 100GB bande passante/mois |
| **Backend API** | Netlify Functions | Génération PDF, webhooks | 125k invocations/mois |
| **Base de données** | Supabase (PostgreSQL) | Données métier, traçabilité | 500MB stockage, 2GB transfert |
| **Authentification** | Supabase Auth | Connexion sécurisée | 50k utilisateurs/mois |
| **Stockage fichiers** | Supabase Storage | Photos, PDF, documents | 1GB |
| **Email** | Gmail (manuel) | Notifications, relances | Usage humain |
| **Domaine** | Netlify subdomain | https://marbrerie.netlify.app | - |

### 2.2 Schéma de données principal

#### Table : `lots_marbre` (Cœur du système)

```sql
id: uuid (PK)
reference_interne: string (unique, ex: "TUN-2026-001")
origine_carriere: string (nom carrière Tunisie)
date_extraction: date
date_importation: date
numero_declaration_douane: string
montant_frais_douane: decimal
poids_kg: decimal
dimensions_cm: string (format: LxlxH)
type_marbre: enum (blanc, noir, vert, beige, etc.)
qualite: enum (A, B, C)
test_resistance_mpa: decimal (norme cimetière)
photos_lot: array[string] (URLs Supabase Storage)
document_certificat_origine: string (URL)
document_douane: string (URL)
localisation_entrepot: string (ex: "Paris 17e - Entrepôt Dupont")
statut: enum (en_transit, en_stock, reserve, vendu, pose)
prix_coutant_total: decimal (achat + transport + douane)
marge_souhaitee_pct: decimal
prix_vente_conseille: decimal
cree_par: uuid (FK -&gt; utilisateurs)
date_creation: timestamp
notes: text
```

#### Table : clients (Pompes funèbres)

**sql**Copy

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   id: uuid (PK)  type_client: enum (pompe_funebre, particulier, entreprise)  nom_enseigne: string  siret: string (validation format)  numero_habilitation_prefecture: string (si pompe funèbre)  adresse: string  code_postal: string  ville: string  contact_nom: string  contact_telephone: string  contact_email: string  est_actif: boolean  cree_le: timestamp  notes_diverses: text   `

#### Table : devis (Conformité arrêté 23/08/2010)

**sql**Copy

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   id: uuid (PK)  numero_devis: string (unique, format: D-2026-0001)  date_devis: date  date_validite: date (devis valable 15 jours min)  client_id: uuid (FK -> clients)  lot_id: uuid (FK -> lots_marbre, nullable si prestation seule)  type_prestation: enum (fourniture, pose, renovation, complet)  description_travaux: text  -- Éléments obligatoires réglementation  prix_ht_fourniture: decimal  prix_ht_main_oeuvre: decimal  prix_ht_transport: decimal  remise_eventuelle: decimal  total_ht: decimal  tva_taux: decimal (20% standard, 10% si conditions)  total_ttc: decimal  -- Spécificités funéraires  cimetiere_nom: string  concession_duree: string (si applicable)  reglement_cimetiere_respecte: boolean  attestation_conformite_generee: boolean  statut: enum (brouillon, envoye, accepte, refuse, facture)  date_acceptation: timestamp  document_pdf_url: string  envoye_par_email: boolean  cree_par: uuid (FK)  date_creation: timestamp   `

#### Table : factures (Simplifié pour contrôle)

**sql**Copy

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   id: uuid (PK)  numero_facture: string (unique)  devis_id: uuid (FK)  date_facture: date  date_echeance: date  montant_ttc: decimal  statut_paiement: enum (en_attente, partiel, paye, retard)  moyen_paiement: enum (virement, cheque, espece - éviter)  date_paiement: timestamp  justificatif_url: string (si virement)  notes: text   `

#### Table : chantiers (Suivi opérationnel)

**sql**Copy

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   id: uuid (PK)  devis_id: uuid (FK)  date_pose_prevue: date  date_pose_effective: date  adresse_cimetiere: string  section_carre: string  numero_concession: string  photos_avant: array[string]  photos_apres: array[string]  bon_livraison_signe_url: string  attestation_pose_url: string  statut: enum (planifie, en_cours, termine, litige)  commentaires: text   `

#### Table : utilisateurs\_systeme (Vous + Oncle)

**sql**Copy

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   id: uuid (PK, lié Supabase Auth)  email: string  role: enum (admin_france, importateur_tunisie, commercial)  nom: string  telephone: string  date_creation: timestamp  est_actif: boolean   `

#### Table : logs\_audit (Traçabilité des modifications)

**sql**Copy

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   id: uuid (PK)  table_concernee: string  enregistrement_id: uuid  type_action: enum (creation, modification, suppression)  champs_modifies: jsonb  utilisateur_id: uuid (FK)  date_action: timestamp  ip_address: string   `

### 2.3 Flux de données principaux

**plain**Copy

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   [Carrière Tunisie]       ↓ (extraction + docs)  [Oncle saisit dans le système] → Upload documents douaniers + photos      ↓  [Arrivage en France - Entrepôt 17e]      ↓  [Vous validez la réception] → Contrôle qualité, stockage      ↓  [Catalogue B2B visible par pompes funèbres]      ↓  [Devis généré (conforme réglementation)]      ↓  [Validation client] → Signature/accord      ↓  [Facturation] → Suivi paiement      ↓  [Pose en cimetière] → Photos + attestations      ↓  [Clôture dossier]   `

3\. FONCTIONNALITÉS DÉTAILLÉES
------------------------------

### 3.1 Module Importation & Stock (Oncle + Vous)

#### 3.1.1 Saisie d'un nouvel arrivage (Oncle)

**Accès** : Interface protégée, rôle "importateur"**Formulaire de saisie** :

*   Upload multi-photos du lot (max 10MB par fichier)
    
*   Scan du certificat d'origine de la carrière
    
*   Scan de la déclaration douane
    
*   Saisie des caractéristiques techniques (poids, dimensions)
    
*   Sélection du type de marbre (liste déroulante paramétrable)
    
*   Calcul automatique du prix de revient (achat + transport + douane)
    

**Règles métier** :

*   Référence interne générée auto : TUN-AAAA-NNN (ex: TUN-2026-001)
    
*   Photos obligatoires (minimum 3 angles différents)
    
*   Documents douaniers obligatoires avant validation finale
    

#### 3.1.2 Validation réception France (Vous)

**Tableau de bord** : Liste des lots "en\_transit" à valider**Actions possibles** :

*   Visualisation des photos et documents uploadés
    
*   Saisie du lieu exact de stockage (entrepôt 17e)
    
*   Validation qualité (checkbox : conforme/non conforme)
    
*   Si non conforme : saisie des écarts et notification oncle
    
*   Passage du statut à "en\_stock" après validation
    

#### 3.1.3 Gestion des stocks

**Vue tableau** :

*   Filtres : par type de marbre, par statut, par date d'arrivée
    
*   Recherche rapide par référence interne
    
*   Alertes visuelles : lots "en\_transit" depuis +30 jours (anomalie)
    

**Indicateurs clés** :

*   Valeur totale du stock (coûtant)
    
*   Marge potentielle si tout vendu au prix conseillé
    
*   Lots les plus anciens (à écouler en priorité)
    

### 3.2 Module Catalogue B2B (Clients Pompes Funèbres)

#### 3.2.1 Vitrine publique (sans connexion)

*   Présentation des types de marbre tunisien (fiches techniques)
    
*   Portfolio photos des réalisations (à alimenter progressivement)
    
*   Formulaire de contact simple (envoie vers votre Gmail)
    
*   Mention légale avec SIRET (à obtenir) et adresse effective
    

#### 3.2.2 Espace Pro (connexion requise)

**Inscription/Connexion** : Via Supabase Auth (email + mot de passe)**Catalogue réservé** :

*   Visualisation des lots disponibles "en\_stock"
    
*   Pour chaque lot : photos HD, dimensions, prix de vente conseillé
    
*   Filtres : par type de marbre, par gamme de prix, par dimensions
    
*   Bouton "Ajouter à ma sélection" (panier B2B)
    

**Génération devis rapide** :

*   Sélection d'un ou plusieurs lots
    
*   Saisie du cimetière et type de prestation (fourniture seule / fourniture + pose)
    
*   Calcul automatique du devis prévisionnel (HT et TTC)
    
*   Export PDF immédiat (brouillon, non signé)
    

### 3.3 Module Devis & Facturation (Conformité réglementaire)

#### 3.3.1 Création devis détaillé

**Conformité arrêté du 23 août 2010** :

*   Numérotation unique et continue
    
*   Date de validité obligatoire (15 jours minimum)
    
*   Décomposition obligatoire : fourniture / main d'œuvre / transport (si applicable)
    
*   Mention "Devis établi conformément à l'article L. 2223-31 du code général des collectivités territoriales"
    
*   Mentions légales complètes en pied de page
    

**Workflow** :

1.  Sélection client (création rapide si nouveau)
    
2.  Sélection lot(s) de marbre (lien traçabilité)
    
3.  Saisie prestation complémentaire (gravure, pose, etc.)
    
4.  Calcul automatique des totaux
    
5.  Génération PDF avec mise en page professionnelle
    
6.  Marquage "envoyé" avec date
    

#### 3.3.2 Suivi des devis

**Tableau de bord** :

*   Devis en attente (non répondus, date de validité dépassée)
    
*   Devis acceptés (à transformer en facture)
    
*   Taux de conversion (acceptés / total envoyés)
    

**Actions** :

*   Relance automatique (email via Gmail manuel pour l'instant)
    
*   Duplication devis (pour variante)
    
*   Transformation en facture (un clic, génération numéro facture)
    

#### 3.3.3 Facturation simplifiée

*   Génération facture PDF à partir du devis accepté
    
*   Suivi des paiements (statut + date + moyen)
    
*   Export mensuel pour comptabilité (CSV)
    

### 3.4 Module Chantiers & Pose (Traçabilité finale)

#### 3.4.1 Planification

*   Calendrier des poses à venir
    
*   Affectation des équipes (si vous avez des poseurs)
    
*   Rappels automatiques (3 jours avant, jour J)
    

#### 3.4.2 Rapport de pose

**Formulaire mobile-friendly** (à remplir sur smartphone au cimetière) :

*   Upload photos "avant" (emplacement vide)
    
*   Upload photos "après" (monument posé)
    
*   Saisie précise de l'emplacement (section, carré, numéro)
    
*   Signature numérique du responsable ou client
    
*   Upload du bon de livraison signé scan
    

**Validation** : Vous validez la clôture depuis l'interface

### 3.5 Module Reporting & Contrôle (Vous uniquement)

#### 3.5.1 Tableau de bord général

**Vue synthétique** :

*   Chiffre d'affaires du mois / année en cours
    
*   Nombre de lots en stock (valeur)
    
*   Devis en attente de réponse
    
*   Chantiers à planifier / en cours
    

#### 3.5.2 Analyses métier

*   Rentabilité par lot (prix de vente réel - coûtant)
    
*   Rentabilité par type de marbre
    
*   Clients les plus actifs
    
*   Délais moyens importation → vente → pose
    

#### 3.5.3 Alertes et sécurité

*   Lots sans documents douaniers (non conformes)
    
*   Devis non transformés depuis +30 jours
    
*   Paiements en retard
    
*   Modifications de données importantes (log audit)
    

4\. CONFORMITÉ ET SÉCURITÉ
--------------------------

### 4.1 Conformité réglementaire

#### Données personnelles (RGPD)

*   Consentement explicite à la création de compte
    
*   Politique de confidentialité affichée
    
*   Droit à l'effacement (suppression compte client)
    
*   Pas de cookies tiers (Netlify ne pose pas de cookies traçants)
    

#### Réglementation funéraire

*   Conservation des devis 10 ans (archivage PDF)
    
*   Traçabilité des monuments (lien lot → cimetière)
    
*   Respect des règlements de cimetière (champ "reglement\_cimetiere\_respecte")
    

### 4.2 Sécurité technique

#### Authentification (Supabase Auth)

*   JWT tokens sécurisés
    
*   Sessions limitées dans le temps
    
*   Mots de passe : min 8 caractères, complexité recommandée
    
*   Récupération de mot de passe par email
    

#### Autorisations (Row Level Security - Supabase)

**sql**Copy

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   -- Exemple : Un client ne voit que ses propres devis  CREATE POLICY "Clients voient leurs devis" ON devis  FOR SELECT USING (auth.uid() = client_id OR                     auth.uid() IN (SELECT id FROM utilisateurs_systeme WHERE role = 'admin_france'));  -- L'oncle ne voit que les lots qu'il a créés ou tous si admin  CREATE POLICY "Importateur voit ses lots" ON lots_marbre  FOR SELECT USING (cree_par = auth.uid() OR                     auth.uid() IN (SELECT id FROM utilisateurs_systeme WHERE role = 'admin_france'));   `

#### Sauvegardes

*   Supabase : backups automatiques quotidiens (conservation 7 jours en gratuit)
    
*   Export mensuel manuel des données critiques (CSV)
    

5\. INTERFACES UTILISATEUR (UI/UX)
----------------------------------

### 5.1 Design général

*   **Style** : Professionnel, sobre, épuré (adapté au secteur funéraire)
    
*   **Couleurs** : Neutres (blanc, gris anthracite, touche de vert ou bleu discret)
    
*   **Typographie** : Sans-serif lisible (Inter ou system-ui)
    
*   **Responsive** : Mobile-first (usage sur chantier pour les photos)
    

### 5.2 Pages principales

#### Public

*   **Accueil** : Présentation expertise tunisienne, types de marbre, appel à action contact
    
*   **Catalogue** : Grille des lots disponibles (photos, prix, dimensions)
    
*   **Réalisations** : Portfolio photos monuments posés
    
*   **Contact** : Formulaire simple (nom, email, téléphone, message)
    

#### Espace Pro (connecté)

*   **Dashboard** : Vue d'ensemble personnalisée selon rôle
    
*   **Mon Compte** : Profil, historique devis/factures
    
*   **Catalogue Pro** : Même que public mais avec prix et détails techniques
    
*   **Mes Devis** : Liste, création, téléchargement PDF
    
*   **Mes Commandes** : Suivi des chantiers en cours
    

#### Admin (vous)

*   **Gestion Stocks** : Tableau complet des lots + actions
    
*   **Gestion Clients** : Annuaire pompes funèbres
    
*   **Comptabilité** : Devis, factures, paiements
    
*   **Paramètres** : Types de marbre, tarifs, utilisateurs système
    

6\. PLANNING DE DÉVELOPPEMENT
-----------------------------

### Phase 1 : Fondations (Semaines 1-3)

*   \[ \] Configuration Netlify + Supabase
    
*   \[ \] Mise en place base de données (tables SQL)
    
*   \[ \] Authentification basique (login/logout)
    
*   \[ \] Upload fichiers (photos, PDF)
    
*   \[ \] Structure frontend (routing, layout)
    

### Phase 2 : Cœur métier (Semaines 4-8)

*   \[ \] Module lots marbre (CRUD complet)
    
*   \[ \] Module clients (CRUD)
    
*   \[ \] Génération devis PDF (template conforme)
    
*   \[ \] Espace pro basique (catalogue + devis)
    

### Phase 3 : Production (Semaines 9-12)

*   \[ \] Module chantiers (pose, photos)
    
*   \[ \] Tableaux de bord et reporting
    
*   \[ \] Tests utilisateurs (oncle + 1-2 pompes funèbres pilotes)
    
*   \[ \] Corrections et optimisations
    

### Phase 4 : Lancement (Semaine 13)

*   \[ \] Déploiement production
    
*   \[ \] Formation oncle (saisie des arrivages)
    
*   \[ \] Premiers lots saisis et testés
    
*   \[ \] Prospection pompes funèbres avec démo
    

7\. BUDGET DÉVELOPPEMENT (Votre temps)
--------------------------------------

**Table**Copy**PhaseHeures estiméesCompétences requises**Fondations40hSQL, React/Vue basics, GitCœur métier80hAPI REST, PDF generation, UI designProduction60hMobile UX, testing, débug**Total~180h**Soit ~4-5 semaines à plein temps**Compétences à acquérir si besoin** :

*   Next.js ou Nuxt.js (framework frontend)
    
*   Supabase (documentation excellente)
    
*   Tailwind CSS (styling rapide)
    
*   Génération PDF (librairie comme Puppeteer ou react-pdf)
    

8\. LIVRABLES ATTENDUS
----------------------

### 8.1 Code source

*   Repository GitHub (privé) avec :
    
    *   /frontend : Application Next.js/Nuxt.js
        
    *   /supabase : Migrations SQL et fonctions edge
        
    *   /docs : Documentation technique et utilisateur
        

### 8.2 Documentation

*   **README** : Installation et déploiement
    
*   **Guide utilisateur** : Comment saisir un lot, créer un devis (pour oncle)
    
*   **Guide admin** : Gestion des stocks, validation, reporting
    

### 8.3 Données de test

*   3-5 lots fictifs avec photos
    
*   2 clients test (pompes funèbres)
    
*   1 devis exemple complet
    

9\. RISQUES ET MITIGATION
-------------------------

**Table**Copy**RisqueProbabilitéImpactMitigation**Dépassement stockage Supabase (500MB)MoyenneBloquantCompression photos, archivage anciens lots sur disque dur externeComplexité génération PDFÉlevéeRetardUtiliser template HTML → PDF simple, pas de mise en page trop complexeRésistance oncle à la saisie informatiqueÉlevéeAdoption lenteInterface ultra simplifiée pour lui, formation patiente, backup Excel temporaireLimite Netlify Functions (125k/mois)FaiblePerformanceArchitecture légère, appels API optimisés

10\. ÉVOLUTIONS FUTURES (hors MVP)
----------------------------------

*   **Paiement en ligne** : Intégration Stripe (quand CA le justifie)
    
*   **Signature électronique** : Yousign ou Docapost API
    
*   **Application mobile** : PWA (Progressive Web App) pour la pose sur chantier
    
*   **Multi-entrepôts** : Si expansion hors Paris 17e
    
*   **API ouverte** : Pour intégration avec logiciels des grossistes pompes funèbres
    

**Document validé par :** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_**Date validation :** \_\_\_\_\_\_\_\_\_\_\_**Version :** 1.0**Prochaine étape :** Création des comptes Netlify et Supabase, puis développement Phase 1.