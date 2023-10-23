CREATE EXTENSION postgis;

CREATE SCHEMA lab2;

CREATE TABLE lab2.buildings(
	ID SERIAL PRIMARY KEY,
	geometry GEOMETRY,
	"name" VARCHAR(50)
);

CREATE TABLE lab2.roads(
	ID SERIAL PRIMARY KEY,
	geometry GEOMETRY,
	"name" VARCHAR(50)
);

INSERT INTO lab2.buildings("name", geometry) VALUES
('BuildingA', 'POLYGON((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))'),
('BuildingB', 'POLYGON((6 5, 6 7, 4 7, 4 5, 6 5))'),
('BuildingC', 'POLYGON((3 6, 5 6, 5 8, 3 8, 3 6))'),
('BuildingD', 'POLYGON((9 8, 10 8, 10 9, 9 9, 9 8))'),
('BuildingF', 'POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))')


INSERT INTO lab2.roads("name", geometry) VALUES
('RoadX', 'LINESTRING(0 4.5, 12 4.5)'),
('RoadY', 'LINESTRING(7.5 10.5, 7.5 0)')

INSERT INTO lab2.poi("name", geometry) VALUES
('G', 'POINT(1 3.5)'),
('H', 'POINT(5.5 1.5)'),
('I', 'POINT(9.5 6)'),
('J', 'POINT(6.5 6)'),
('K', 'POINT(6 9.5)')


-- ex 6 

-- a
SELECT SUM(ST_LENGTH(geometry)) AS total_road_length FROM lab2.roads;


-- b
SELECT geometry, ST_AREA(geometry) AS area, ST_PERIMETER(geometry) AS perimeter
FROM lab2.buildings
WHERE "name" = 'BuildingA';

-- c
SELECT "name", ST_AREA(geometry) AS area
FROM lab2.buildings
ORDER BY "name";

-- d
SELECT "name", ST_PERIMETER(geometry) AS perimeter
FROM lab2.buildings
ORDER BY ST_AREA(geometry) DESC
LIMIT 2;

-- e
SELECT ST_DISTANCE(t1.geometry, t2.geometry)
FROM (SELECT "name", geometry FROM lab2.poi WHERE "name" = 'K') t1
CROSS JOIN (SELECT "name", geometry FROM lab2.buildings WHERE "name" = 'BuildingC') t2;

-- f
SELECT ST_AREA(ST_DIFFERENCE(t1.geometry, ST_EXPAND(t2.geometry, 0.5)))
FROM (SELECT "name", geometry FROM lab2.buildings WHERE "name" = 'BuildingC') t1
CROSS JOIN (SELECT "name", geometry FROM lab2.buildings WHERE "name" = 'BuildingB') t2;

-- g
SELECT *
FROM lab2.buildings AS b
WHERE ST_Y(ST_CENTROID(b.geometry)) > (
  SELECT ST_Y(ST_CENTROID(r.geometry))
  FROM lab2.roads AS r
  WHERE r."name" = 'RoadX'
);

-- h

SELECT ST_AREA(ST_SYMDIFFERENCE(geometry, 'POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'))
FROM lab2.buildings
WHERE "name" = 'BuildingC';



------------------------------------ LAB 3
------------------------------------ LAB 3
------------------------------------ LAB 3
------------------------------------ LAB 3
------------------------------------ LAB 3
------------------------------------ LAB 3
------------------------------------ LAB 3
------------------------------------ LAB 3
------------------------------------ LAB 3
------------------------------------ LAB 3
------------------------------------ LAB 3



-- zad 1
SELECT
    t19.name AS b19_name,
    ST_AsText(t19.geom) AS b19_geom,
    t18.name AS b18_name,
    ST_AsText(t18.geom) AS b18_geom
FROM t2019_kar_buildings AS t19
LEFT JOIN t2018_kar_buildings AS t18
ON t19.polygon_id = t18.polygon_id
WHERE t18.polygon_id IS NULL OR ST_AsText(t18.geom) <> ST_AsText(t19.geom);

	
--zad 2

CREATE VIEW n_building_change AS
SELECT
    b19.*
FROM t2019_kar_buildings AS b19
LEFT JOIN t2018_kar_buildings AS b18
    ON b19.polygon_id = b18.polygon_id
WHERE b18.polygon_id IS NULL 
    OR ST_AsText(b18.geom) != ST_AsText(b19.geom);

CREATE VIEW fresh_poi AS
SELECT
    p19.*
FROM t2018_kar_poi_table AS p19
LEFT JOIN t2019_kar_poi_table AS p18
    ON p19.poi_id = p18.poi_id
WHERE p18.poi_id IS NULL;

SELECT
    np.type,
    COUNT(np.gid) AS count
FROM fresh_poi AS np
JOIN n_building_change AS cnb
    ON ST_Intersects(ST_Buffer(cnb.geom, 0.005), np.geom)
GROUP BY np.type;

-- 
-----  zad 3 
-- 
	
CREATE TABLE streets_reprojected AS
	SELECT
		gid
		, link_id
		, st_name
		, ref_in_id
		, nref_in_id
		, func_class
		, speed_cat
		, fr_speed_l
		, to_speed_l
		, dir_travel
		, ST_SetSRID(geom, 3068) AS geom
	FROM t2019_kar_streets;

-- 
---- zad 4
-- 

CREATE TABLE input_points (
    gid serial PRIMARY KEY,
    geom geometry(Point, 4326)
);
DROP TABLE input_points;

INSERT INTO input_points (geom) VALUES
(ST_GeomFromText('POINT(8.36093 49.03174)', 3068)),
(ST_GeomFromText('POINT(8.39876 49.00644)', 3068));


--zad 5
UPDATE input_points
SET geom = ST_SetSRID(ST_AsText(geom), 4326)


--zad 6
update t2019_kar_street_node set geom = st_transform(st_setsrid(geom, 4326), 3068)


CREATE VIEW line_points AS
	SELECT
		ST_Makeline(geom) AS geom
	FROM input_points

SELECT sn19.node_id
FROM t2019_kar_street_node AS sn19
JOIN line_points AS lp
	ON ST_Contains(ST_Buffer(lp.geom, 0.02), sn19.geom)
	
--zad 7

SELECT
	COUNT(*)
FROM t2019_kar_poi_table AS p
JOIN t2019_kar_land_use_a AS lu
	ON ST_Intersects(ST_Buffer(lu.geom, 0.003), p.geom)
WHERE p.type = 'Sporting Goods Store';


--zad 8

CREATE TABLE T2019_KAR_BRIDGES AS
SELECT
    ST_Intersection(r.geom, wl.geom) AS geom
FROM t2019_kar_railways r
JOIN t2019_kar_water_lines wl ON ST_Intersects(r.geom, wl.geom);








