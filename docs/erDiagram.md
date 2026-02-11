erDiagram.md
    %% Définition des entités avec leurs attributs
    
    UTILISATEURS_SYSTEME {
        uuid id PK "Clé primaire (liée Supabase Auth)"
        string email "Email de connexion"
        enum role "admin_france | importateur_tunisie | commercial"
        string nom "Nom complet"
        string telephone "Téléphone"
        boolean est_actif "Actif/Inactif"
        timestamp date_creation "Date de création"
    }
    
    LOTS_MARBRE {
        uuid id PK "Clé primaire"
        string reference_interne UK "Unique: TUN-2026-001"
        string origine_carriere "Nom carrière Tunisie"
        date date_extraction "Date extraction"
        date date_importation "Date arrivée France"
        string numero_declaration_douane "N° déclaration"
        decimal montant_frais_douane "Frais de douane"
        decimal poids_kg "Poids en kg"
        string dimensions_cm "Format: LxlxH"
        enum type_marbre "blanc | noir | vert | beige | etc."
        enum qualite "A | B | C"
        decimal test_resistance_mpa "Résistance mécanique"
        array photos_lot "URLs Supabase Storage"
        string document_certificat_origine "URL document"
        string document_douane "URL document"
        string localisation_entrepot "Ex: Paris 17e"
        enum statut "en_transit | en_stock | reserve | vendu | pose"
        decimal prix_coutant_total "Coût total"
        decimal marge_souhaitee_pct "% marge souhaitée"
        decimal prix_vente_conseille "Prix conseillé"
        uuid cree_par FK "Créé par (utilisateur)"
        timestamp date_creation "Date création"
        text notes "Notes libres"
    }
    
    CLIENTS {
        uuid id PK "Clé primaire"
        enum type_client "pompe_funebre | particulier | entreprise"
        string nom_enseigne "Nom de l'enseigne"
        string siret "N° SIRET (validation format)"
        string numero_habilitation_prefecture "N° habilitation si pompe funèbre"
        string adresse "Adresse"
        string code_postal "Code postal"
        string ville "Ville"
        string contact_nom "Nom du contact"
        string contact_telephone "Téléphone"
        string contact_email "Email"
        boolean est_actif "Client actif"
        timestamp cree_le "Date création"
        text notes_diverses "Notes"
    }
    
    DEVIS {
        uuid id PK "Clé primaire"
        string numero_devis UK "Unique: D-2026-0001"
        date date_devis "Date émission"
        date date_validite "Valable jusqu'à (15j min)"
        uuid client_id FK "Client concerné"
        uuid lot_id FK "Lot associé (nullable)"
        enum type_prestation "fourniture | pose | renovation | complet"
        text description_travaux "Description détaillée"
        decimal prix_ht_fourniture "Montant HT fourniture"
        decimal prix_ht_main_oeuvre "Montant HT main d'œuvre"
        decimal prix_ht_transport "Montant HT transport"
        decimal remise_eventuelle "Remise accordée"
        decimal total_ht "Total HT"
        decimal tva_taux "Taux TVA (20% ou 10%)"
        decimal total_ttc "Total TTC"
        string cimetiere_nom "Nom du cimetière"
        string concession_duree "Durée concession"
        boolean reglement_cimetiere_respecte "Conformité règlement"
        boolean attestation_conformite_generee "Attestation générée"
        enum statut "brouillon | envoye | accepte | refuse | facture"
        timestamp date_acceptation "Date acceptation client"
        string document_pdf_url "URL PDF généré"
        boolean envoye_par_email "Envoyé par email"
        uuid cree_par FK "Créé par (utilisateur)"
        timestamp date_creation "Date création"
    }
    
    FACTURES {
        uuid id PK "Clé primaire"
        string numero_facture UK "N° unique"
        uuid devis_id FK "Devis associé"
        date date_facture "Date émission"
        date date_echeance "Date échéance paiement"
        decimal montant_ttc "Montant TTC"
        enum statut_paiement "en_attente | partiel | paye | retard"
        enum moyen_paiement "virement | cheque | espece"
        timestamp date_paiement "Date paiement effectif"
        string justificatif_url "URL justificatif"
        text notes "Notes"
    }
    
    CHANTIERS {
        uuid id PK "Clé primaire"
        uuid devis_id FK "Devis associé"
        date date_pose_prevue "Date prévue"
        date date_pose_effective "Date réelle"
        string adresse_cimetiere "Adresse complète"
        string section_carre "Section/carré"
        string numero_concession "N° concession"
        array photos_avant "URLs photos avant"
        array photos_apres "URLs photos après"
        string bon_livraison_signe_url "Bon signé"
        string attestation_pose_url "Attestation pose"
        enum statut "planifie | en_cours | termine | litige"
        text commentaires "Commentaires"
    }
    
    LOGS_AUDIT {
        uuid id PK "Clé primaire"
        string table_concernee "Table modifiée"
        uuid enregistrement_id "ID enregistrement"
        enum type_action "creation | modification | suppression"
        jsonb champs_modifies "Changements détaillés"
        uuid utilisateur_id FK "Utilisateur auteur"
        timestamp date_action "Date/heure action"
        string ip_address "IP source"
    }
    
    %% Définition des relations
    
    UTILISATEURS_SYSTEME ||--o{ LOTS_MARBLE : "crée (1:N)"
    UTILISATEURS_SYSTEME ||--o{ DEVIS : "crée (1:N)"
    UTILISATEURS_SYSTEME ||--o{ LOGS_AUDIT : "génère (1:N)"
    
    LOTS_MARBRE ||--o{ DEVIS : "utilisé dans (1:N)"
    CLIENTS ||--o{ DEVIS : "demande (1:N)"
    DEVIS ||--o| FACTURES : "génère (1:1)"
    DEVIS ||--o| CHANTIERS : "donne lieu à (1:1)"