SET TERM ^ ;
set sql dialect 3^
/* **************************************************************************************************************** */
/* TODO refaire un tour de tous les .sql avant la mise en prod*/


/* **************************************************************************************************************** */
/* ************************************************** Exceptions ************************************************** */
/* **************************************************************************************************************** */

create exception exp_nev_couverture_client 'Client inexistant/supprimé/purgé'^

create exception exp_nev_couv_amo_incoh 'Couverture AMO associé à un organisme AMC'^

create exception exp_nev_couv_amc_incoh 'Couverture AMC associé à un organisme AMO'^

create exception exp_nev_client_non_trouve 'Client non trouvé'^

create exception exp_nev_fou_cat_non_trouve 'Fournisseur associé au catalogue introuvable'^

/* **************************************************************************************************************** */
/* ************************************************** Praticiens ************************************************** */
/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_praticien(
  APraticienID integer,
  ANomPrenom varchar(20),
  ANoFiness varchar(9),
  ASpecialite integer,
  ARPPS varchar(11),
  avoie1 varchar(50),
  avoie2 varchar(50),
  acommentaireadresse varchar(50),
  aville varchar(50),
  acodepostal varchar(10),
  atelephone varchar(50),
  cacomplement_1 varchar(50),
  cacomplement_2 varchar(50),
  cacomplement_3 varchar(50),
  cacomplement_4 varchar(50)
 )
as
declare variable strPraticienID varchar(50)^
declare variable strNom varchar(20)^
declare variable strPrenom varchar(20)^
declare variable intSpecialite integer^
declare variable strNoFiness varchar(9)^
declare variable strNJF varchar(50)^
declare variable IDHopital varchar(50)^
declare variable strCommentaireFiness varchar(50)^
begin
  execute procedure ps_separer_nom_prenom(:ANomPrenom, ' ') returning_values :StrNom, :StrPrenom, :strNJF^
  execute procedure ps_renvoyer_id_specialite(:ASpecialite) returning_values :intSpecialite^
  strNoFiness = iif(trim(:ANoFiness) = '', '0', trim(:ANoFiness))^
  strPraticienID = cast(APraticienID as varchar(50))^
  

  -- pas de RPPS + un finess d'hopital => creation d'un hopital 
  if ((substring(:strNoFiness from 3 for 1) = '0')) then
  begin
    -- si finees pas dans la base c'est peut etre une erreur   
    if (not(exists(select * from T_REF_HOPITAL where NUMERO_FINESS = trim(:strNoFiness)))) then
      strCommentaireFiness = 'Vérifier / Corriger Numéro FINESS'^
        -- creation si n existe pas 
    if (not(exists(select * from T_HOPITAL where NO_FINESS = trim(:strNoFiness)))) then
      insert into t_hopital (t_hopital_id,
                             nom,
                             rue_1,
                             rue_2,
                             code_postal,
                             nom_ville,
                             no_finess,
                             tel_standard,
                             commentaire)
      values (:strPraticienID,
              :ANomPrenom,
              trim(:avoie1),
              trim(:avoie2),
              :ACodePostal,
              :AVille,
              :strNoFiness,
              :ATelephone,
              coalesce(:strCommentaireFiness,:acommentaireadresse))^  

  end

    -- si RPPS + finess d'hopital => praticien hospitalier     
  if ((substring(:strNoFiness from 3 for 1) = '0') and (trim(:ARPPS) > '')) then
  begin
    select t_hopital_id from T_HOPITAL where NO_FINESS = trim(:strNoFiness)
    into :IDHopital^

   update or insert into t_praticien(t_praticien_id,
                                    type_praticien,
                                    nom,
                                    prenom,
                                    rue_1,
                                    rue_2,
                                    code_postal,
                                    nom_ville,
                                    tel_standard,
                                    t_ref_specialite_id,
                                    no_finess,
                                    num_rpps,
                                    commentaire,
                                    t_hopital_id)
  values(:strPraticienID,
         '2',
         :strNom,
         :strPrenom,
         :avoie1,
         :avoie2,
         :acodepostal,
         :aville,
         :atelephone,
         :intSpecialite,
         :strNoFiness,
         trim(:ARPPS),
         substring(trim(:acommentaireadresse)||' '||
                   trim(:cacomplement_1)||' '||
                   trim(:cacomplement_2)||' '||
                   trim(:cacomplement_3)||' '||
                   trim(:cacomplement_4) from 1 for 200),
         :IDHopital)^
  end

 -- si pas finess d'hopital => praticien privé     
  if (substring(:strNoFiness from 3 for 1) <> '0') then
   update or insert into t_praticien(t_praticien_id,
                                    type_praticien,
                                    nom,
                                    prenom,
                                    rue_1,
                                    rue_2,
                                    code_postal,
                                    nom_ville,
                                    tel_standard,
                                    t_ref_specialite_id,
                                    no_finess,
                                    num_rpps,
                                    commentaire)
  values(:strPraticienID,
         '1',
         :strNom,
         :strPrenom,
         :avoie1,
         :avoie2,
         :acodepostal,
         :aville,
         :atelephone,
         :intSpecialite,
         :strNoFiness,
         trim(:ARPPS),
         substring(trim(:acommentaireadresse)||' '||
                   trim(:cacomplement_1)||' '||
                   trim(:cacomplement_2)||' '||
                   trim(:cacomplement_3)||' '||
                   trim(:cacomplement_4) from 1 for 200))^
end^

/* **************************************************************************************************************** */
/* ************************************************** Organismes ************************************************** */
/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_destinataire(
  ADestinataireID float,
  ANom varchar(25),
  ARue1 varchar(25),
  ARue2 varchar(25),
  ACodePostal char(5),
  ANomVille varchar(25),
  ATelephone varchar(15),
  AFax varchar(15),
  AAdresseSMTP varchar(30),
  AAdressePOP varchar(30),
  ACommentaire varchar(105)
 )
as
declare variable strDestinataireID varchar(50)^
declare variable strCommentaire varchar(100)^
begin
  --TODO : requete à faire quand on aura trouvé un base nev qui possede afzdes 

  strCommentaire = substring(trim(:ACommentaire) from 1 for 100)^

  strDestinataireID = cast(ADestinataireID as varchar(50))^
  update or insert into t_destinataire(t_destinataire_id,
                                       nom,
                                       rue_1,
                                       rue_2,
                                       code_postal,
                                       nom_ville,
                                       tel_standard,
                                       fax,
                                       serv_smtp,
                                       serv_pop3,
                                       commentaire)
  values(:strDestinataireID,
         trim(:ANom),
         trim(:ARue1),
         trim(:ARue2),
         :ACodePostal,
         trim(:ANomVille),
         trim(:ATelephone),
         trim(:AFax),
         trim(:AAdresseSMTP),
         trim(:AAdressePOP),
         :strCommentaire
        )^
end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_organisme(
  ATypeOrganisme integer,
  AOrganisme1ID integer,
  AOrganisme2ID integer,
  ADestinataireID float,
  ANom varchar(20),
  ARegime char(2),
  ACaisse char(3),
  AIdentifiantNational varchar(16),
  AOrganismeSantePharma char(1),
  ACMU char(1),
  avoie1 varchar(50),
  avoie2 varchar(50),
  acommentaireadresse varchar(50),
  aville varchar(50),
  acodepostal varchar(10),
  atelephone varchar(50),
  cacomplement_1 varchar(16),
  cacomplement_2 varchar(16),
  cacomplement_3 varchar(16),
  cacomplement_4 varchar(16)
 )
as

declare variable intIDRegime integer^
declare variable strOrganismeID varchar(50)^
declare variable strIdentifiantNational varchar(9)^
declare variable chSansCentreGestionnaire char(1)^
begin
  if ((ADestinataireID = '0') or
      (not (exists (select *
                    from t_destinataire
                    where t_destinataire_id = :ADestinataireID)))) then
    ADestinataireID = null ^

  strOrganismeID = :AOrganisme1ID || '_' || :AOrganisme2ID^
  strIdentifiantNational = substring(:AIdentifiantNational from 1 for 9)^

  if (ATypeOrganisme = '1') then
  begin
    select t_ref_regime_id,
           sans_centre_gestionnaire
    from t_ref_regime
    where code = :ARegime
    into :intIDRegime,
         :chSansCentreGestionnaire^

    if (row_count = 0) then
      intIDRegime = null^

    update or insert into t_organisme(type_organisme,
                                      t_organisme_id,
                                      nom,
                                      nom_reduit,
                                      type_releve,
                                      t_destinataire_id,
                                      t_ref_regime_id,
                                      caisse_gestionnaire,
                                      centre_gestionnaire,
                                      application_mt_mini_pc,
                                      rue_1,
                                      rue_2,
                                      code_postal,
                                      nom_ville,
                                      tel_personnel,
                                      commentaire)
    values('1',
          :strOrganismeID,
          trim(:ANom),
          :strOrganismeID,
          '0',
          :ADestinataireID,
          :intIDRegime,
          :ACaisse,
          :AOrganisme2ID, --substring(:AIdentifiantNational from 6 for 4),
          '0',
          :avoie1,
          :avoie2,
          :acodepostal,
          :aville,
          :atelephone,
          :acommentaireadresse||' '||trim(:cacomplement_1)||' '||trim(:cacomplement_2)||' '||trim(:cacomplement_3)||' '||trim(:cacomplement_4)
         )^
    end
  else
  begin
    update or insert into t_organisme(type_organisme,
                                      t_organisme_id,
                                      nom,
                                      nom_reduit,
                                      t_destinataire_id,
                                      type_releve,
                                      identifiant_national,
                                      application_mt_mini_pc,
                                      org_sante_pharma,
                                      rue_1,
                                      rue_2,
                                      code_postal,
                                      nom_ville,
                                      tel_personnel,
                                      commentaire)
    values('2',
          :strOrganismeID,
          trim(:ANom),
          :strOrganismeID,
          :ADestinataireID,
          '0',
          :strIdentifiantNational,
          '0',
          :AOrganismeSantePharma,
          :avoie1,
          :avoie2,
          :acodepostal,
          :aville,
          :atelephone,
          :acommentaireadresse||' '||trim(:cacomplement_1)||' '||trim(:cacomplement_2)||' '||trim(:cacomplement_3)||' '||trim(:cacomplement_4)
         )^
  end
end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_taux(
  ACouvertureAMOID integer,
  ACouvertureAMCID integer,
  APrestation varchar(3),
  ATaux numeric(10,2))
as
declare variable intPrestationID integer^
begin
  execute procedure ps_renvoyer_id_prestation(:APrestation) returning_values :intPrestationID^

  insert into t_taux_prise_en_charge(t_taux_prise_en_charge_id,
                                     t_couverture_amo_id,
                                     t_couverture_amc_id,
                                     t_ref_prestation_id,
                                     taux)
  values(gen_id(seq_taux_prise_en_charge, 1),
         :ACouvertureAMOID,
         :ACouvertureAMCID,
         :intPrestationID,
         :ATaux)^
end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_contrat(
  AContratTypeID integer,
  ALibelle varchar(30),
  ATauxPH1 numeric(10,2),
  ATauxPH7 numeric(10,2),
  ATauxPH4 numeric(10,2),
  ATauxPH2 numeric(10,2),
  ATauxLPP numeric(10,2),
  ANatureAssurance numeric(2),
  AJustificatifExo varchar(2),
  ATypeContrat integer,
  AMode integer)
as
declare variable lFormule char(3)^
declare variable strCouvertureID varchar(50)^
begin
  strCouvertureID = cast(AContratTypeID as varchar(50))^
  if (ATypeContrat = 1) then
  begin
   -- ------------------- couvertures AMO ---------------------- 
    update or insert into t_couverture_amo(t_couverture_amo_id,
                                           ald,
                                           libelle,
                                           nature_assurance,
                                           justificatif_exo)
    values(:strCouvertureID,
           '0',
           :ALibelle,
           :ANatureAssurance,
           :AJustificatifExo)
    returning old.t_couverture_amo_id into :strCouvertureID^

    if (strCouvertureID is not null) then
      delete from t_taux_prise_en_charge where t_couverture_amo_id = :strCouvertureID^
    else
      strCouvertureID = cast(AContratTypeID as varchar(50))^

    execute procedure ps_nev_creer_taux(:strCouvertureID, null, 'PH1', :ATauxPH1)^
    execute procedure ps_nev_creer_taux(:strCouvertureID, null, 'PH4', :ATauxPH4)^
    execute procedure ps_nev_creer_taux(:strCouvertureID, null, 'PH7', :ATauxPH7)^
    execute procedure ps_nev_creer_taux(:strCouvertureID, null, 'PH2', :ATauxPH2)^
    execute procedure ps_nev_creer_taux(:strCouvertureID, null, 'ADD', :ATauxLPP)^
    execute procedure ps_nev_creer_taux(:strCouvertureID, null, 'PMR', :ATauxPH7)^
  end
  else
  begin
  -- ------------------- couvertures AMC ---------------------- 
    if ((ATauxPH1 = 0) and (AMode = 3)) then
      ATauxPH1 = ATauxPH4^

    -- Mode 1 = AMC seul , 
    -- Mode 2 = AMC seul par formule (taux recalculée dans la requete d extraction) 
    -- Mode 3 = AMO incluse
    if (Amode = 3) then 
      lFormule ='02A'^ 
    else
      lFormule = '021'^

    update or insert into t_couverture_amc(t_couverture_amc_id,
                                           libelle,
                                           montant_franchise,
                                           plafond_prise_en_charge,
                                           formule)
    values(:strCouvertureID,
           :ALibelle,
           0,
           0,
           :lFormule)
    returning old.t_couverture_amc_id into :strCouvertureID^

    if (strCouvertureID is not null) then
      delete from t_taux_prise_en_charge where t_couverture_amc_id = :strCouvertureID^
    else
      strCouvertureID = cast(AContratTypeID as varchar(50))^

    execute procedure ps_nev_creer_taux(null, :AContratTypeID, 'PH1', :ATauxPH1)^
    execute procedure ps_nev_creer_taux(null, :AContratTypeID, 'PH4', :ATauxPH4)^
    execute procedure ps_nev_creer_taux(null, :AContratTypeID, 'PH7', :ATauxPH7)^
    execute procedure ps_nev_creer_taux(null, :AContratTypeID, 'PH2', :ATauxPH2)^
    execute procedure ps_nev_creer_taux(null, :AContratTypeID, 'AAD', :ATauxLPP)^
    execute procedure ps_nev_creer_taux(null, :AContratTypeID, 'PMR', :ATauxPH7)^  
  end
end^

/* **************************************************************************************************************** */
/* ************************************************** Clients ***************************************************** */
/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_client(
  AClientID integer,
  ATypeClient char(1),
  AIDCollectivite integer,
  ANumeroInsee varchar(15),
  ANom varchar(20),
  APrenom varchar(15),
  ANomJeuneFille varchar(20),
  ADateNaissance varchar(10),
  AQualite integer,
  ARangGemellaire integer,
  ACommentaireGlobal1 varchar(20),
  ACommentaireGlobal2 varchar(20),
  ADateDerniereVisite date,
  AGenre char(1),
  ADateCreation date,
  avoie1 varchar(50),
  avoie2 varchar(50),
  acommentaireadresse varchar(50),
  aville varchar(50),
  acodepostal varchar(10),
  atelephone varchar(15),
  atelperso varchar(15),
  atelmobile varchar(15),
  aemail varchar(60),
  cacomplement_1 varchar(16),
  cacomplement_2 varchar(16),
  cacomplement_3 varchar(16),
  cacomplement_4 varchar(16),
  commentaire varchar(2000),
  ATypeCommentaire integer
 )
as
declare variable strClientID varchar(50)^
declare variable lStrDateNaissance varchar(8)^
declare variable lStrQualite varchar(2)^
declare variable strCommentaireG varchar(200)^
begin
  if (ADateNaissance is not null) then
  begin
    lStrDateNaissance = replace(cast(ADateNaissance as varchar(10)), '-', '')^
    lStrDateNaissance = substring(lStrDateNaissance from 7 for 2) ||
                        substring(lStrDateNaissance from 5 for 2) ||
                        substring(lStrDateNaissance from 1 for 4)^
  end
  else
    lStrDateNaissance = null^

  if (ANumeroInsee <> '') then
    if (AQualite = '1') then
      lStrQualite = '0'^
    else
      if (AQualite = '2') then
        lStrQualite = '2'^
      else
        lStrQualite = '6'^
  else
    lStrQualite = '0'^

  strClientID = cast(AClientID as varchar(50))^

  -- Commentaire global
  if (trim(ACommentaireGlobal1) = '') then
    strCommentaireG = trim(ACommentaireGlobal2)^
  else
    if (trim(ACommentaireGlobal2) = '') then
      strCommentaireG = trim(ACommentaireGlobal1)^
    else
      strCommentaireG = trim(:ACommentaireGlobal1) || ascii_char(13) || ascii_char(10) || trim(:ACommentaireGlobal2)^
    
  strCommentaireG = substring(trim(:acommentaireadresse)||' '||trim(:cacomplement_1)||' '||trim(:cacomplement_2)||' '||trim(:cacomplement_3)||' '||trim(:cacomplement_4) from 1 for 200) || strCommentaireG^

  insert into t_client(t_client_id,
    numero_insee,
    nom,
    prenom,
    nom_jeune_fille,
    rue_1,
    rue_2,
    code_postal,
    nom_ville,
    tel_personnel,
    tel_standard,
    tel_mobile,
    email,
    commentaire_global,
    date_naissance,
    qualite,
    rang_gemellaire,
    date_derniere_visite,
    genre,
    date_creation)
  values(:strClientID,
    trim(:ANumeroInsee),
    trim(:ANom),
    trim(:APrenom),
    trim(:ANomjeuneFille),
    :avoie1,
    :avoie2,
    :acodepostal,
    :aville,
    trim(:atelephone),
    trim(:atelperso),
    trim(:atelmobile),
    substring(:aemail from 1 for 50),
    :strCommentaireG,
    trim(:lStrDateNaissance),
    :lStrQualite,
    :ARangGemellaire,
    :ADateDerniereVisite,
    iif(:AGenre = 'F', 'F', 'H'),
    :ADateCreation)^

  if (trim(strCommentaireG) > '') then
  insert into t_commentaire (t_commentaire_id,
                             t_entite_id,
                             type_entite,
                             commentaire,
                             est_global)
  values (next value for seq_commentaire,
          :strClientID,
          '0', -- client 
          cast(:strCommentaireG as blob),
          '1' )^

  if (trim(:commentaire) > '') then
  insert into t_commentaire (t_commentaire_id,
                             t_entite_id,
                             type_entite,
                             commentaire,
                             est_global)
  values (next value for seq_commentaire,
          :strClientID,
          '0', -- client 
          cast(:commentaire as blob),
           iif(:ATypeCommentaire = 0, '0','1')  )^

  -- Création du compte client
  if ((ATypeClient = 'C') and ((AQualite = 0) or ((AQualite <> 0) and (AClientID = AIDCollectivite)))) then
  begin
    insert into t_compte(t_compte_id,
                         nom)
    values(:AClientID,
           substring(trim(:ANom) || ' ' || trim(:APrenom) from 1 for 30))^

    insert into t_compte_client
    values(next value for seq_compte_client, :AClientID, :AClientID)^
  end

end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_client_liaison(
  AIDCollectivite integer,
  AIDClient integer)
as
begin
  insert into t_compte_client(t_compte_client_id,
                              t_compte_id,
                              t_client_id)
  values(next value for seq_compte_client,
         :AIDCollectivite,
         :AIDClient)^
end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_couv_amo(
  AOrganismeAMOID varchar(50),
  AContratTypeID integer)
as
declare variable strCouvertureRefID varchar(50)^
declare variable strCouvertureID varchar(50)^
begin
  strCouvertureRefID = cast(:AContratTypeID as varchar(50))^
  if (exists(select *
             from t_couverture_amo
             where t_couverture_amo_id = :strCouvertureRefID)) then
  begin
    strCouvertureID = AOrganismeAMOID || '_' || strCouvertureRefID^
    if (not (exists(select *
                    from t_couverture_amo
                    where t_couverture_amo_id = :strCouvertureID))) then
    begin
      insert into t_couverture_amo(t_couverture_amo_id,
                                   t_organisme_amo_id,
                                   ald,
                                   libelle,
                                   nature_assurance,
                                   justificatif_exo)
      select :strCouvertureID,
             :AOrganismeAMOID,
             ald,
             libelle,
             nature_assurance,
             justificatif_exo
      from t_couverture_amo
      where t_couverture_amo_id = :strCouvertureRefID^

      insert into t_taux_prise_en_charge(t_taux_prise_en_charge_id,
                                         t_couverture_amo_id,
                                         t_couverture_amc_id,
                                         t_ref_prestation_id,
                                         taux)
      select next value for seq_taux_prise_en_charge,
             :strCouvertureID,
             null,
             t_ref_prestation_id,
             taux
      from t_taux_prise_en_charge
      where t_couverture_amo_id = :strCouvertureRefID^
    end
  end
  else
    exception exp_nev_couv_amo_incoh^
end^


/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_couv_amc(
  AOrganismeAMCID varchar(50),
  AContratTypeID integer)
as
declare variable strCouvertureRefID varchar(50)^
declare variable strCouvertureID varchar(50)^
begin
  strCouvertureRefID = cast(:AContratTypeID as varchar(50))^
  if (exists(select *
             from t_couverture_amc
             where t_couverture_amc_id = :strCouvertureRefID)) then
  begin
    strCouvertureID = :AOrganismeAMCID || '_' || :strCouvertureRefID^
    if (not (exists(select *
                    from t_couverture_amc
                    where t_couverture_amc_id = :strCouvertureID))) then
    begin
      insert into t_couverture_amc(t_couverture_amc_id,
                                   t_organisme_amc_id,
                                   libelle,
                                   montant_franchise,
                                   plafond_prise_en_charge,
                                   formule)
      select :strCouvertureID,
             :AOrganismeAMCID,
             libelle,
             montant_franchise,
             plafond_prise_en_charge,
             formule
      from t_couverture_amc
      where t_couverture_amc_id = :strCouvertureRefID^


      insert into t_taux_prise_en_charge(t_taux_prise_en_charge_id,
                                         t_couverture_amo_id,
                                         t_couverture_amc_id,
                                         t_ref_prestation_id,
                                         taux)
      select next value for seq_taux_prise_en_charge,
             null,
             :strCouvertureID,
             t_ref_prestation_id,
             taux
      from t_taux_prise_en_charge
      where t_couverture_amc_id = :strCouvertureRefID^
    end 
  end
  else
    exception exp_nev_couv_amc_incoh^
end^

/* ********************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_client_contrat(
  AClientID integer,
  ANoContrat integer, --inutilisé
  AAssureID integer,  --inutilisé
  AOrganismeAMOID integer,
  ACentreId integer,
  AContratTypeID integer,
  ANumeroAdherent varchar(16),
  AReference varchar(11),  --inutilisé
  AContratSantePharma varchar(18), --non repris en bd
  ADebutDroit date,
  AFinDroit date)
as
declare variable strClientID varchar(50)^
declare variable strOrganismeID varchar(50)^
declare variable chTypeOrganisme char(1)^
declare variable strIdentifiantNational varchar(9)^
begin
  strClientID = cast(AClientID as varchar(50))^
  if (exists(select *
             from t_client
             where t_client_id = :strClientID)) then
  begin
    strOrganismeID = cast(:AOrganismeAMOID || '_' || :ACentreId as varchar(50))^
    select type_organisme,
           t_organisme_id,
           identifiant_national
    from t_organisme
    where t_organisme_id = :strOrganismeID
    into :chTypeOrganisme,
         :strOrganismeID,
         :strIdentifiantNational^

    if (row_count = 1) then
    begin
      if (chTypeOrganisme = '1') then
      begin
        execute procedure ps_nev_creer_couv_amo(:strOrganismeID, :AContratTypeID)^

        update t_client
        set t_organisme_amo_id = :strOrganismeID,
            centre_gestionnaire = iif(:ACentreId = 0, '', lpad(:ACentreId, 4, '0'))
        where t_client_id = :strClientID^

        insert into t_couverture_amo_client(t_couverture_amo_client_id,
                                            t_client_id,
                                            t_couverture_amo_id,
                                            fin_droit_amo)
        values(next value for seq_couverture_amo_client,
               :strClientID,
               :strOrganismeID || '_' || :AContratTypeID,
               :AFinDroit)^
      end
      else
      begin
        execute procedure ps_nev_creer_couv_amc(:strOrganismeID, AContratTypeID)^
  --select iif(identifiant_national='99999997'or identifiant_national='27000000','1','2') from t_organisme where t_organisme_id = :strOrganismeID into :chModeGestion^
    
        update t_client
        set t_organisme_amc_id = :strOrganismeID,
            t_couverture_amc_id = :strOrganismeID || '_' || :AContratTypeID,
            debut_droit_amc = :ADebutDroit,
            fin_droit_amc = :AFinDroit,
            numero_adherent_mutuelle = trim(:ANumeroAdherent),
            contrat_sante_pharma = :AContratSantePharma
        where t_client_id = :strClientID
          and (fin_droit_amc < :AFinDroit or fin_droit_amc is null)^
      end
    end
  end
  else
    exception exp_nev_couverture_client^
end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_maj_org_client(
  ANumeroInsee varchar(15),
  ARegime integer,
  ACaisseGestionnaire integer,
  ACentreGestionnaire integer)
as
declare variable lIntRegimeID integer^
declare variable lStrRegime varchar(2)^
declare variable lStrCaisseGestionnaire varchar(3)^
declare variable lStrCentreGestionnaire varchar(4)^
declare variable lStrOrganismeAMOID varchar(50)^
begin
  lStrRegime = lpad(:ARegime, 2, '0')^
  lStrCaisseGestionnaire = lpad(:ACaisseGestionnaire, 3, '0')^
  lStrCentreGestionnaire = lpad(:ACentreGestionnaire, 4, '0')^

  select t_ref_regime_id
  from t_ref_regime
  where code = :lStrRegime
  into lIntRegimeID^

  select first 1 t_organisme_id
  from t_organisme
  where t_ref_regime_id = :lIntRegimeID
    and caisse_gestionnaire = :lStrCaisseGestionnaire
    and centre_gestionnaire = :lStrCentreGestionnaire
  into :lStrOrganismeAMOID^

  if (row_count = 0) then
    insert into t_organisme (type_organisme,
                             t_organisme_id,
                             t_ref_regime_id,
                             caisse_gestionnaire,
                             centre_gestionnaire,
                             nom,
                             nom_reduit,
                             type_releve,
                             application_mt_mini_pc)
    values ('1',
           'SV_' || :lStrRegime || :lStrCaisseGestionnaire || :lStrCentreGestionnaire,
           :lIntRegimeID,
           :lStrCaisseGestionnaire,
           :lStrCentreGestionnaire,
           'Organisme Sesam Vitale ' || :lStrRegime || :lStrCaisseGestionnaire || :lStrCentreGestionnaire,
           :lStrRegime || :lStrCaisseGestionnaire || :lStrCentreGestionnaire,
           '0',
           '0')
    returning t_organisme_id into :lStrOrganismeAMOID^

  update t_client
  set t_organisme_amo_id = :lStrOrganismeAMOID,
      centre_gestionnaire= :lStrCentreGestionnaire
  where numero_insee = :ANumeroInsee^
end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_maj_couv_client(
  ANumeroInsee varchar(15),
  ADateNaissance varchar(8),
  ARangGemellaire varchar(5),
  AQualite varchar(2),
  ANom varchar(27),
  APrenom varchar(20),
  ACouvertureAMO varchar(5),
  ADebutDroitAMO varchar(8),
  AFinDroitAMO varchar(8))
as
declare variable lStrClientID varchar(50)^
declare variable lStrOrganismeAMOID varchar(50)^
declare variable lStrCouvertureAMOID varchar(50)^
declare variable intCouvertureAMORef integer^
begin

  if (ACouvertureAMO = '00000') then ACouvertureAMO = '00100'^

  if ((ANumeroInsee <> '') and (ACouvertureAMO <> '')) then
  begin
    begin
      select t_client_id,
             t_organisme_amo_id
      from t_client
      where numero_insee = :ANumeroInsee
        and date_naissance = substring(:ADateNaissance from 7 for 2) ||
                             substring(:ADateNaissance from 5 for 2) ||
                             substring(:ADateNaissance from 1 for 4)
        and qualite = cast(:AQualite as integer)
        and rang_gemellaire = cast(:ARangGemellaire as integer)
      into :lStrClientID,
           :lStrOrganismeAMOID^
    when sqlcode -811 do
      exception  exp_nev_client_non_trouve^
    end

    if (lStrOrganismeAMOID is not null) then
    begin
      lStrCouvertureAMOID = cast(:lStrOrganismeAMOID || '_' || :ACouvertureAMO as varchar(50))^
      if (not(exists(select *
                     from t_couverture_amo
                     where t_couverture_amo_id = :lStrCouvertureAMOID))) then
      begin
        select t_ref_couverture_amo_id
        from t_ref_couverture_amo
        where code_couverture = :ACouvertureAMO
        into :intCouvertureAMORef^

        if (row_count = 1) then
        begin
            insert into t_couverture_amo(t_organisme_amo_id,
                                       t_couverture_amo_id,
                                       ald,
                                       libelle,
                                       t_ref_couverture_amo_id)
          values (:lStrOrganismeAMOID,
                  :lStrCouvertureAMOID,
                  substring(:ACouvertureAMO from 1 for 1),
                  'Couverture Sesam Vitale ' || :ACouvertureAMO,
                  :intCouvertureAMORef)^

          insert into t_taux_prise_en_charge(t_taux_prise_en_charge_id,
                                             t_couverture_amo_id,
                                             t_ref_prestation_id,
                                             taux)
          select gen_id(seq_taux_prise_en_charge, 1),
                 :lStrCouvertureAMOID,
                 t.t_ref_prestation_id,
                 t.taux
          from t_ref_taux_prise_en_charge t
               inner join t_ref_couverture_amo c on (c.t_ref_couverture_amo_id = t.t_ref_couverture_amo_id)
          where c.code_couverture = :ACouvertureAMO^
        end
          else
            intCouvertureAMORef = null^
       end
       else
          intCouvertureAMORef = 0^

      if (intCouvertureAMORef is not null) then
          update or insert into t_couverture_amo_client(t_couverture_amo_client_id,
                                                      t_client_id,
                                                      t_couverture_amo_id,
                                                      debut_droit_amo,
                                                      fin_droit_amo)
        values (next value for seq_couverture_amo_client,
                :lStrClientID,
                :lStrCouvertureAMOID,
                iif(:ADebutDroitAMO = '00000000',null,substring(:ADebutDroitAMO from 1 for 4) || '-'|| substring(:ADebutDroitAMO from 5 for 2) || '-'|| substring(:ADebutDroitAMO from 7 for 2)),
                iif(:AFinDroitAMO = '00000000',null,substring(:AFinDroitAMO from 1 for 4) || '-'|| substring(:AFinDroitAMO from 5 for 2) || '-'|| substring(:AFinDroitAMO from 7 for 2))
               )
         matching (t_client_id, t_couverture_amo_id)^
    end
   end
end^

/* **************************************************************************************************************** */
/* ************************************************** Produits **************************************************** */
/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_fournisseur(
  AFournisseurID dm_code,
  ATypeFournisseur char(1),
  ARaisonSociale varchar(25),
  ARepresentant varchar(50),
  ATelephone varchar(20),
  AObservation varchar(50),
  ACommentaire varchar(20),
  AIdentifiantClient varchar(20),
  ANumeroTelephone varchar(20),
  ANorme varchar(3),
  AIdentifiantFournisseur varchar(20),
  ACodeFournisseur varchar(2),
  AUtilisateur varchar(50),
  AMotDePasse varchar(50),
  ACleCryptage varchar(4),
  AURLPrincipale varchar(100),
  AURLSecondaire varchar(100),
  avoie1 varchar(50),
  avoie2 varchar(50),
  acommentaireadresse varchar(50),
  aville varchar(50),
  acodepostal varchar(10),
  atelephone2 varchar(50),
  cacomplement_1 varchar(16),
  cacomplement_2 varchar(16),
  cacomplement_3 varchar(16),
  cacomplement_4 varchar(16),
  commentaire varchar(2000)
 )
as
begin

if (:ACodeFournisseur = '') 
  then ACodeFournisseur = null^ 

if (ATypeFournisseur = 'L') then
begin
  insert into t_fournisseur_direct(t_fournisseur_direct_id,
                                  raison_sociale,
                                  represente_par,
                                  telephone_representant,
                                  commentaire, 
                                  identifiant_171, 
                                  numero_appel,
                                  rue_1,
                                  rue_2,
                                  code_postal,
                                  nom_ville,
                                  tel_personnel
                                 )
  values(:AFournisseurID,
        trim(:ARaisonSociale),
        :Arepresentant,
        :ATelephone,
        substring(trim(:acommentaireadresse)||' '||trim(:AObservation)||' '||trim(:ACommentaire)||' '||trim(:cacomplement_1)||' '||trim(:cacomplement_2)||' '||trim(:cacomplement_3)||' '||trim(:cacomplement_4)||' '||trim(:commentaire) from 1 for 200),
        substring(:AIdentifiantClient from 1 for 8),
        :ANumeroTelephone,
        :avoie1,
        :avoie2,
        :acodepostal,
        :aville,
        :atelephone2
       )^

  --creation aussi en codif 4 pour reprise distributeur
  insert into t_codification(t_codification_id,
                               rang,
                               code,
                               libelle)
  values(next value for seq_codification,
           4,
           :AFournisseurID,
           trim(:ARaisonSociale))^
end

  
if (ATypeFournisseur = 'R' or ATypeFournisseur = 'P') then -- P : répartiteur prioritaire
/* ---------------- REPARTITEUR ---------------*/
  insert into t_repartiteur(t_repartiteur_id,
                            raison_sociale,
                            identifiant_171,
                            numero_appel,
                            commentaire,
                            pharmaml_url_1,
                            pharmaml_url_2,
                            pharmaml_cle,
                            pharmaml_id_officine,
                            pharmaml_id_magasin,
                            pharmaml_ref_id,
                            rue_1,
                            rue_2,
                            code_postal,
                            nom_ville,
                            tel_personnel                           
                          )
  values(:AFournisseurID,
        trim(:ARaisonSociale),
        substring(:AIdentifiantClient from 1 for 8),
        :ANumeroTelephone,
        substring(trim(:acommentaireadresse)||' '||trim(:AObservation)||' '||trim(:ACommentaire)||' '||trim(:commentaire) from 1 for 200),
        :AURLPrincipale, -- in 100 out 150 OK
        :AURLSecondaire, -- in 100 out 150 OK
        :ACleCryptage, -- out dm_varchar4
        :AIdentifiantClient, -- pharmaml_id_officine in varchar(20) out dm_varchar20 OK
        :AIdentifiantFournisseur, --in varchar(20) out dm_varchar20 OK
        :ACodeFournisseur, --in varchar(2) out dm_numeric3
        :avoie1,
        :avoie2,
        :acodepostal,
        :aville,
        :atelephone2
       )^

-- a utiliser quand ça servira
  /*  if (trim(:acommentaireadresse)<>'' or trim(:ACommentaire)<>'') then
      insert into t_commentaire (t_commentaire_id,
                                t_entite_id,
                                type_entite,
                                commentaire,
                                est_global)
      values (next value for seq_commentaire,
              :AFournisseurID,
              '1', 
              cast(trim(:acommentaireadresse)||' '||trim(:AObservation)||' '||trim(:ACommentaire) as blob),
              '0')^
              */
end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_famille(
  ARang char(1),
  AFamilleID varchar(20),
  ALibelle varchar(50))
as
declare variable intCodificationID integer^
declare variable strFamilleID varchar(50)^
begin
  update or insert into t_codification(t_codification_id,
                                       code,
                                       libelle,
                                       rang)
  values(next value for seq_codification,
         trim(:AFamilleID),
         trim(:ALibelle),
         :ARang)
  matching(code, rang)
  returning old.t_codification_id into :intCodificationID^

  --TODO : inuitlisé ?
  -- Particularité Gamme
  --if ((intCodificationID is not null) and (ARang = 3)) then
  --  update t_produit set t_codif_3_id = null where t_codif_3_id = :intCodificationID^
end^

/* -- TODO : reste de alliance, encore utile ?


create
 or alter 
 or alter procedure ps_alliance_creer_produit_gamme(
  AFournisseurID integer,
  AGammeID integer,
  AProduitID integer)
as
declare intGammeID integer^
begin
  execute procedure ps_renvoyer_id_codification(3, cast(:AFournisseurID || '_' || :AGammeID as varchar(50))) returning_values :intGammeID^

  if (intGammeID is not null) then
    update t_produit
    set t_codif_3_id = :intGammeID
    where t_produit_id = cast(:AProduitID as varchar(50))^
  else
    exception exp_alliance_gamme_non_trouve^
end^*/


/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_zone_geo(
  AZoneGeographiqueID varchar(4),
  ALibelle varchar(54))
as
begin
  update or insert into t_zone_geographique(t_zone_geographique_id,
                                  libelle)
  values(:AZoneGeographiqueID,
         substring(:AZoneGeographiqueID || ' - ' || trim(:ALibelle) from 1 for 50))^
end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_produit(
  AProduitID dm_code,
  ACodeCIP7 char(7),
  ACodeCIP7Remplacement char(7),
  ADesignation varchar(34),
  ACode13 char(13),
  AFamilleBCB varchar(5),
  AFamilleInterne varchar(5),
  ALaboratoire integer,
  ADistributeur integer,
  ATypeReappro char(1),
  ARepartiteurExclusifID integer,
  AListe char(1),
  ABaseRemboursement float,
  APrixVente float,
  ATVA smallint,
  APrestation char(3),
  APrixAchat float,
  APAMP float,
  AGestionReserve char(1),
  AGestionAutomate char(1),
  ACodeGestion varchar(2),
  AForcee char(1),
  AZoneGeoRayon varchar(4),
  AZoneGeoReserve varchar(4),
  AStockProtection integer, --inutile stock min calculé
  AStockProtectionForce integer,
  AStockMaxi integer,
  AStockMiniRayon integer,
  AStockMaxiRayon integer,
  AStockRayon integer,
  AStockReserve integer,
  APrixAchatRemise float,
  ADateDerniereVente date,
  ADatePeremption date,
  ACodeTIPSLPP varchar(13),
  ATypeHomeo char(1),
  ACommentaireVente varchar(1000),
  ACommentaireAchat varchar(1000)
 )
as
declare variable lFtTauxTVA numeric(5,2)^
declare variable lIntTVAID integer^
declare variable lIntPrestationID integer^
declare variable lIntFamilleBCB integer^
declare variable lIntFamilleInterne integer^
declare variable lIntDistributeur integer^
declare variable intMarque integer^
declare variable lCodeCIP13 varchar(13)^
declare variable lCodeEAN13 varchar(13)^
declare variable lCodeCIP7 char(7)^
begin

  -- TVA
  if (ATVA = 1) then
    lFtTauxTVA = 2.1^
  else
    if (ATVA = 2) then
      lFtTauxTVA = 5.5^
      else
       if (ATVA = 4) then
         lFtTauxTVA = 20^
    else
       if (ATVA = 5) then
         lFtTauxTVA = 10^
       else
         lFtTauxTVA = '0.0'^

  execute procedure ps_renvoyer_id_tva(lFtTauxTVA) returning_values :lIntTVAID^

  -- Liste
  if (AListe = '') then
    AListe = '0'^
  else
    if (AListe in('1', 'A')) then
      AListe = '1'^
    else
      if (AListe in ('2', 'C')) then
        AListe = '2'^
      else
        if (AListe in ('S', 'B')) then
          AListe = '3'^
        else
          AListe = '0'^

  -- Type Homeo
  if (ATypeHomeo in ('3', '7')) then
   ATypeHomeo = '2'^
 else
    if (ATypeHomeo in ('1', '2', '4', '5', '6', '8', '9')) then
     ATypeHomeo = '1'^
   else
     ATypeHomeo = '0'^

  --  Prestation
  execute procedure ps_renvoyer_id_prestation(APrestation) returning_values :lIntPrestationID^

  -- Marque
  execute procedure ps_renvoyer_id_marque(:ALaboratoire) returning_values :intMarque^

  -- Distributeur
  execute procedure ps_renvoyer_id_codification('4', :ADistributeur) returning_values :lIntDistributeur^

  -- Familles
  execute procedure ps_renvoyer_id_codification('1', trim(:AFamilleBCB)) returning_values :lIntFamilleBCB^
  if (AFamilleInterne = AFamilleBCB) then
    lIntFamilleInterne = null^
  else
    execute procedure ps_renvoyer_id_codification('2', trim(:AFamilleInterne)) returning_values :lIntFamilleInterne^


  lCodeCIP13 = null^
  lCodeEAN13 = null^
  lCodeCip7 = null^

  --Création CIP 
  if (ACode13 similar to '340[01][[:DIGIT:]]{9}') then 
    lCodeCIP13 = :ACode13^ 
  else 
    lCodeEAN13 = :ACode13^

  if (trim(ACodeCIP7Remplacement) > '') then
    lCodeCIP7 = :ACodeCIP7Remplacement^
  else
    lCodeCIP7 = :ACodeCIP7^  

  -- ne reprendre cip7 que si c'est le seul code  
  if ((:lCodeCIP13 is not null) or (:lCodeEAN13 is not null)) then
    lCodeCIP7 = null^  
    
  -- Produit
  insert into t_produit(t_produit_id,
                        code_cip,
                        designation,
                        liste,
                        t_ref_prestation_id,
                        date_derniere_vente,
                        type_homeo,
                        t_codif_1_id,
                        t_codif_2_id,
                        t_codif_4_id,
                        t_codif_6_id,
                        prix_achat_catalogue,
                        prix_vente,
                        base_remboursement,
                        t_ref_tva_id,
                        t_repartiteur_id,
                        prix_achat_remise,
                        pamp,
                        date_peremption,
                        commentaire_commande,
                        commentaire_vente,
                        stock_mini,
                        stock_maxi,
                        profil_gs,
                        calcul_gs)
  values(:AProduitID,
         coalesce(:lCodeCIP13, :lCodeCIP7), 
         :ADesignation,
         :AListe,
         :lIntPrestationID,
         :ADateDerniereVente,
         :ATypeHomeo,
         :lIntFamilleBCB,
         :lIntFamilleInterne,
         :lIntDistributeur,
         :intMarque,
         :APrixAchat,
         :APrixVente,
         :ABaseRemboursement,
         :lIntTVAID,
         iif(:ATypeReappro = 'I', :ARepartiteurExclusifID, null),
         :APrixAchatRemise,
         :APAMP,
         :ADatePeremption,
         substring(:ACommentaireAchat from 1 for 200),
         substring(:ACommentaireVente from 1 for 200),
         :AStockProtectionForce,
         :AStockMaxi,
         iif(:ATypeReappro = '0' or :ATypeReappro = 'E' , '2', '0'),
         iif(:AForcee = 'O' or :ACodeGestion = 'FV' or :ACodeGestion = 'S0', '4', '0'))^

if (:lCodeEAN13 similar to '[[:DIGIT:]]{13}') then
        insert into t_code_ean13 (t_code_ean13_id,
                                  t_produit_id,
                                  code_ean13)
        values (next value for seq_code_ean13,
                :AProduitID,
                trim(:lCodeEAN13))^

end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_produit_geo(
  AProduitID integer,
  AQuantite numeric(5),
  APriorite char(1),
  AStockMini numeric(3),
  AStockMaxi numeric(3),
  AZoneGeographique varchar(50))
as
declare variable t_depot_id dm_code^
begin
  if (APriorite = '1') then
    select t_depot_id from t_depot where libelle ='PHARMACIE' into :t_depot_id ^
  else if (APriorite = '2') then
      select t_depot_id from t_depot where libelle ='AUTOMATE' into :t_depot_id ^
     else
      select t_depot_id from t_depot where libelle ='RESERVE' into :t_depot_id ^

  insert into t_produit_geographique (t_produit_geographique_id,
                                      t_produit_id,
                                      quantite,
                                      t_depot_id,
                                      stock_mini,
                                      stock_maxi,
                                      t_zone_geographique_id)
  values (next value for seq_produit_geographique,
          :AProduitID,
          :AQuantite,
          :t_depot_id,
          :AStockMini,
          :AStockMaxi,
          iif(:AZoneGeographique = '', null, trim(:AZoneGeographique)))^

end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_stock(
  AProduitID dm_code,
  AGestionReserve char(1),
  AGestionAutomate char(1),
  ACodeGestion varchar(2),
  AForcee char(1),
  AZoneGeoRayon varchar(4),
  AZoneGeoReserve varchar(4),
  AStockProtection integer,
  AStockProtectionForce integer,
  AStockMaxi integer,
  AStockMiniRayon integer,
  AStockMaxiRayon integer,
  AStockRayon integer,
  AStockReserve integer
 ) 
as
begin
    -- parametre priorite : 0 = reserve, 2 = automate , 1 = pharmacie
   if ((AGestionAutomate = 'O') OR (AGestionAutomate = 'M')) then
    begin
       if (not(exists(select * from t_depot where libelle  = 'AUTOMATE '))) then
              insert into t_depot values (next value for seq_depot , 'AUTOMATE', '1', 'SUVE')^
      execute procedure ps_nev_creer_produit_geo(:AProduitID, :AStockRayon, '2',  :AStockMiniRayon,  AStockMaxiRayon  , :AZoneGeoRayon)^

    end
    else
      execute procedure ps_nev_creer_produit_geo(:AProduitID, :AStockRayon, '1', iif(:AGestionReserve = 'O', :AStockMiniRayon, iif(:AForcee = 'O', :AStockProtectionForce, :AStockProtection)),  iif(:AGestionReserve = 'O', :AStockMaxiRayon, :AStockMaxi) , :AZoneGeoRayon)^
    if (AGestionReserve = 'O') then
      execute procedure ps_nev_creer_produit_geo(:AProduitID, :AStockReserve, '0', null, null, :AZoneGeoReserve)^
end^   

/* ********************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_produit_code(
  AProduitID dm_code,
  ACode varchar(13),
  p_type integer)
as
declare code_cip_produit varchar(13)^
begin
  
  -- recuperation du code cip du produit pour comparaison
  select code_cip
  from t_produit
  where  t_produit_id = :AProduitID
  into code_cip_produit^

  -- si deja un cip13 de creer_produit mettre a jour avec celui donc le code type = 1
  -- CIP 13
  if (((:ACode similar to '340[01][[:DIGIT:]]{9}') and (p_type = 1)) -- code cip13 prioritaire
  or ((:ACode similar to '340[01][[:DIGIT:]]{9}') and ( coalesce(:code_cip_produit,'') not similar to '340[01][[:DIGIT:]]{9}'))) then -- cip 13 pas deja present ( ecrase un cip 7 ou un cip13 null)  
    update t_produit 
    set code_cip = trim(:ACode) 
    where t_produit_id = :AProduitID^ 
  else
    begin
  
      -- code EAN / GTIN / ACL / codes internes ... mais pas de CIP 13 !!
      if ((trim(:ACode) similar to '[[:DIGIT:]]{13}')  and (trim(:ACode) not similar to '340[01][[:DIGIT:]]{9}') and not(exists(select code_ean13 from t_code_ean13 WHERE code_ean13 = trim(:ACode)))) then
      begin
        insert into t_code_ean13 (t_code_ean13_id,
                    t_produit_id,
                    code_ean13)
        values (next value for seq_code_ean13,
            :AProduitID,
            trim(:ACode))^
      end
      -- si le seul code est un cip 7 le reprendre 
      if ((trim(:ACode) similar to '[[:DIGIT:]]{7}') and (code_cip_produit is null)) then 
      begin
        update t_produit 
        set code_cip = :ACode 
        where t_produit_id = :AProduitID ^
      end
      
      -- si on a un code autre que code interne , cip 7 inutile le faire sauter 
      if ((trim(:ACode) not similar to '20000[[:DIGIT:]]{8}') and (trim(:ACode) not similar to '[[:DIGIT:]]{7}') and (coalesce(trim(:code_cip_produit),'') similar to '[[:DIGIT:]]{7}')) then 
      begin
        update t_produit 
        set code_cip = null 
        where t_produit_id = :AProduitID ^
      end  


     end   
end^
/* ********************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_histo_vente_m(
  AProduitID integer,
  AMois integer,
  AAnnee integer,
  ANombreVendues integer,
  ANombreActes integer)
returns(
  AProchainMois integer,
  AProchaineAnnee integer)
as
begin
  if (ANombreVendues > 0) then
    insert into t_historique_vente(t_historique_vente_id,
                                   t_produit_id,
                                   periode,
                                   quantite_vendues,
                                   quantite_actes)
    values(next value for seq_historique_vente,
           :AProduitID,
           lpad(:AMois, 2, '0') || lpad(:AAnnee, 4, '0'),
           :ANombreVendues,
           iif(:ANombreActes < 0, 1, :ANombreActes))^

  AProchainMois = AMois - 1^
  if (AProchainMois < 1) then
  begin
    AProchainMois = 12^
    AProchaineAnnee = AAnnee - 1^
  end
  else
    AProchaineAnnee = AAnnee^
end^

/* ********************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_histo_vente(
  AProduitID integer,
  ADateDerniereVente date,
  AVendues0 integer,
  AVendues1 integer,
  AVendues2 integer,
  AVendues3 integer,
  AVendues4  integer,
  AVendues5 integer,
  AVendues6 integer,
  AVendues7 integer,
  AVendues8 integer,
  AVendues9 integer,
  AVendues10 integer,
  AVendues11 integer,
  AVendues12 integer,
  AVendues13 integer,
  AVendues14  integer,
  AVendues15 integer,
  AVendues16 integer,
  AVendues17 integer,
  AActes0 integer,
  AActes1 integer,
  AActes2 integer,
  AActes3 integer,
  AActes4  integer,
  AActes5 integer,
  AActes6 integer,
  AActes7 integer,
  AActes8 integer,
  AActes9 integer,
  AActes10 integer,
  AActes11 integer,
  AActes12 integer,
  AActes13 integer,
  AActes14  integer,
  AActes15 integer,
  AActes16 integer,
  AActes17 integer)
as
declare variable strDateDerniereVente varchar(10)^
declare variable intMois integer^
declare variable intAnnee integer^
declare variable flag_depart char(1)^
begin
      -- Historique de ventes
  if (ADateDerniereVente  is not null) then
  begin
    strDateDerniereVente = cast(ADateDerniereVente as varchar(10))^
    intMois = substring(ADateDerniereVente from 6 for 2)^
    intAnnee = substring(ADateDerniereVente from 1 for 4)^

    flag_depart = '0'^

    if (AVendues0>0) then flag_depart = '1'^
    if (flag_depart = '1') then
        execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues0, :AActes0) returning_values :intMois, :intAnnee^
    if (AVendues1>0) then flag_depart = '1'^
    if (flag_depart = '1') then
            execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues1, :AActes1) returning_values :intMois, :intAnnee^
    if (AVendues2>0) then flag_depart = '1'^
    if (flag_depart = '1') then
            execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues2, :AActes2) returning_values :intMois, :intAnnee^
    if (AVendues3>0) then flag_depart = '1'^
    if (flag_depart = '1') then
            execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues3, :AActes3) returning_values :intMois, :intAnnee^
    if (AVendues4>0) then flag_depart = '1'^
    if (flag_depart = '1') then
            execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues4, :AActes4) returning_values :intMois, :intAnnee^
    if (AVendues5>0) then flag_depart = '1'^
    if (flag_depart = '1') then
            execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues5, :AActes5) returning_values :intMois, :intAnnee^
    if (AVendues6>0) then flag_depart = '1'^
    if (flag_depart = '1') then
            execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues6, :AActes6) returning_values :intMois, :intAnnee^
    if (AVendues7>0) then flag_depart = '1'^
    if (flag_depart = '1') then
            execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues7, :AActes7) returning_values :intMois, :intAnnee^
    if (AVendues8>0) then flag_depart = '1'^
    if (flag_depart = '1') then
            execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues8, :AActes8) returning_values :intMois, :intAnnee^
    if (AVendues9>0) then flag_depart = '1'^
    if (flag_depart = '1') then
            execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues9, :AActes9) returning_values :intMois, :intAnnee^
    if (AVendues10>0) then flag_depart = '1'^
    if (flag_depart = '1') then
            execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues10, :AActes10) returning_values :intMois, :intAnnee^
    if (AVendues11>0) then flag_depart = '1'^
    if (flag_depart = '1') then
            execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues11, :AActes11) returning_values :intMois, :intAnnee^
    if (AVendues12>0) then flag_depart = '1'^
    if (flag_depart = '1') then
            execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues12, :AActes12) returning_values :intMois, :intAnnee^
    if (AVendues13>0) then flag_depart = '1'^
    if (flag_depart = '1') then
            execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues13, :AActes13) returning_values :intMois, :intAnnee^
    if (AVendues14>0) then flag_depart = '1'^
    if (flag_depart = '1') then
            execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues14, :AActes14) returning_values :intMois, :intAnnee^
    if (AVendues15>0) then flag_depart = '1'^
    if (flag_depart = '1') then
            execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues15, :AActes15) returning_values :intMois, :intAnnee^
    if (AVendues16>0) then flag_depart = '1'^
    if (flag_depart = '1') then
            execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues16, :AActes16) returning_values :intMois, :intAnnee^
    if (AVendues17>0) then flag_depart = '1'^
    if (flag_depart = '1') then
            execute procedure ps_nev_creer_histo_vente_m(:AProduitID, :intMois, :intAnnee, :AVendues17, :AActes17) returning_values :intMois, :intAnnee^
  end
end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_produits_lpp(
  AProduitID dm_code,
  APrestation char(3),
  ACodeTIPSLPP varchar(13)
 )
as
declare variable lIntPrestationID integer^
declare variable lChTypeCodeLPP char(1)^
begin

  --  Prestation
  execute procedure ps_renvoyer_id_prestation(APrestation) returning_values :lIntPrestationID^

  if ((char_length(ACodeTIPSLPP) = 7) and (ACodeTIPSLPP similar to '[[:DIGIT:]]*')) then
      lChTypeCodeLPP = '0'^
    else
      lChTypeCodeLPP = '2'^

  insert into t_produit_lpp(t_produit_lpp_id,
                            t_produit_id,
                            type_code,
                            code_lpp,
                            quantite,
                            t_ref_prestation_id)
  values (next value for seq_produit_lpp,
          :AProduitID,
          :lChTypeCodeLPP,
          :ACodeTIPSLPP,
          1,
          :lIntPrestationID)^

end^

/* **************************************************************************************************************** */
/* ************************************************** Encours ***************************************************** */
/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_avance(
  AClientID integer,
  ADate date,
  AProduitID integer,
  AQuantite numeric(5),
  APrixVente float,
  AOperateur varchar(3))
as
declare variable chCodeCIP char(13)^
declare variable strDesignation varchar(50)^
declare variable lFtPrixAchat numeric(10,3)^
declare variable lStrCodePrestation varchar(4)^
declare variable lFtBaseRemboursement numeric(10,2)^
begin

-- TODO recupere directement dans la requete 
    select coalesce(prd.code_cip,prd.code_cip7) ,
           prd.designation,
           prd.prix_achat_catalogue,
           prd.t_ref_prestation_id,
           prd.base_remboursement
    from t_produit prd
    where prd.t_produit_id = cast(:AProduitID as varchar(50))
    into :chCodeCIP,
         :strDesignation,
         :lFtPrixAchat,
         :lStrCodePrestation,
         :lFtBaseRemboursement^

  if (:strDesignation is not null) then        
    insert into t_vignette_avancee(t_vignette_avancee_id,
                                   t_client_id,
                                   date_avance,
                                   code_cip,
                                   designation,
                                   prix_vente,
                                   prix_achat,
                                   code_prestation,
                                   t_produit_id,
                                   t_operateur_id,
                                   quantite_avancee,
                                   base_remboursement)
    values(next value for seq_vignette_avancee,
           :AClientID,
           :ADate,
           :chCodeCIP,
           :strDesignation,
           :APrixVente,
           :lFtPrixAchat,
           :lStrCodePrestation,
           :AProduitID,
           null,
           :AQuantite,
           :lFtbaseRemboursement)^
end^


/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_produit_du(
  AClientID integer,
  ADate date,
  AProduitID integer,
  AQuantite numeric(5),
  APrixVente float,
  AOperateur varchar(3))
as
declare variable chCodeCIP char(13)^
declare variable strDesignation varchar(50)^
declare variable lFtPrixAchat numeric(10,3)^
declare variable lStrCodePrestation varchar(4)^
declare variable lFtBaseRemboursement numeric(10,2)^
begin

    insert into t_produit_du(t_produit_du_id,
                             t_client_id,
                             date_du,
                             t_produit_id,
                             quantite)
    values(next value for seq_produit_du,
           :AClientID,
           :ADate,
           :AProduitID,
           :AQuantite)^
end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_credit(
  AClientID integer,
  ATypeClient char(1),
  AIDCollectivite integer,
  AQualite integer,
  AMontantCredit float,
  ADateDernierReglement date,
  ADateDerniereVisite date)
as
declare variable strClientID varchar(50)^
declare variable boolCpt char(1)^

begin
strClientID = cast(AClientID as varchar(50))^

if ((ATypeClient = 'C') and ((AQualite = 0) or ((AQualite <> 0) and (AClientID = AIDCollectivite)))) then
  boolCpt = '1'^
else 
  boolCpt = '0'^

insert into t_credit(t_credit_id,
           t_client_id,
           t_compte_id,
           date_credit,
           montant)
values(:strClientID,
     iif(:boolCpt = '0', :AClientID, null),
     iif(:boolCpt = '1', :AClientID, null),
     iif(((:ADateDernierReglement is null) or (:ADateDernierReglement < :ADateDerniereVisite)),:ADateDerniereVisite, :ADateDernierReglement),
     :AMontantCredit)^

end^

/* **************************************************************************************************************** */
/* ************************************************** Autres donnees ********************************************** */
/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_operateur(
  AVendeurID integer,
  ANomPrenom varchar(20),
  ACodeVendeur varchar(3),
  AMotDePasse varchar(20))
as
declare variable intPos integer^
declare variable strNom varchar(20)^
declare variable strPrenom varchar(20)^
declare variable strNJF varchar(50)^
begin
  execute procedure ps_separer_nom_prenom(:ANomPrenom, ' ') returning_values :strNom, :strPrenom, :strNJF^

  update or insert into t_operateur(t_operateur_id,
                                    code_operateur,
                                    nom,
                                    prenom,
                                    mot_de_passe)
  values(trim(:ACodeVendeur),
         trim(:ACodeVendeur),
         :strNom,
         :strPrenom,
         :AMotDePasse)^
end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_histo_ent(
  ADateCreation date,
  AHistoriqueClientEntete integer,
  AClientID integer,
  APraticienID integer,
  ANumeroFacture integer,
  ADateDelivrance date,
  ADateFacture date,
  ATypeFacture char)
as
declare variable strHistoriqueClientID varchar(50)^
begin
  strHistoriqueClientID = :ADateCreation || ' ' || :AHistoriqueClientEntete^

  insert into t_historique_client(t_historique_client_id,
                                            t_client_id,
                                            numero_facture,
                                            date_prescription,
                                            code_operateur,
                                            t_praticien_id,
                                            type_facturation,
                                            date_acte)
  values(:strHistoriqueClientID,
         iif(:AClientID=0,null,:AClientID),
         :ANumeroFacture,
         :ADateFacture,
         '.',
         :APraticienID,
         case when :ATypeFacture = 'T' then '1'
              when :ATypeFacture = 'O' then '2'
              else '3'
              end,
         :ADateDelivrance)^

end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_histo_lig(
  ADateCreation date,
  AHistoriqueClientEntete integer,
  ADesignation varchar(23),
  AProduitID dm_code,
  APrixVente float,
  AQuantiteDelivree integer)
as
declare variable strHistoriqueClient varchar(50)^
declare variable strCodeCIP varchar(13)^
declare variable strDesignation varchar(50)^
declare variable intHistoriqueClientLigne integer^
declare variable t_produit_id dm_code^
begin

    strHistoriqueClient = :ADateCreation || ' ' || :AHistoriqueClientEntete^


    select coalesce(code_cip,code_cip7), 
           designation, 
           t_produit_id
    from t_produit
    where t_produit_id = :AProduitID
    into :strCodeCIP,
         :strDesignation,
         :t_produit_id^

    insert into t_historique_client_ligne(t_historique_client_ligne_id,
                                           t_historique_client_id,
                                           code_cip,
                                           t_produit_id,
                                           designation,
                                           quantite_facturee,
                                           prix_vente)
    values(next value for seq_historique_client_ligne,
           :strHistoriqueClient,
           :strCodeCIP,
           :AProduitID,
           coalesce(trim(:strDesignation),:ADesignation),
           :AQuantiteDelivree,
           :APrixVente)^
end^


create
 or alter 
 or alter procedure ps_nev_creer_fact_att(
  AClientID integer,
  ANumeroFacture integer,
  ADateFacture date)
as
begin
   insert into t_facture_attente(t_facture_attente_id,
                 date_acte,
                 t_client_id)
   values(:ANumeroFacture,
         :ADateFacture,
         :AclientID)^

end^
/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_commande(
  ADateCommande date,
  ADateReception date,
  AEtat char(1),
  ANumeroCommandeJour integer,
  AIDFournisseur integer,
  ATotalBrut float,
  ATotalNet float,
  ANombreLigne integer,
  ANombreBoite integer)
as
declare variable strTypeCommande char(1)^
declare variable strFournisseurID varchar(50)^
declare variable strRepartiteurID varchar(50)^
begin
  if (exists(select *
             from t_fournisseur_direct
             where t_fournisseur_direct_id = :AIDFournisseur)) then
  begin
    strTypeCommande = '1'^
    strFournisseurID = AIDFournisseur^
    strRepartiteurID = null^
  end
  else
  begin
    strTypeCommande = '2'^
    strFournisseurID = null^
    strRepartiteurID = AIDFournisseur^
  end

  insert into t_commande(t_commande_id,
                         type_commande,
                         date_creation,
                         date_reception,
                         montant_ht,
                         t_fournisseur_direct_id,
                         t_repartiteur_id,
                         etat)
  values(:ADateCommande || ' ' || :ANumeroCommandeJour,
         :strTypeCommande,
         :ADateCommande,
         :ADateReception,
         0,
         :strFournisseurID,
         :strRepartiteurID,
         iif(:AEtat in ('N' , 'T'), '2', '3'))^
end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_comm_ligne(
  ADateCommande date,
  ANumeroCommandeJour integer,
  AIDProduit integer,
  AQuantiteCommandee integer,
  AQuantiteRecue integer,
  APrixAchat float,
  APrixRemise float,
  APrixVente float,
  ADateReception date)
as
declare variable strCommandeID varchar(50)^
begin
  strCommandeID = ADateCommande || ' ' || ANumeroCommandeJour^
  insert into t_commande_ligne(t_commande_ligne_id,
                               t_commande_id,
                               t_produit_id,
                               quantite_commandee,
                               quantite_recue,
                               quantite_totale_recue,
                               prix_achat_tarif,
                               prix_achat_remise,
                               prix_vente)
  values(next value for seq_commande_ligne,
         :strCommandeID,
         :AIDProduit,
         :AQuantiteCommandee,
         :AQuantiteRecue,
         :AQuantiteRecue,
         :APrixAchat,
         :APrixRemise,
         :APrixVente)^

  update t_commande
  set date_reception = iif((date_reception is null) or (date_reception < :ADateReception), :ADateReception, date_reception),
      montant_ht = montant_ht + (:AQuantiteCommandee *  :APrixAchat)
  where t_commande_id = :strCommandeID^
end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_catalogue(
  AIDFournisseur integer,
  AIDCatalogue integer,
  ALibelle varchar(105))
as
declare variable f varchar(50)^
declare variable r varchar(50)^
begin
  f = cast(AIDFournisseur as varchar(50))^
  
  select raison_sociale
  from t_fournisseur_direct
  where t_fournisseur_direct_id = :f
  into :r^
  
  if (row_count <> 0) then
  begin  
    if (not exists(select null
                   from t_catalogue
                   where t_catalogue_id = :f)) then
      insert into t_catalogue(
        t_catalogue_id,
        designation,
        t_fournisseur_id,
        date_creation)
      values(
        :f,
        :r,
        :f,
        current_date)^
      
    insert into t_classification_fournisseur(
      t_classification_fournisseur_id,
      designation,
      t_catalogue_id)
    values(
      :f || '_' || :AIDCatalogue,
      substring(trim(:ALibelle) from 1 for 100),
      :f)^
  end
  else
    exception exp_nev_fou_cat_non_trouve^
end^

/* **************************************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_catalogue_prod(
  AIDFournisseur integer,
  AIDCatalogue integer,
  AIDProduit integer,
  Atypeg integer,
  APrixAChatCatalogue float,
  APrixAchatRemise float,
  ADerniereQuantiteCommandee smallint,  
  ADateDerniereCommande date)
as
declare variable g varchar(50)^
declare variable l smallint^
declare variable p varchar(50)^
declare variable cl integer^
begin
  --traitement à séparer en deux à l'occasion
  g = cast(:AIDFournisseur || '_' || :AIDCatalogue as varchar(50))^
  p = cast(AIDProduit as varchar(50))^

  if (not exists(select null from t_catalogue where t_catalogue_id = :AIDFournisseur)) then
  EXECUTE PROCEDURE ps_nev_creer_catalogue(:AIDFournisseur,
                                              :AIDCatalogue,  
                                              (select raison_sociale from t_fournisseur_direct where t_fournisseur_direct_id = :AIDFournisseur)
                                             )^

  select t_catalogue_ligne_id
  from t_catalogue_ligne
  where t_classification_fournisseur_id = :g and t_produit_id = :p
  into :cl^
  
  if (row_count = 0) then
  begin
    select max(no_ligne)
    from t_catalogue_ligne
    where t_classification_fournisseur_id = :g
    into l^
    
    if (l is null) then
      l = 1^
        
    insert into t_catalogue_ligne(
      t_catalogue_ligne_id,
      t_catalogue_id,
      t_classification_fournisseur_id,
      no_ligne,
      t_produit_id,
      prix_achat_catalogue,
      prix_achat_remise,
      remise_simple,
      date_maj_tarif,
      date_creation)
    values(
      next value for seq_catalogue_ligne,
      :AIDFournisseur,
      :g,
      :l + 1,
      :AIDProduit,
      iif(:Atypeg=1,:APrixAchatCatalogue,:APrixAchatRemise),
      iif(:Atypeg=1,:APrixAchatCatalogue,:APrixAchatRemise),
      0,
      current_date,
      current_date)^
  end
  else
    if (Atypeg = 1) then 
      update t_catalogue_ligne
      set prix_achat_catalogue = :APrixAchatCatalogue,
          prix_achat_remise = iif(prix_achat_remise = 0 , :APrixAchatCatalogue,prix_achat_remise),
          remise_simple = iif(prix_achat_remise > 0 ,(1 - prix_achat_remise/:APrixAchatCatalogue) * 100 ,remise_simple)
      where t_catalogue_ligne_id = :cl^
    else
      update t_catalogue_ligne
      set prix_achat_remise = :APrixAchatRemise,
        prix_achat_catalogue = iif(prix_achat_catalogue=0 ,:APrixAchatRemise,prix_achat_catalogue),
        quantite = iif(:ADerniereQuantiteCommandee <> 0, :ADerniereQuantiteCommandee, 1),
        date_maj_tarif = coalesce(:ADateDerniereCommande, current_date),
        remise_simple = iif(:APrixAchatRemise > 0 ,(1 - :APrixAchatRemise/prix_achat_catalogue) * 100 ,remise_simple)
      where t_catalogue_ligne_id = :cl^
end^

/* ********************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_document(
  AIDClient integer,
  ALibelle varchar(50),
  AFichier varchar(255))
as
declare variable numero_facture dm_code^
begin

  if ( :AIDClient in ( select t_client_id from t_client )) then
   insert into t_document(t_document_id,
                         type_entite,
                         t_entite_id,
                         libelle,
                         document, 
                         commentaire)
  values(next value for seq_document,
         2, --doc client
         :AIDClient,
         :ALibelle,
         :AFichier,
         'Attestation mutuelle')^
  else
  begin
    -- si le numero client ne donne rien  , c'est peu etre un scan ordo a lier par son numero de facture
    numero_facture = replace( :ALIBELLE ,'.pdf', '')^
   
    insert into t_document(t_document_id,
                         type_entite,
                         t_entite_id,
                         libelle,
                         document, 
                         commentaire)
    values(next value for seq_document,
           2, --doc client
           ( select t_client_id from t_historique_client where numero_facture = :numero_facture ),
           :ALibelle,
           :AFichier,
           'Scan Ordonnance no '||:numero_facture)^

  end       
end^

/* ********************************************************************************************** */

create
 or alter 
 or alter procedure ps_nev_creer_carte_prog_rel(
  AIDClient integer,
  numcarte char(13)
)
as
begin

insert into t_carte_programme_relationnel(
  t_carte_prog_relationnel_id,
  t_aad_id,
  numero_carte
 )
values(
  next value for seq_programme_relationnel,
  :AIDClient,
  :numcarte)^
end^
SET TERM ; ^
