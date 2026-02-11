-- ============================================
-- MIGRATION 001 : Schéma initial
-- Système de Traçabilité Marbrerie Funéraire
-- ============================================

-- Extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. TABLE UTILISATEURS SYSTÈME
-- ============================================
CREATE TABLE utilisateurs_systeme (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin_france', 
'importateur_tunisie', 'commercial')),
    nom VARCHAR(255) NOT NULL,
    telephone VARCHAR(20),
    est_actif BOOLEAN DEFAULT true,
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 2. TABLE LOTS MARBRE (CŒUR DU SYSTÈME)
-- ============================================
CREATE TABLE lots_marbre (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference_interne VARCHAR(50) UNIQUE NOT NULL,
    origine_carriere VARCHAR(255) NOT NULL,
    date_extraction DATE,
    date_importation DATE NOT NULL,
    numero_declaration_douane VARCHAR(100),
    montant_frais_douane DECIMAL(10,2),
    poids_kg DECIMAL(10,2),
    dimensions_cm VARCHAR(50),
    type_marbre VARCHAR(100) NOT NULL,
    qualite VARCHAR(10) CHECK (qualite IN ('A', 'B', 'C')),
    test_resistance_mpa DECIMAL(6,2),
    photos_lot TEXT[],
    document_certificat_origine TEXT,
    document_douane TEXT,
    localisation_entrepot VARCHAR(255),
    statut VARCHAR(50) NOT NULL DEFAULT 'en_transit' CHECK (statut IN 
('en_transit', 'en_stock', 'reserve', 'vendu', 'pose')),
    prix_coutant_total DECIMAL(10,2) NOT NULL,
    marge_souhaitee_pct DECIMAL(5,2),
    prix_vente_conseille DECIMAL(10,2),
    cree_par UUID NOT NULL REFERENCES utilisateurs_systeme(id),
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT
);

-- ============================================
-- 3. TABLE CLIENTS
-- ============================================
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_client VARCHAR(50) NOT NULL CHECK (type_client IN 
('pompe_funebre', 'particulier', 'entreprise')),
    nom_enseigne VARCHAR(255) NOT NULL,
    siret VARCHAR(14),
    numero_habilitation_prefecture VARCHAR(100),
    adresse TEXT,
    code_postal VARCHAR(10),
    ville VARCHAR(100),
    contact_nom VARCHAR(255),
    contact_telephone VARCHAR(20),
    contact_email VARCHAR(255),
    est_actif BOOLEAN DEFAULT true,
    cree_le TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes_diverses TEXT
);

-- ============================================
-- 4. TABLE DEVIS (Conforme arrêté 23/08/2010)
-- ============================================
CREATE TABLE devis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    numero_devis VARCHAR(50) UNIQUE NOT NULL,
    date_devis DATE NOT NULL DEFAULT CURRENT_DATE,
    date_validite DATE NOT NULL,
    client_id UUID NOT NULL REFERENCES clients(id),
    lot_id UUID REFERENCES lots_marbre(id),
    type_prestation VARCHAR(50) NOT NULL CHECK (type_prestation IN 
('fourniture', 'pose', 'renovation', 'complet')),
    description_travaux TEXT,
    prix_ht_fourniture DECIMAL(10,2) DEFAULT 0,
    prix_ht_main_oeuvre DECIMAL(10,2) DEFAULT 0,
    prix_ht_transport DECIMAL(10,2) DEFAULT 0,
    remise_eventuelle DECIMAL(10,2) DEFAULT 0,
    total_ht DECIMAL(10,2) NOT NULL,
    tva_taux DECIMAL(5,2) DEFAULT 20.00,
    total_ttc DECIMAL(10,2) NOT NULL,
    cimetiere_nom VARCHAR(255),
    concession_duree VARCHAR(50),
    reglement_cimetiere_respecte BOOLEAN DEFAULT false,
    attestation_conformite_generee BOOLEAN DEFAULT false,
    statut VARCHAR(50) NOT NULL DEFAULT 'brouillon' CHECK (statut IN 
('brouillon', 'envoye', 'accepte', 'refuse', 'facture')),
    date_acceptation TIMESTAMP WITH TIME ZONE,
    document_pdf_url TEXT,
    envoye_par_email BOOLEAN DEFAULT false,
    cree_par UUID NOT NULL REFERENCES utilisateurs_systeme(id),
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 5. TABLE FACTURES
-- ============================================
CREATE TABLE factures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    numero_facture VARCHAR(50) UNIQUE NOT NULL,
    devis_id UUID NOT NULL REFERENCES devis(id),
    date_facture DATE NOT NULL DEFAULT CURRENT_DATE,
    date_echeance DATE,
    montant_ttc DECIMAL(10,2) NOT NULL,
    statut_paiement VARCHAR(50) DEFAULT 'en_attente' CHECK 
(statut_paiement IN ('en_attente', 'partiel', 'paye', 'retard')),
    moyen_paiement VARCHAR(50) CHECK (moyen_paiement IN ('virement', 
'cheque', 'espece')),
    date_paiement TIMESTAMP WITH TIME ZONE,
    justificatif_url TEXT,
    notes TEXT
);

-- ============================================
-- 6. TABLE CHANTIERS
-- ============================================
CREATE TABLE chantiers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    devis_id UUID NOT NULL REFERENCES devis(id),
    date_pose_prevue DATE,
    date_pose_effective DATE,
    adresse_cimetiere TEXT,
    section_carre VARCHAR(100),
    numero_concession VARCHAR(100),
    photos_avant TEXT[],
    photos_apres TEXT[],
    bon_livraison_signe_url TEXT,
    attestation_pose_url TEXT,
    statut VARCHAR(50) DEFAULT 'planifie' CHECK (statut IN ('planifie', 
'en_cours', 'termine', 'litige')),
    commentaires TEXT
);

-- ============================================
-- 7. TABLE LOGS AUDIT (Traçabilité)
-- ============================================
CREATE TABLE logs_audit (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_concernee VARCHAR(100) NOT NULL,
    enregistrement_id UUID NOT NULL,
    type_action VARCHAR(50) NOT NULL CHECK (type_action IN ('creation', 
'modification', 'suppression')),
    champs_modifies JSONB,
    utilisateur_id UUID NOT NULL REFERENCES utilisateurs_systeme(id),
    date_action TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_address INET
);

-- ============================================
-- INDEX POUR PERFORMANCES
-- ============================================
CREATE INDEX idx_lots_statut ON lots_marbre(statut);
CREATE INDEX idx_lots_type ON lots_marbre(type_marbre);
CREATE INDEX idx_devis_client ON devis(client_id);
CREATE INDEX idx_devis_statut ON devis(statut);
CREATE INDEX idx_factures_statut ON factures(statut_paiement);

-- ============================================
-- FONCTION : Génération référence lot auto
-- ============================================
CREATE OR REPLACE FUNCTION generate_lot_reference()
RETURNS TRIGGER AS $$
DECLARE
    year TEXT;
    next_num INT;
    new_ref TEXT;
BEGIN
    year := EXTRACT(YEAR FROM CURRENT_DATE);
    SELECT COALESCE(MAX(CAST(SUBSTRING(reference_interne FROM 
'TUN-\d{4}-(\d{3})') AS INTEGER)), 0) + 1
    INTO next_num
    FROM lots_marbre
    WHERE reference_interne LIKE 'TUN-' || year || '-%';
    
    new_ref := 'TUN-' || year || '-' || LPAD(next_num::TEXT, 3, '0');
    NEW.reference_interne := new_ref;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_generate_lot_reference
BEFORE INSERT ON lots_marbre
FOR EACH ROW
EXECUTE FUNCTION generate_lot_reference();

-- ============================================
-- FONCTION : Génération numéro devis auto
-- ============================================
CREATE OR REPLACE FUNCTION generate_devis_number()
RETURNS TRIGGER AS $$
DECLARE
    year TEXT;
    next_num INT;
    new_num TEXT;
BEGIN
    year := EXTRACT(YEAR FROM CURRENT_DATE);
    SELECT COALESCE(MAX(CAST(SUBSTRING(numero_devis FROM 
'D-\d{4}-(\d{4})') AS INTEGER)), 0) + 1
    INTO next_num
    FROM devis
    WHERE numero_devis LIKE 'D-' || year || '-%';
    
    new_num := 'D-' || year || '-' || LPAD(next_num::TEXT, 4, '0');
    NEW.numero_devis := new_num;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_generate_devis_number
BEFORE INSERT ON devis
FOR EACH ROW
EXECUTE FUNCTION generate_devis_number();

-- ============================================
-- ROW LEVEL SECURITY (RLS) - Sécurité
-- ============================================

-- Activer RLS sur toutes les tables
ALTER TABLE lots_marbre ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE devis ENABLE ROW LEVEL SECURITY;
ALTER TABLE factures ENABLE ROW LEVEL SECURITY;
ALTER TABLE chantiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE logs_audit ENABLE ROW LEVEL SECURITY;

-- Politiques de base (à affiner selon vos besoins exacts)
CREATE POLICY "Enable all for authenticated" ON lots_marbre
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all for authenticated" ON clients
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all for authenticated" ON devis
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all for authenticated" ON factures
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all for authenticated" ON chantiers
    FOR ALL USING (auth.role() = 'authenticated');

-- Logs audit : seul l'admin peut tout voir, les users voient leurs 
actions
CREATE POLICY "Users see own logs" ON logs_audit
    FOR SELECT USING (utilisateur_id = auth.uid());

-- ============================================
-- DONNÉES DE TEST (Optionnel - à supprimer en prod)
-- ============================================
INSERT INTO utilisateurs_systeme (email, role, nom, telephone) VALUES
('vous@example.com', 'admin_france', 'Admin France', '06 12 34 56 78'),
('oncle@example.com', 'importateur_tunisie', 'Importateur Tunisie', '+216 
12 345 678');

INSERT INTO clients (type_client, nom_enseigne, siret, contact_nom, 
contact_email, ville) VALUES
('pompe_funebre', 'Pompes Funèbres Dupont', '12345678900012', 'Jean 
Dupont', 'contact@dupont.fr', 'Paris'),
('particulier', 'Famille Martin', NULL, 'Marie Martin', 
'marie.martin@email.com', 'Lyon');
