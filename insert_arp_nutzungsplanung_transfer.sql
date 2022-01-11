-- Datenumbau von Modell SO_Nutzungsplanung_20171118 ins Modell SO_Nutzungsplanung_Nachfuehrung_20201005
-- Datenumbau erfolgt pro XTF

-- dataset
INSERT INTO arp_nutzungsplanung_transfer_v1.t_ili2db_dataset
SELECT
    t_id,
    datasetname
FROM
    arp_nutzungsplanung_import_v1.t_ili2db_dataset
;

-- neues Dataset "Kanton" einfügen
INSERT INTO arp_nutzungsplanung_transfer_v1.t_ili2db_dataset
SELECT
    nextval('arp_nutzungsplanung_transfer_v1.t_ili2db_seq'::regclass) as t_id,
    'Kanton' as datasetname
;

-- basket
INSERT INTO arp_nutzungsplanung_transfer_v1.t_ili2db_basket
SELECT
    basket.t_id,
    basket.dataset,
    replace (basket.topic, 'SO_Nutzungsplanung_20171118', 'SO_Nutzungsplanung_Nachfuehrung_20201005')AS topic,
    basket.t_ili_tid,
    basket.attachmentkey,
    basket.domains

FROM
    arp_nutzungsplanung_import_v1.t_ili2db_basket AS basket
WHERE basket.topic != 'SO_Nutzungsplanung_20171118.TransferMetadaten'
        AND
      basket.topic != 'SO_Nutzungsplanung_20171118.Verfahrenstand'
;
-- neue Topic SO_Nutzungsplanung_Nachfuehrung_20201005.Laermempfindlichkeitsstufen einfügen in basket
INSERT INTO arp_nutzungsplanung_transfer_v1.t_ili2db_basket
SELECT
    nextval('arp_nutzungsplanung_transfer_v1.t_ili2db_seq'::regclass) AS t_id,
    basket.dataset,
   'SO_Nutzungsplanung_Nachfuehrung_20201005.Laermempfindlichkeitsstufen' AS topic,
    NULL AS t_ili_tid,
    'Datenumbau neues Topic Laermempfindlichkeitsstufen' attachmentkey,
    NULL AS domains
FROM
    arp_nutzungsplanung_import_v1.t_ili2db_basket AS basket
WHERE
    topic= 'SO_Nutzungsplanung_20171118.Nutzungsplanung'
;

-- neue Baket für dataset "Kanton". Topic Nutzungsplanung.
INSERT INTO arp_nutzungsplanung_transfer_v1.t_ili2db_basket
SELECT
    nextval('arp_nutzungsplanung_transfer_v1.t_ili2db_seq'::regclass) AS t_id,
    (SELECT
        t_id
    FROM
        arp_nutzungsplanung_transfer_v1.t_ili2db_dataset
    WHERE
        datasetname='Kanton') AS dataset,
    'SO_Nutzungsplanung_Nachfuehrung_20201005.Nutzungsplanung' AS topic,
    Null AS t_ili_tid,
    'Nachfuehrung_Kanton' AS attachmentkey,
    Null AS domains
;

-- neue Baket für dataset "Kanton". Topic Erschliessungsplanung.
INSERT INTO arp_nutzungsplanung_transfer_v1.t_ili2db_basket
SELECT
    nextval('arp_nutzungsplanung_transfer_v1.t_ili2db_seq'::regclass) AS t_id,
    (SELECT
        t_id
    FROM
        arp_nutzungsplanung_transfer_v1.t_ili2db_dataset
    WHERE
        datasetname='Kanton') AS dataset,
    'SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung' AS topic,
    Null AS t_ili_tid,
    'Nachfuehrung_Kanton' AS attachmentkey,
    Null AS domains
;

-- neue Baket für dataset "Kanton". Topic Rechtsvorschriften.
INSERT INTO arp_nutzungsplanung_transfer_v1.t_ili2db_basket
SELECT
    nextval('arp_nutzungsplanung_transfer_v1.t_ili2db_seq'::regclass) AS t_id,
    (SELECT
        t_id
    FROM
        arp_nutzungsplanung_transfer_v1.t_ili2db_dataset
    WHERE
        datasetname='Kanton') AS dataset,
    'SO_Nutzungsplanung_Nachfuehrung_20201005.Rechtsvorschriften' AS topic,
    Null AS t_ili_tid,
    'Nachfuehrung_Kanton' AS attachmentkey,
    Null AS domains
;

--Dokumente
INSERT INTO arp_nutzungsplanung_transfer_v1.rechtsvorschrften_dokument
SELECT
    t_id,
    t_basket,
    t_datasetname,
    t_ili_tid,
    dokumentid,
    titel,
    offiziellertitel,
    abkuerzung,
    offiziellenr,
    kanton,
    gemeinde,
    publiziertab,
    CASE rechtsstatus
        WHEN 'laufendeAenderung'
            THEN 'AenderungMitVorwirkung'
        ELSE 'inKraft'
    END AS rechtsstatus,
    'https://geo.so.ch/docs/ch.so.arp.zonenplaene/Zonenplaene_pdf/' || textimweb AS textimweb,
    bemerkungen,
    rechtsvorschrift
FROM
    arp_nutzungsplanung_import_v1.rechtsvorschrften_dokument
;

-- Grundnutzung
INSERT INTO arp_nutzungsplanung_transfer_v1.nutzungsplanung_typ_grundnutzung
SELECT
    t_id,
    t_basket,
    t_datasetname,
    t_ili_tid,
    typ_kt,
    code_kommunal,
    nutzungsziffer,
    nutzungsziffer_art,
    geschosszahl,
    bezeichnung,
    abkuerzung,
    'Nutzungsplanfestlegung' as verbindlichkeit,
    bemerkungen
FROM
    arp_nutzungsplanung_import_v1.nutzungsplanung_typ_grundnutzung
;

INSERT INTO arp_nutzungsplanung_transfer_v1.nutzungsplanung_grundnutzung
SELECT
    t_id,
    t_basket,
    t_datasetname,
    t_ili_tid,
    geometrie,
    name_nummer AS geschaefts_nummer,
    CASE rechtsstatus
        WHEN 'laufendeAenderung'
            THEN 'AenderungMitVorwirkung'
        ELSE 'inKraft'
    END AS rechtsstatus,
    publiziertab,
    bemerkungen,
    erfasser,
    datum,
    NULL AS publiziertbis,
    typ_grundnutzung
FROM
    arp_nutzungsplanung_import_v1.nutzungsplanung_grundnutzung
;

/* Stefan */


/*
 * Es werden von der Zwischentabelle nur diejenigen Verknüpfungen kopiert,
 * deren Typ tatsächlich auch im Zielschema bei den Typen vorhanden ist.
 * Das hilft zwar bei Typen, die zum Kantons-Basket gehören würden und
 * so nicht fälschlicherweise der Gemeinde zugewiesen werden. Es führt
 * aber dazu, dass eventuell Dokumente kopiert wurden, die dann mit nix
 * verküpft sind.
 *
 */

INSERT INTO 
    arp_nutzungsplanung_transfer_v1.nutzungsplanung_typ_grundnutzung_dokument 
(
    t_id,
    t_basket,
    t_datasetname,
    typ_grundnutzung,
    dokument
)

SELECT 
    t_id,
    t_basket,
    t_datasetname,
    typ_grundnutzung,
    dokument
FROM 
    arp_nutzungsplanung_import_v1.nutzungsplanung_typ_grundnutzung_dokument AS typ_grundnutzung_dokument 
WHERE 
    typ_grundnutzung IN 
    (
        SELECT  
            t_id 
        FROM 
            arp_nutzungsplanung_transfer_v1.nutzungsplanung_typ_grundnutzung 
    )
;    
    
WITH RECURSIVE x(ursprung, hinweis, parents, last_ursprung, depth) AS 
(
    SELECT 
        ursprung, 
        hinweis, 
        ARRAY[ursprung] AS parents, 
        ursprung AS last_ursprung, 
        0 AS "depth" 
    FROM 
        arp_nutzungsplanung_import_v1.rechtsvorschrften_hinweisweiteredokumente
    WHERE
        ursprung != hinweis
    -- Hier könnte zusätzlich nach Basket gefilter werden.
    -- Dann müssen aber die bereits kopierten Dokumente
    -- korrekt zugewiesen sein, was momentan nicht ist.

    UNION ALL
  
    SELECT 
        x.ursprung, 
        x.hinweis, 
        parents||t1.hinweis, 
        t1.hinweis AS last_ursprung, 
        x."depth" + 1
    FROM 
        x 
        INNER JOIN arp_nutzungsplanung_import_v1.rechtsvorschrften_hinweisweiteredokumente t1 
        ON (last_ursprung = t1.ursprung)
    WHERE 
        t1.hinweis IS NOT NULL
    -- Dito. Siehe oben.
)
,
zusaetzliche_dokumente AS 
(
    SELECT 
        DISTINCT ON (x.last_ursprung, x.ursprung)
        x.ursprung AS top_level_dokument,
        x.last_ursprung AS t_id
    FROM 
        x
)
INSERT INTO 
    arp_nutzungsplanung_transfer_v1.nutzungsplanung_typ_grundnutzung_dokument 
    (
        t_basket,
        t_datasetname,
        typ_grundnutzung
        ,
        dokument 
    )
    SELECT 
        DISTINCT 
        typ_grundnutzung_dokument.t_basket,
        typ_grundnutzung_dokument.t_datasetname,
        typ_grundnutzung_dokument.typ_grundnutzung,
        zusaetzliche_dokumente.t_id AS vorschrift_vorschriften_dokument
    FROM 
        zusaetzliche_dokumente
        LEFT JOIN arp_nutzungsplanung_transfer_v1.nutzungsplanung_typ_grundnutzung_dokument AS typ_grundnutzung_dokument
        ON typ_grundnutzung_dokument.dokument = zusaetzliche_dokumente.top_level_dokument
    WHERE
        NOT EXISTS 
        (
            SELECT 
                typ_grundnutzung,
                dokument
            FROM 
                arp_nutzungsplanung_transfer_v1.nutzungsplanung_typ_grundnutzung_dokument
            WHERE 
                typ_grundnutzung = nutzungsplanung_typ_grundnutzung_dokument.typ_grundnutzung 
                AND
                dokument = zusaetzliche_dokumente.t_id
        )
;

/* Stefan */

--überlagernde Fläche
INSERT INTO arp_nutzungsplanung_transfer_v1.nutzungsplanung_typ_ueberlagernd_flaeche
SELECT
    t_id,
-- Für Nachführungseinheit "Kanton" gibt es einen eigenen Basket
    CASE typ_kt
        WHEN 'N526_kantonale_Landwirtschafts_und_Schutzzone_Witi'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Nutzungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'N610_Perimeter_kantonaler_Nutzungsplan'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Nutzungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
          ELSE t_basket
    END AS t_basket,
-- Für Nachführungseinheit "Kanton" gibt es einen eigenes Dataset
    CASE typ_kt
        WHEN 'N526_kantonale_Landwirtschafts_und_Schutzzone_Witi'
            THEN 'Kanton'
        WHEN 'N610_Perimeter_kantonaler_Nutzungsplan'
            THEN 'Kanton'
          ELSE t_datasetname
    END AS t_datasetname,
    t_ili_tid,
    typ_kt,
    code_kommunal,
    bezeichnung,
    abkuerzung,
    verbindlichkeit,
    bemerkungen
FROM
    arp_nutzungsplanung_import_v1.nutzungsplanung_typ_ueberlagernd_flaeche
WHERE
    typ_kt!= 'N520_BLN_Gebiet'
    AND
    typ_kt!= 'N521_Juraschutzzone'
    AND
    typ_kt!= 'N522_Naturreservat_inkl_Geotope'
    AND
    typ_kt!= 'N524_Siedlungstrennguertel_von_kommunaler_Bedeutung'
    AND
    typ_kt!= 'N525_Siedlungstrennguertel_von_kantonaler_Bedeutung'
    AND
    typ_kt!= 'N527_kantonale_Uferschutzzone'
    AND
    typ_kt!= 'N530_Naturgefahren_erhebliche_Gefaehrdung'
    AND
    typ_kt!= 'N531_Naturgefahren_mittlere_Gefaehrdung'
    AND
    typ_kt!= 'N532_Naturgefahren_geringe_Gefaehrdung'
    AND
    typ_kt!= 'N533_Naturgefahren_Restgefaehrdung'
    AND
    typ_kt!= 'N593_Grundwasserschutzzone_S1'
    AND
    typ_kt!= 'N594_Grundwasserschutzzone_S2'
    AND
    typ_kt!= 'N595_Grundwasserschutzzone_S3'
    AND
    typ_kt!= 'N596_Grundwasserschutzareal'
    AND
    typ_kt!= 'N680_Empfindlichkeitsstufe_I'
    AND
    typ_kt!= 'N681_Empfindlichkeitsstufe_II'
    AND
    typ_kt!= 'N682_Empfindlichkeitsstufe_II_aufgestuft'
    AND
    typ_kt!= 'N683_Empfindlichkeitsstufe_III'
    AND
    typ_kt!= 'N684_Empfindlichkeitsstufe_III_aufgestuft'
    AND
    typ_kt!= 'N685_Empfindlichkeitsstufe_IV'
    AND
    typ_kt!= 'N686_keine_Empfindlichkeitsstufe'
    AND
    typ_kt!= 'N690_kantonales_Vorranggebiet_Natur_und_Landschaft'
    AND
    typ_kt!= 'N812_geologisches_Objekt'
    AND
    typ_kt!= 'N820_kantonal_geschuetztes_Kulturobjekt'
;

INSERT INTO arp_nutzungsplanung_transfer_v1.nutzungsplanung_ueberlagernd_flaeche

SELECT
    ueberlagernd_flaeche.t_id,
    -- Für Nachführungseinheit "Kanton" gibt es einen eigenen Basket
    CASE typ_kt
        WHEN 'N526_kantonale_Landwirtschafts_und_Schutzzone_Witi'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Nutzungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'N610_Perimeter_kantonaler_Nutzungsplan'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Nutzungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
          ELSE ueberlagernd_flaeche.t_basket
    END AS t_basket,
-- Für Nachführungseinheit "Kanton" gibt es einen eigenes Dataset
    CASE typ_kt
        WHEN 'N526_kantonale_Landwirtschafts_und_Schutzzone_Witi'
            THEN 'Kanton'
        WHEN 'N610_Perimeter_kantonaler_Nutzungsplan'
            THEN 'Kanton'
        ELSE ueberlagernd_flaeche.t_datasetname
    END AS t_datasetname,
    ueberlagernd_flaeche.t_ili_tid,
    ueberlagernd_flaeche.geometrie,
    ueberlagernd_flaeche.name_nummer AS geschaefts_nummer,
    CASE ueberlagernd_flaeche.rechtsstatus
        WHEN 'laufendeAenderung'
            THEN 'AenderungMitVorwirkung'
        ELSE 'inKraft'
    END AS rechtsstatus,
    ueberlagernd_flaeche.publiziertab,
    ueberlagernd_flaeche.bemerkungen,
    ueberlagernd_flaeche.erfasser,
    ueberlagernd_flaeche.datum,
    NULL AS publiziertbis,
    ueberlagernd_flaeche.typ_ueberlagernd_flaeche
FROM
    arp_nutzungsplanung_import_v1.nutzungsplanung_ueberlagernd_flaeche AS ueberlagernd_flaeche
    LEFT JOIN arp_nutzungsplanung_import_v1.nutzungsplanung_typ_ueberlagernd_flaeche AS typ
    ON typ.t_id = ueberlagernd_flaeche.typ_ueberlagernd_flaeche
WHERE
    typ.typ_kt!= 'N520_BLN_Gebiet'
    AND
    typ_kt!= 'N521_Juraschutzzone'
    AND
    typ.typ_kt!= 'N522_Naturreservat_inkl_Geotope'
    AND
    typ.typ_kt!= 'N524_Siedlungstrennguertel_von_kommunaler_Bedeutung'
    AND
    typ.typ_kt!= 'N525_Siedlungstrenngu el_von_kantonaler_Bedeutung'
    AND
    typ.typ_kt!= 'N527_kantonale_Uferschutzzone'
    AND
    typ.typ_kt!= 'N530_Naturgefahren_erhebliche_Gefaehrdung'
    AND
    typ.typ_kt!= 'N531_Naturgefahren_mittlere_Gefaehrdung'
    AND
    typ.typ_kt!= 'N532_Naturgefahren_geringe_Gefaehrdung'
    AND
    typ.typ_kt!= 'N533_Naturgefahren_Restgefaehrdung'
    AND
    typ.typ_kt!= 'N593_Grundwasserschutzzone_S1'
    AND
    typ.typ_kt!= 'N594_Grundwasserschutzzone_S2'
    AND
    typ.typ_kt!= 'N595_Grundwasserschutzzone_S3'
    AND
    typ.typ_kt!= 'N596_Grundwasserschutzareal'
    AND
    typ.typ_kt!= 'N680_Empfindlichkeitsstufe_I'
    ANDlice

    typ.typ_kt!= 'N681_Empfindlichkeitsstufe_II'
    AND
    typ.typ_kt!= 'N682_Empfindlichkeitsstufe_II_aufgestuft'
    AND
    typ.typ_kt!= 'N683_Empfindlichkeitsstufe_III'
    AND
    typ.typ_kt!= 'N684_Empfindlichkeitsstufe_III_aufgestuft'
    AND
    typ.typ_kt!= 'N685_Empfindlichkeitsstufe_IV'
    AND
    typ.typ_kt!= 'N686_keine_Empfindlichkeitsstufe'
    AND
    typ.typ_kt!= 'N690_kantonales_Vorranggebiet_Natur_und_Landschaft'
    AND
    typ.typ_kt!= 'N812_geologisches_Objekt'
    AND
    typ.typ_kt!= 'N820_kantonal_geschuetztes_Kulturobjekt'
;

--Beziehung Dokument übberlagernde Fläche !! Verweise noch nicht gelöst
INSERT INTO arp_nutzungsplanung_transfer_v1.nutzungsplanung_typ_ueberlagernd_flaeche_dokument
SELECT
    ueberlagernd_flaeche_dokument.t_id,
    -- Für Nachführungseinheit "Kanton" gibt es einen eigenen Basket
    CASE typ_kt
        WHEN 'N526_kantonale_Landwirtschafts_und_Schutzzone_Witi'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE  
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Nutzungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'N610_Perimeter_kantonaler_Nutzungsplan'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Nutzungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        ELSE ueberlagernd_flaeche_dokument.t_basket
    END AS t_basket,
-- Für Nachführungseinheit "Kanton" gibt es einen eigenes Dataset
    CASE typ_kt
        WHEN 'N526_kantonale_Landwirtschafts_und_Schutzzone_Witi'
            THEN 'Kanton'
        WHEN 'N610_Perimeter_kantonaler_Nutzungsplan'
            THEN 'Kanton'
        ELSE ueberlagernd_flaeche_dokument.t_datasetname
    END AS t_datasetname,
    ueberlagernd_flaeche_dokument.typ_ueberlagernd_flaeche,
    ueberlagernd_flaeche_dokument.dokument
FROM
    arp_nutzungsplanung_import_v1.nutzungsplanung_typ_ueberlagernd_flaeche_dokument AS ueberlagernd_flaeche_dokument
    LEFT JOIN arp_nutzungsplanung_import_v1.nutzungsplanung_typ_ueberlagernd_flaeche AS typ
    ON typ.t_id = ueberlagernd_flaeche_dokument.typ_ueberlagernd_flaeche
WHERE
    typ.typ_kt!= 'N520_BLN_Gebiet'
    AND
    typ.typ_kt!= 'N521_Juraschutzzone'
    AND
    typ.typ_kt!= 'N522_Naturreservat_inkl_Geotope'
    AND
    typ.typ_kt!= 'N524_Siedlungstrennguertel_von_kommunaler_Bedeutung'
    AND
    typ.typ_kt!= 'N525_Siedlungstrennguertel_von_kantonaler_Bedeutung'
    AND
    typ.typ_kt!= 'N527_kantonale_Uferschutzzone'
    AND
    typ.typ_kt!= 'N530_Naturgefahren_erhebliche_Gefaehrdung'
    AND
    typ.typ_kt!= 'N531_Naturgefahren_mittlere_Gefaehrdung'
    AND
    typ.typ_kt!= 'N532_Naturgefahren_geringe_Gefaehrdung'
    AND
    typ.typ_kt!= 'N533_Naturgefahren_Restgefaehrdung'
    AND
    typ.typ_kt!= 'N593_Grundwasserschutzzone_S1'
    AND
    typ.typ_kt!= 'N594_Grundwasserschutzzone_S2'
    AND
    typ.typ_kt!= 'N595_Grundwasserschutzzone_S3'
    AND
    typ.typ_kt!= 'N596_Grundwasserschutzareal'
    AND
    typ.typ_kt!= 'N680_Empfindlichkeitsstufe_I'
    AND
    typ.typ_kt!= 'N681_Empfindlichkeitsstufe_II'
    AND
    typ.typ_kt!= 'N682_Empfindlichkeitsstufe_II_aufgestuft'
    AND
    typ.typ_kt!= 'N683_Empfindlichkeitsstufe_III'
    AND
    typ.typ_kt!= 'N684_Empfindlichkeitsstufe_III_aufgestuft'
    AND
    typ.typ_kt!= 'N685_Empfindlichkeitsstufe_IV'
    AND
    typ.typ_kt!= 'N686_keine_Empfindlichkeitsstufe'
    AND
    typ.typ_kt!= 'N690_kantonales_Vorranggebiet_Natur_und_Landschaft'
    AND
    typ.typ_kt!= 'N812_geologisches_Objekt'
    AND
    typ.typ_kt!= 'N820_kantonal_geschuetztes_Kulturobjekt'
;

--überlagernde Linie
INSERT INTO arp_nutzungsplanung_transfer_v1.nutzungsplanung_typ_ueberlagernd_linie
SELECT
    t_id,
    t_basket,
    t_datasetname,
    t_ili_tid,
    typ_kt,
    code_kommunal,
    bezeichnung,
    abkuerzung,
    verbindlichkeit,
    bemerkungen
FROM
    arp_nutzungsplanung_import_v1.nutzungsplanung_typ_ueberlagernd_linie
WHERE
    typ_kt = 'N799_weitere_linienbezogene_Festlegungen_NP'
;

INSERT INTO arp_nutzungsplanung_transfer_v1.nutzungsplanung_ueberlagernd_linie

SELECT
    ueberlagernd_linie.t_id,
    ueberlagernd_linie.t_basket,
    ueberlagernd_linie.t_datasetname,
    ueberlagernd_linie.t_ili_tid,
    ueberlagernd_linie.geometrie,
    ueberlagernd_linie.name_nummer AS geschaefts_nummer,
    CASE ueberlagernd_linie.rechtsstatus
        WHEN 'laufendeAenderung'
            THEN 'AenderungMitVorwirkung'
        ELSE 'inKraft'
    END AS rechtsstatus,
    ueberlagernd_linie.publiziertab,
    ueberlagernd_linie.bemerkungen,
    ueberlagernd_linie.erfasser,
    ueberlagernd_linie.datum,
    NULL AS publiziertbis,
    ueberlagernd_linie.typ_ueberlagernd_linie
FROM
    arp_nutzungsplanung_import_v1.nutzungsplanung_ueberlagernd_linie AS ueberlagernd_linie
    LEFT JOIN arp_nutzungsplanung_import_v1.nutzungsplanung_typ_ueberlagernd_linie AS typ
    ON typ.t_id = ueberlagernd_linie.typ_ueberlagernd_linie
WHERE
    typ.typ_kt = 'N799_weitere_linienbezogene_Festlegungen_NP'
;
--Beziehung Dokument überlagernde Linie!! Verweise noch nicht gelöst
INSERT INTO arp_nutzungsplanung_transfer_v1.nutzungsplanung_typ_ueberlagernd_linie_dokument
SELECT
    ueberlagernd_linie_dokument.t_id,
    ueberlagernd_linie_dokument.t_basket,
    ueberlagernd_linie_dokument.t_datasetname,
    ueberlagernd_linie_dokument.typ_ueberlagernd_linie,
    ueberlagernd_linie_dokument.dokument
FROM
    arp_nutzungsplanung_import_v1.nutzungsplanung_typ_ueberlagernd_linie_dokument AS ueberlagernd_linie_dokument
    LEFT JOIN arp_nutzungsplanung_import_v1.nutzungsplanung_typ_ueberlagernd_linie AS typ
    ON typ.t_id = ueberlagernd_linie_dokument.typ_ueberlagernd_linie
WHERE
    typ.typ_kt = 'N799_weitere_linienbezogene_Festlegungen_NP'
;

--überlagernde Punkt
INSERT INTO arp_nutzungsplanung_transfer_v1.nutzungsplanung_typ_ueberlagernd_punkt
SELECT
    t_id,
    t_basket,
    t_datasetname,
    t_ili_tid,
    typ_kt,
    code_kommunal,
    bezeichnung,
    abkuerzung,
    verbindlichkeit,
    bemerkungen
FROM
    arp_nutzungsplanung_import_v1.nutzungsplanung_typ_ueberlagernd_punkt
WHERE
    typ_kt!= 'N812_geologisches_Objekt'
    AND
    typ_kt!= 'N820_kantonal_geschuetztes_Kulturobjekt'
;

INSERT INTO arp_nutzungsplanung_transfer_v1.nutzungsplanung_ueberlagernd_punkt

SELECT
    ueberlagernd_punkt.t_id,
    ueberlagernd_punkt.t_basket,
    ueberlagernd_punkt.t_datasetname,
    ueberlagernd_punkt.t_ili_tid,
    ueberlagernd_punkt.geometrie,
    ueberlagernd_punkt.name_nummer AS geschaefts_nummer,
    CASE ueberlagernd_punkt.rechtsstatus
        WHEN 'laufendeAenderung'
            THEN 'AenderungMitVorwirkung'
        ELSE 'inKraft'
    END AS rechtsstatus,
    ueberlagernd_punkt.publiziertab,
    ueberlagernd_punkt.bemerkungen,
    ueberlagernd_punkt.erfasser,
    ueberlagernd_punkt.datum,
    NULL AS publiziertbis,
    ueberlagernd_punkt.typ_ueberlagernd_punkt
FROM
    arp_nutzungsplanung_import_v1.nutzungsplanung_ueberlagernd_punkt AS ueberlagernd_punkt
    LEFT JOIN arp_nutzungsplanung_import_v1.nutzungsplanung_typ_ueberlagernd_punkt AS typ
    ON typ.t_id = ueberlagernd_punkt.typ_ueberlagernd_punkt
WHERE
    typ.typ_kt!= 'N812_geologisches_Objekt'
    AND
    typ.typ_kt!= 'N820_kantonal_geschuetztes_Kulturobjekt'
;

--Beziehung Dokument überlagernde Punkt!! Verweise noch nicht gelöst
INSERT INTO arp_nutzungsplanung_transfer_v1.nutzungsplanung_typ_ueberlagernd_punkt_dokument
SELECT
    ueberlagernd_punkt_dokument.t_id,
    ueberlagernd_punkt_dokument.t_basket,
    ueberlagernd_punkt_dokument.t_datasetname,
    ueberlagernd_punkt_dokument.typ_ueberlagernd_punkt,
    ueberlagernd_punkt_dokument.dokument
FROM
    arp_nutzungsplanung_import_v1.nutzungsplanung_typ_ueberlagernd_punkt_dokument AS ueberlagernd_punkt_dokument
    LEFT JOIN arp_nutzungsplanung_import_v1.nutzungsplanung_typ_ueberlagernd_punkt AS typ
    ON typ.t_id = ueberlagernd_punkt_dokument.typ_ueberlagernd_punkt
WHERE
    typ.typ_kt!= 'N812_geologisches_Objekt'
    AND
    typ.typ_kt!= 'N820_kantonal_geschuetztes_Kulturobjekt'
;

-- Erschliessung Fläche
INSERT INTO arp_nutzungsplanung_transfer_v1.erschlssngsplnung_typ_erschliessung_flaechenobjekt
SELECT
    t_id,
-- Für Nachführungseinheit "Kanton" gibt es einen eigenen Basket
    CASE typ_kt
        WHEN 'E560_Nationalstrasse'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E561_Kantonsstrasse'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        ELSE t_basket
    END AS t_basket,
-- Für Nachführungseinheit "Kanton" gibt es einen eigenes Dataset
    CASE typ_kt
        WHEN 'E560_Nationalstrasse'
            THEN 'Kanton'
        WHEN 'E561_Kantonsstrasse'
            THEN 'Kanton'
        ELSE t_datasetname
    END AS t_datasetname,
    t_ili_tid,
    typ_kt,
    code_kommunal,
    bezeichnung,
    abkuerzung,
    verbindlichkeit,
    bemerkungen
FROM
    arp_nutzungsplanung_import_v1.erschlssngsplnung_typ_erschliessung_flaechenobjekt
;

INSERT INTO arp_nutzungsplanung_transfer_v1.erschlssngsplnung_erschliessung_flaechenobjekt
SELECT
    erschliessung_flaechenobjekt.t_id,
-- Für Nachführungseinheit "Kanton" gibt es einen eigenen Basket
    CASE typ.typ_kt
        WHEN 'E560_Nationalstrasse'
            THEN
                (SELECT
                    t_id
                FROM
                     arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE  
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E561_Kantonsstrasse'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        ELSE erschliessung_flaechenobjekt.t_basket
    END AS t_basket,
-- Für Nachführungseinheit "Kanton" gibt es einen eigenes Dataset
    CASE typ_kt
        WHEN 'E560_Nationalstrasse'
            THEN 'Kanton'
        WHEN 'E561_Kantonsstrasse'
            THEN 'Kanton'
        ELSE erschliessung_flaechenobjekt.t_datasetname
    END AS t_datasetname,
    erschliessung_flaechenobjekt.t_ili_tid,
    erschliessung_flaechenobjekt.geometrie,
    erschliessung_flaechenobjekt.name_nummer AS geschaefts_nummer,
    CASE rechtsstatus
        WHEN 'laufendeAenderung'
            THEN 'AenderungMitVorwirkung'
        ELSE 'inKraft'
    END AS rechtsstatus,
    erschliessung_flaechenobjekt.publiziertab,
    erschliessung_flaechenobjekt.bemerkungen,
    erschliessung_flaechenobjekt.erfasser,
    erschliessung_flaechenobjekt.datum,
    NULL AS publiziertbis,
    erschliessung_flaechenobjekt.typ_erschliessung_flaechenobjekt
FROM
    arp_nutzungsplanung_import_v1.erschlssngsplnung_erschliessung_flaechenobjekt AS erschliessung_flaechenobjekt
    LEFT JOIN arp_nutzungsplanung_import_v1.erschlssngsplnung_typ_erschliessung_flaechenobjekt AS typ
    ON typ.t_id = erschliessung_flaechenobjekt.typ_erschliessung_flaechenobjekt
;

INSERT INTO arp_nutzungsplanung_transfer_v1.erschlssngsplnung_typ_erschliessung_flaechenobjekt_dokument
SELECT
    erschliessung_flaechenobjekt_dokument.t_id,
-- Für Nachführungseinheit "Kanton" gibt es einen eigenen Basket
    CASE typ.typ_kt
        WHEN 'E560_Nationalstrasse'
            THEN
               (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE  
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E561_Kantonsstrasse'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        ELSE erschliessung_flaechenobjekt_dokument.t_basket
    END AS t_basket,
-- Für Nachführungseinheit "Kanton" gibt es einen eigenes Dataset
    CASE typ_kt
        WHEN 'E560_Nationalstrasse'
            THEN 'Kanton'
        WHEN 'E561_Kantonsstrasse'
            THEN 'Kanton'
        ELSE erschliessung_flaechenobjekt_dokument.t_datasetname
    END AS t_datasetname,
    erschliessung_flaechenobjekt_dokument.typ_erschliessung_flaechenobjekt,
    erschliessung_flaechenobjekt_dokument.dokument
FROM
    arp_nutzungsplanung_import_v1.erschlssngsplnung_typ_erschliessung_flaechenobjekt_dokument AS erschliessung_flaechenobjekt_dokument
    LEFT JOIN arp_nutzungsplanung_import_v1.erschlssngsplnung_typ_erschliessung_flaechenobjekt AS typ
    ON typ.t_id = erschliessung_flaechenobjekt_dokument.typ_erschliessung_flaechenobjekt
;
-- Erschliessung Linie
INSERT INTO arp_nutzungsplanung_transfer_v1.erschlssngsplnung_typ_erschliessung_linienobjekt
SELECT
    t_id,
    -- Für Nachführungseinheit "Kanton" gibt es einen eigenen Basket
    CASE typ_kt
        WHEN 'E711_Baulinie_Strasse_kantonal'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E712_Vorbaulinie_kantonal'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E713_Gestaltungsbaulinie_kantonal'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E714_Rueckwaertige_Baulinie_kantonal'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E715_Baulinie_Infrastruktur_kantonal'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E719_weitere_nationale_und_kantonale_Baulinien'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        ELSE t_basket
    END AS t_basket,
-- Für Nachführungseinheit "Kanton" gibt es einen eigenes Dataset
    CASE typ_kt
        WHEN 'E711_Baulinie_Strasse_kantonal'
            THEN 'Kanton'
        WHEN 'E712_Vorbaulinie_kantonal'
            THEN 'Kanton'
        WHEN 'E713_Gestaltungsbaulinie_kantonal'
            THEN 'Kanton'
        WHEN 'E714_Rueckwaertige_Baulinie_kantonal'
            THEN 'Kanton'
        WHEN 'E715_Baulinie_Infrastruktur_kantonal'
            THEN 'Kanton'
        WHEN 'E719_weitere_nationale_und_kantonale_Baulinien'
            THEN 'Kanton'
        ELSE t_datasetname
    END AS t_datasetname,
    t_ili_tid,
    typ_kt,
    code_kommunal,
    bezeichnung,
    abkuerzung,
    verbindlichkeit,
    bemerkungen
FROM
    arp_nutzungsplanung_import_v1.erschlssngsplnung_typ_erschliessung_linienobjekt
WHERE
    typ_kt != 'E710_nationale_Baulinie'
;

INSERT INTO arp_nutzungsplanung_transfer_v1.erschlssngsplnung_erschliessung_linienobjekt
SELECT
    erschliessung_linienobjekt.t_id,
  -- Für Nachführungseinheit "Kanton" gibt es einen eigenen Basket
    CASE typ.typ_kt
        WHEN 'E711_Baulinie_Strasse_kantonal'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E712_Vorbaulinie_kantonal'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E713_Gestaltungsbaulinie_kantonal'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E714_Rueckwaertige_Baulinie_kantonal'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E715_Baulinie_Infrastruktur_kantonal'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E719_weitere_nationale_und_kantonale_Baulinien'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        ELSE  erschliessung_linienobjekt.t_basket
    END AS t_basket,
  -- Für Nachführungseinheit "Kanton" gibt es einen eigenes Dataset
    CASE typ.typ_kt
        WHEN 'E711_Baulinie_Strasse_kantonal'
            THEN 'Kanton'
        WHEN 'E712_Vorbaulinie_kantonal'
            THEN 'Kanton'
        WHEN 'E713_Gestaltungsbaulinie_kantonal'
            THEN 'Kanton'
        WHEN 'E714_Rueckwaertige_Baulinie_kantonal'
            THEN 'Kanton'
        WHEN 'E715_Baulinie_Infrastruktur_kantonal'
            THEN 'Kanton'
        WHEN 'E719_weitere_nationale_und_kantonale_Baulinien'
            THEN 'Kanton'
        ELSE erschliessung_linienobjekt.t_datasetname
    END AS t_datasetname,
    erschliessung_linienobjekt.t_ili_tid,
    erschliessung_linienobjekt.geometrie,
    erschliessung_linienobjekt.name_nummer AS geschaefts_nummer,
    CASE rechtsstatus
        WHEN 'laufendeAenderung'
            THEN 'AenderungMitVorwirkung'
        ELSE 'inKraft'
    END AS rechtsstatus,
    erschliessung_linienobjekt.publiziertab,
    erschliessung_linienobjekt.bemerkungen,
    erschliessung_linienobjekt.erfasser,
    erschliessung_linienobjekt.datum,
    NULL AS publiziertbis,
    erschliessung_linienobjekt.typ_erschliessung_linienobjekt
FROM
    arp_nutzungsplanung_import_v1.erschlssngsplnung_erschliessung_linienobjekt AS erschliessung_linienobjekt
    LEFT JOIN arp_nutzungsplanung_import_v1.erschlssngsplnung_typ_erschliessung_linienobjekt AS typ
    ON typ.t_id = erschliessung_linienobjekt.typ_erschliessung_linienobjekt
WHERE
    typ_kt != 'E710_nationale_Baulinie'
;

INSERT INTO arp_nutzungsplanung_transfer_v1.erschlssngsplnung_typ_erschliessung_linienobjekt_dokument
SELECT
    erschliessung_linienobjekt_dokument.t_id,
  -- Für Nachführungseinheit "Kanton" gibt es einen eigenen Basket
    CASE typ.typ_kt
        WHEN 'E711_Baulinie_Strasse_kantonal'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E712_Vorbaulinie_kantonal'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E713_Gestaltungsbaulinie_kantonal'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E714_Rueckwaertige_Baulinie_kantonal'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E715_Baulinie_Infrastruktur_kantonal'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        WHEN 'E719_weitere_nationale_und_kantonale_Baulinien'
            THEN
                (SELECT
                    t_id
                FROM
                    arp_nutzungsplanung_transfer_v1.t_ili2db_basket
                WHERE 
                    topic ='SO_Nutzungsplanung_Nachfuehrung_20201005.Erschliessungsplanung'
                    AND
                    attachmentkey = 'Nachfuehrung_Kanton')
        ELSE  erschliessung_linienobjekt_dokument.t_basket
    END AS t_basket,
  -- Für Nachführungseinheit "Kanton" gibt es einen eigenes Dataset
    CASE typ.typ_kt
        WHEN 'E711_Baulinie_Strasse_kantonal'
            THEN 'Kanton'
        WHEN 'E712_Vorbaulinie_kantonal'
            THEN 'Kanton'
        WHEN 'E713_Gestaltungsbaulinie_kantonal'
            THEN 'Kanton'
        WHEN 'E714_Rueckwaertige_Baulinie_kantonal'
            THEN 'Kanton'
        WHEN 'E715_Baulinie_Infrastruktur_kantonal'
            THEN 'Kanton'
        WHEN 'E719_weitere_nationale_und_kantonale_Baulinien'
            THEN 'Kanton'
        ELSE erschliessung_linienobjekt_dokument.t_datasetname
    END AS t_datasetname,
    erschliessung_linienobjekt_dokument.typ_erschliessung_linienobjekt,
    erschliessung_linienobjekt_dokument.dokument
FROM
    arp_nutzungsplanung_import_v1.erschlssngsplnung_typ_erschliessung_linienobjekt_dokument AS erschliessung_linienobjekt_dokument
    LEFT JOIN arp_nutzungsplanung_import_v1.erschlssngsplnung_typ_erschliessung_linienobjekt AS typ
    ON typ.t_id = erschliessung_linienobjekt_dokument.typ_erschliessung_linienobjekt
WHERE
    typ_kt != 'E710_nationale_Baulinie'
;
-- Erschliessung Punkt
INSERT INTO arp_nutzungsplanung_transfer_v1.erschlssngsplnung_typ_erschliessung_punktobjekt
SELECT
    t_id,
    t_basket,
    t_datasetname,
    t_ili_tid,
    typ_kt,
    code_kommunal,
    bezeichnung,
    abkuerzung,
    verbindlichkeit,
    bemerkungen
FROM
    arp_nutzungsplanung_import_v1.erschlssngsplnung_typ_erschliessung_punktobjekt
;

INSERT INTO arp_nutzungsplanung_transfer_v1.erschlssngsplnung_erschliessung_punktobjekt
SELECT
    t_id,
    t_basket,
    t_datasetname,
    t_ili_tid,
    geometrie,
    name_nummer AS geschaefts_nummer,
    CASE rechtsstatus
        WHEN 'laufendeAenderung'
            THEN 'AenderungMitVorwirkung'
        ELSE 'inKraft'
    END AS rechtsstatus,
    publiziertab,
    bemerkungen,
    erfasser,
    datum,
    NULL AS publiziertbis,
    typ_erschliessung_punktobjekt
FROM
    arp_nutzungsplanung_import_v1.erschlssngsplnung_erschliessung_punktobjekt
;

INSERT INTO arp_nutzungsplanung_transfer_v1.erschlssngsplnung_typ_erschliessung_punktobjekt_dokument
SELECT
    t_id,
    t_basket,
    t_datasetname,
    typ_erschliessung_punktobjekt,
    dokument
FROM
    arp_nutzungsplanung_import_v1.erschlssngsplnung_typ_erschliessung_punktobjekt_dokument
;
-- Lärmempfindlichkeitsstufen
INSERT INTO arp_nutzungsplanung_transfer_v1.laermmpfhktsstfen_typ_empfindlichkeitsstufe
SELECT
    t_id,
    t_basket,
    t_datasetname,
    t_ili_tid,
    typ_kt,
    bezeichnung,
    abkuerzung,
    verbindlichkeit,
    bemerkungen
FROM
    arp_nutzungsplanung_import_v1.nutzungsplanung_typ_ueberlagernd_flaeche
WHERE
    typ_kt= 'N680_Empfindlichkeitsstufe_I'
    OR
    typ_kt= 'N681_Empfindlichkeitsstufe_II'
    OR
    typ_kt= 'N682_Empfindlichkeitsstufe_II_aufgestuft'
    OR
    typ_kt= 'N683_Empfindlichkeitsstufe_III'
    OR
    typ_kt= 'N684_Empfindlichkeitsstufe_III_aufgestuft'
    OR
    typ_kt= 'N685_Empfindlichkeitsstufe_IV'
    OR
    typ_kt= 'N686_keine_Empfindlichkeitsstufe'
;

INSERT INTO arp_nutzungsplanung_transfer_v1.laermmpfhktsstfen_empfindlichkeitsstufe
SELECT
    ueberlagernd_flaeche.t_id,
    ueberlagernd_flaeche.t_basket,
    ueberlagernd_flaeche.t_datasetname,
    ueberlagernd_flaeche.t_ili_tid,
    ueberlagernd_flaeche.geometrie,
    ueberlagernd_flaeche.name_nummer AS geschaefts_nummer,
    CASE ueberlagernd_flaeche.rechtsstatus
        WHEN 'laufendeAenderung'
            THEN 'AenderungMitVorwirkung'
    END AS rechtsstatus,
    ueberlagernd_flaeche.publiziertab,
    ueberlagernd_flaeche.bemerkungen,
    ueberlagernd_flaeche.erfasser,
    ueberlagernd_flaeche.datum,
    NULL AS publiziertbis,
    ueberlagernd_flaeche.typ_ueberlagernd_flaeche AS typ_empfindlichkeitsstufen
FROM
    arp_nutzungsplanung_import_v1.nutzungsplanung_ueberlagernd_flaeche AS ueberlagernd_flaeche
    LEFT JOIN arp_nutzungsplanung_import_v1.nutzungsplanung_typ_ueberlagernd_flaeche AS typ
    ON typ.t_id = ueberlagernd_flaeche.typ_ueberlagernd_flaeche
WHERE
    typ.typ_kt= 'N680_Empfindlichkeitsstufe_I'
    OR
    typ.typ_kt= 'N681_Empfindlichkeitsstufe_II'
    OR
    typ.typ_kt= 'N682_Empfindlichkeitsstufe_II_aufgestuft'
    OR
    typ.typ_kt= 'N683_Empfindlichkeitsstufe_III'
    OR
    typ.typ_kt= 'N684_Empfindlichkeitsstufe_III_aufgestuft'
    OR
    typ.typ_kt= 'N685_Empfindlichkeitsstufe_IV'
    OR
    typ.typ_kt= 'N686_keine_Empfindlichkeitsstufe'
;

INSERT INTO arp_nutzungsplanung_transfer_v1.laermmpfhktsstfen_typ_empfindlichkeitsstufe_dokument
SELECT
    ueberlagernd_flaeche_dokument.t_id,
    ueberlagernd_flaeche_dokument.t_basket,
    ueberlagernd_flaeche_dokument.t_datasetname,
    ueberlagernd_flaeche_dokument.dokument,
    ueberlagernd_flaeche_dokument.typ_ueberlagernd_flaeche AS typ_empfindlichkeitsstufen
FROM
    arp_nutzungsplanung_import_v1.nutzungsplanung_typ_ueberlagernd_flaeche_dokument AS ueberlagernd_flaeche_dokument
    LEFT JOIN arp_nutzungsplanung_import_v1.nutzungsplanung_typ_ueberlagernd_flaeche AS typ
    ON typ.t_id = ueberlagernd_flaeche_dokument.typ_ueberlagernd_flaeche
WHERE
    typ.typ_kt= 'N680_Empfindlichkeitsstufe_I'
    OR
    typ.typ_kt= 'N681_Empfindlichkeitsstufe_II'
    OR
    typ.typ_kt= 'N682_Empfindlichkeitsstufe_II_aufgestuft'
    OR
    typ.typ_kt= 'N683_Empfindlichkeitsstufe_III'
    OR
    typ.typ_kt= 'N684_Empfindlichkeitsstufe_III_aufgestuft'
    OR
    typ.typ_kt= 'N685_Empfindlichkeitsstufe_IV'
    OR
    typ.typ_kt= 'N686_keine_Empfindlichkeitsstufe'
;

--Datasetname "Kanton" und der entsprechenden Basket bei Dokumente aktuallisieren
--nutzungsplanung_typ_ueberlagernd_flaeche_dokument
UPDATE arp_nutzungsplanung_transfer_v1.rechtsvorschrften_dokument
SET
    t_datasetname =ueberlagernd_flaeche_dokument.t_datasetname,
    t_basket=basket.t_id
FROM
    arp_nutzungsplanung_transfer_v1.nutzungsplanung_typ_ueberlagernd_flaeche_dokument AS ueberlagernd_flaeche_dokument,
    arp_nutzungsplanung_transfer_v1.t_ili2db_basket AS basket,
    arp_nutzungsplanung_transfer_v1.t_ili2db_dataset AS dataset
WHERE
    ueberlagernd_flaeche_dokument.dokument=arp_nutzungsplanung_transfer_v1.rechtsvorschrften_dokument.t_id
    AND
    ueberlagernd_flaeche_dokument.t_datasetname=dataset.datasetname
    AND
    basket.topic = 'SO_Nutzungsplanung_Nachfuehrung_20201005.Rechtsvorschriften'
    AND
    dataset.t_id=basket.dataset
;
--erschlssngsplnung_typ_erschliessung_flaechenobjekt_dokument
UPDATE arp_nutzungsplanung_transfer_v1.rechtsvorschrften_dokument
SET
    t_datasetname =erschliessung_flaechenobjekt_dokument.t_datasetname,
    t_basket=basket.t_id
FROM
    arp_nutzungsplanung_transfer_v1.erschlssngsplnung_typ_erschliessung_flaechenobjekt_dokument AS erschliessung_flaechenobjekt_dokument,
    arp_nutzungsplanung_transfer_v1.t_ili2db_basket AS basket,
    arp_nutzungsplanung_transfer_v1.t_ili2db_dataset AS dataset
WHERE
    erschliessung_flaechenobjekt_dokument.dokument=arp_nutzungsplanung_transfer_v1.rechtsvorschrften_dokument.t_id
    AND
    erschliessung_flaechenobjekt_dokument.t_datasetname=dataset.datasetname
    AND
    basket.topic = 'SO_Nutzungsplanung_Nachfuehrung_20201005.Rechtsvorschriften'
    AND
    dataset.t_id=basket.dataset
;
--erschlssngsplnung_typ_erschliessung_linienobjekt_dokument
UPDATE arp_nutzungsplanung_transfer_v1.rechtsvorschrften_dokument
SET
     t_datasetname =erschliessung_linienobjekt_dokument.t_datasetname,
     t_basket=basket.t_id
FROM
    arp_nutzungsplanung_transfer_v1.erschlssngsplnung_typ_erschliessung_linienobjekt_dokument AS erschliessung_linienobjekt_dokument,
    arp_nutzungsplanung_transfer_v1.t_ili2db_basket AS basket,
    arp_nutzungsplanung_transfer_v1.t_ili2db_dataset AS dataset
WHERE
    erschliessung_linienobjekt_dokument.dokument=arp_nutzungsplanung_transfer_v1.rechtsvorschrften_dokument.t_id
    AND
    erschliessung_linienobjekt_dokument.t_datasetname=dataset.datasetname
    AND
    basket.topic = 'SO_Nutzungsplanung_Nachfuehrung_20201005.Rechtsvorschriften'
    AND
    dataset.t_id=basket.dataset
;

-- erschliessung_flaechenobjekt_dokument aktualliseren für Datasetname "Kanton" und der entsprechenden Basket z.B. Trottoir usw. aus kantonalem Erschliessungsplan
--UPDATE arp_nutzungsplanung_transfer_v1.erschlssngsplnung_typ_erschliessung_flaechenobjekt_dokument
-- Achtung bei Oensingen ist das nicht sinnvoll, überhaupt sinnvoll?
--SET
--    t_datasetname =dokument.t_datasetname,
--    t_basket=dokument.t_basket
--FROM
--     arp_nutzungsplanung_transfer_v1.rechtsvorschrften_dokument AS dokument
--WHERE
--     dokument.t_id=arp_nutzungsplanung_transfer_v1.erschlssngsplnung_typ_erschliessung_flaechenobjekt_dokument.dokument
-- erschliessung_flaechenobjekt_dokument aktualliseren für Datasetname "Kanton" und der entsprechenden Basket z.B. Trottoir usw. aus kantonalem Erschliessungsplan
--UPDATE arp_nutzungsplanung_transfer_v1.erschlssngsplnung_typ_erschliessung_flaechenobjekt
--SET
--     t_datasetname =erschliessung_flaechenobjekt_dokument.t_datasetname,
--     t_basket=erschliessung_flaechenobjekt_dokument.t_basket
--FROM
--     arp_nutzungsplanung_transfer_v1.erschlssngsplnung_typ_erschliessung_flaechenobjekt_dokument AS erschliessung_flaechenobjekt_dokument
--WHERE
--     erschliessung_flaechenobjekt_dokument.typ_erschliessung_flaechenobjekt=arp_nutzungsplanung_transfer_v1.erschlssngsplnung_typ_erschliessung_flaechenobjekt.t_id
