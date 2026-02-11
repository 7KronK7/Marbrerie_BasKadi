#_CAHIER_DES_CHARGES_TECHNIQUE.md
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