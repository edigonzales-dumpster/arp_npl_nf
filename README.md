# arp_npl_nf

```
docker run --rm --name oerebdb -p 54323:5432 -e POSTGRES_PASSWORD=mysecretpassword -e POSTGRES_DB=edit -e POSTGRES_HOST_AUTH_METHOD=md5 -e PG_READ_PWD=dmluser -e PG_WRITE_PWD=ddluser -e GRETL_PG_WRITE_PWD=gretl sogis/oereb-db:2
```


--dbhost localhost --dbport 54321 --dbdatabase edit --dbusr gretl --dbpwd gretl \
--dbhost localhost --dbport 54321 --dbdatabase edit --dbusr gretl --dbpwd gretl \

```
java -jar /Users/stefan/apps/ili2h2gis-4.7.0/ili2h2gis-4.7.0.jar \
--dbfile arp_nutzungsplanung_datenumbau \
--dbschema arp_nutzungsplanung_import --models SO_Nutzungsplanung_20171118 \
--defaultSrsCode 2056 --createGeomIdx --createFk --createFkIdx --createUnique --createEnumTabs --beautifyEnumDispName --createMetaInfo --createNumChecks --nameByTopic --strokeArcs --sqlEnableNull \
--schemaimport
```

```
java -jar /Users/stefan/apps/ili2h2gis-4.7.0/ili2h2gis-4.7.0.jar \
--dbfile arp_nutzungsplanung_datenumbau \
--dbschema arp_nutzungsplanung_import --models SO_Nutzungsplanung_20171118 \
--defaultSrsCode 2056 --disableValidation \
--import 2498.xtf
```

```
java -jar /Users/stefan/apps/ili2h2gis-4.7.0/ili2h2gis-4.7.0.jar \
--dbfile arp_nutzungsplanung_datenumbau \
--dbschema arp_nutzungsplanung --models SO_ARP_Nutzungsplanung_Nachfuehrung_20201005 \
--defaultSrsCode 2056 --createGeomIdx --createFk --createFkIdx --createUnique --createEnumTabs --beautifyEnumDispName --createMetaInfo --createNumChecks --nameByTopic --strokeArcs \
--idSeqMin 1000000000000 \
--schemaimport
```

```
WITH RECURSIVE x(ursprung, hinweis, parents, last_ursprung, tiefe) AS 
(
    SELECT 
        ursprung, 
        hinweis, 
        ursprung AS parents, 
        ursprung AS last_ursprung, 
        0 AS tiefe 
    FROM 
        ARP_NUTZUNGSPLANUNG_IMPORT.RECHTSVORSCHRFTEN_HINWEISWEITEREDOKUMENTE
    WHERE
        ursprung != hinweis
        
    UNION ALL
  
    SELECT 
        x.ursprung, 
        x.hinweis, 
        parents||','||t1.hinweis, 
        t1.hinweis AS last_ursprung, 
        x.tiefe + 1
    FROM 
        x 
        INNER JOIN ARP_NUTZUNGSPLANUNG_IMPORT.RECHTSVORSCHRFTEN_HINWEISWEITEREDOKUMENTE t1 
        ON (last_ursprung = t1.ursprung)
    WHERE 
        t1.hinweis IS NOT NULL
)
SELECT * FROM x
```