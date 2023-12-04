CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;

--pg_restore.exe -h localhost -p 5432 -U postgres -d cw6 "C:\Users\kacper\Desktop\SEM_7\BazyDanychPrzestrzennych\lab6\postgis_raster.backup"

ALTER SCHEMA schema_name RENAME TO smolec;

--załadowanie rastrów do bazy:
--raster2pgsql.exe -s 3763 -N -32767 -t 100x100 -I -C -M -d "C:\Users\kacper\Desktop\SEM_7\BazyDanychPrzestrzennych\lab6\srtm_1arc_v3.tif" rasters.dem | psql -d cw6 -h localhost -U postgres -p 5432
--raster2pgsql.exe -s 3763 -N -32767 -t 128x128 -I -C -M -d "C:\Users\kacper\Desktop\SEM_7\BazyDanychPrzestrzennych\lab6\Landsat8_L1TP_RGBN.TIF" rasters.landsat8 | psql -d cw6 -h localhost -U postgres -p 5432

SELECT * FROM public.raster_columns

-----------------Tworzenie rastrów z istniejących rastrów i interakcja z wektorami------------------

--Przykład 1
CREATE TABLE smolec.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

alter table smolec.intersects
add column rid SERIAL PRIMARY KEY;

CREATE INDEX idx_intersects_rast_gist ON smolec.intersects
USING gist (ST_ConvexHull(rast));

-- schema::name table_name::name raster_column::name , dodanie raster constraints
SELECT AddRasterConstraints('smolec'::name,
'intersects'::name,'rast'::name);


--Przykład 2
--ST_Clip: Obcinanie rastra na podstawie wektora
CREATE TABLE smolec.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';


--Przykład 3
--ST_Union: Połączenie wielu kafelków w jeden raster
CREATE TABLE smolec.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);


-----------------Tworzenie rastrów z wektorów (rastrowanie)------------------

--Przykład 1
CREATE TABLE smolec.porto_parishes AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


--Przykład 2
--- ST_Union: Drugi przykład łączy rekordy z poprzedniego przykładu przy użyciu funkcji ST_UNION w pojedynczy raster
DROP TABLE smolec.porto_parishes; --> drop table porto_parishes first
CREATE TABLE smolec.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


--Przykład 3
--ST_Tile: Po uzyskaniu pojedynczego rastra można generować kafelki za pomocą funkcji ST_Tile
DROP TABLE smolec.porto_parishes; --> drop table porto_parishes first
CREATE TABLE smolec.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


-----------------Konwertowanie rastrów na wektory (wektoryzowanie)------------------

--Przykład 1
create table smolec.intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


--Przykład 2
--ST_DumpAsPolygons: konwertuje rastry w wektory (poligony), też zwraca zestaw wartości geomval
CREATE TABLE smolec.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


-----------------Analiza rastrów------------------

--Przykład 1
CREATE TABLE smolec.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;


--Przykład 2
CREATE TABLE smolec.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


--Przykład 3
CREATE TABLE smolec.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM smolec.paranhos_dem AS a;


--Przykład 4
CREATE TABLE smolec.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3','32BF',0)
FROM smolec.paranhos_slope AS a;


--Przykład 5
SELECT st_summarystats(a.rast) AS stats
FROM smolec.paranhos_dem AS a;


--Przykład 6
SELECT st_summarystats(ST_Union(a.rast))
FROM smolec.paranhos_dem AS a;


--Przykład 7
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM smolec.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;


--Przykład 8
WITH t AS (
	SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast, b.geom,true))) AS stats
	FROM rasters.dem AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
	group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;


--Przykład 9
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;


-----------------Topographic Position Index (TPI)------------------

--Przykład 10
create table smolec.tpi30 as		--58 secs 585 msecs
select ST_TPI(a.rast,1) as rast
from rasters.dem a;

create table smolec.tpi30_porto as		--3 secs 226 msecs
select ST_TPI(a.rast,1) as rast
from rasters.dem a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

CREATE INDEX idx_tpi30_rast_gist ON smolec.tpi30
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('smolec'::name,		--dodanie constraintów
'tpi30'::name,'rast'::name);



-----------------Algebra map------------------

--Przykład 1
--Wyrażenie Algebry Map

CREATE TABLE smolec.porto_ndvi AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, 1,
r.rast, 4,
'([rast2.val] - [rast1.val]) / ([rast2.val] +
[rast1.val])::float','32BF'
) AS rast
FROM r;

--Poniższe zapytanie utworzy indeks przestrzenny na wcześniej stworzonej tabeli:
CREATE INDEX idx_porto_ndvi_rast_gist ON smolec.porto_ndvi
USING gist (ST_ConvexHull(rast));

--Dodanie constraintów:
SELECT AddRasterConstraints('smolec'::name,
'porto_ndvi'::name,'rast'::name);


--Przykład 2
--Funkcja zwrotna
create or replace function smolec.ndvi(
	value double precision [] [] [],
	pos integer [][],
	VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
	--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

--W kwerendzie algebry map należy można wywołać zdefiniowaną wcześniej funkcję:
CREATE TABLE smolec.porto_ndvi2 AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, ARRAY[1,4],
'smolec.ndvi(double precision[],
integer[],text[])'::regprocedure, --> This is the function!
'32BF'::text
) AS rast
FROM r;

--Dodanie indeksu przestrzennego:
CREATE INDEX idx_porto_ndvi2_rast_gist ON smolec.porto_ndvi2
USING gist (ST_ConvexHull(rast));

--Dodanie constraintów:
SELECT AddRasterConstraints('smolec'::name,
'porto_ndvi2'::name,'rast'::name);


-----------------Eksport danych------------------

--Przykład 1 
--ST_AsTiff: tworzy dane wyjściowe jako binarną reprezentację pliku tiff
SELECT ST_AsTiff(ST_Union(rast))
FROM smolec.porto_ndvi;


--Przykład 2 
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM smolec.porto_ndvi;

SELECT ST_GDALDrivers();


--Przykład 3
CREATE TABLE tmp_out2 AS
SELECT lo_from_bytea(0,
 ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
 ) AS loid
FROM smolec.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'C:\Users\HP\Documents\Studia\Semestr 7\Bazy danych przestrzennych\lab6\myraster.tiff') --> Save the file in a place where the user postgres have access. In windows a flash drive usualy works fine.
FROM tmp_out2;
----------------------------------------------
SELECT lo_unlink(loid)
 FROM tmp_out2; --> Delete the large object.
 
 
 --Przykład 4

-----------------Rozwiązanie problemu postawionego we wcześniejszej części------------------
create table smolec.tpi30_porto as
SELECT ST_TPI(a.rast,1) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto'

--Dodanie indeksu przestrzennego:
CREATE INDEX idx_tpi30_porto_rast_gist ON smolec.tpi30_porto
USING gist (ST_ConvexHull(rast));

--Dodanie constraintów:
SELECT AddRasterConstraints('smolec'::name,
'tpi30_porto'::name,'rast'::name);