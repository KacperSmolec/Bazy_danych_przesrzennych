CREATE EXTENSION postgis;

CREATE TABLE obiekty(
	id int PRIMARY KEY,
	nazwa varchar(40),
	geometria geometry
);
-------------------------------------------------------------------------------------
--zad1
-------------------------------------------------------------------------------------
INSERT INTO obiekty VALUES
(1, 'obiekt1', ST_Collect(ARRAY['LINESTRING(0 1, 1 1)', 'CIRCULARSTRING(1 1, 2 0, 3 1)', 'CIRCULARSTRING(3 1, 4 2, 5 1)', 'LINESTRING(5 1, 6 1)'])),
(2, 'obiekt2', ST_Collect(ARRAY['LINESTRING(10 6, 14 6)', 'CIRCULARSTRING(14 6, 16 4, 14 2)', 'CIRCULARSTRING(14 2, 12 0, 10 2)', 'LINESTRING(10 2, 10 6)', 'CIRCULARSTRING(11 2, 12 1, 13 2, 12 3, 11 2)'])),
(3, 'obiekt3', 'POLYGON((7 15, 12 13, 10 17, 7 15))'),
(4, 'obiekt4', 'LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)'),
(5, 'obiekt5', ST_Collect(ARRAY['POINT(30 30 59)', 'POINT(38 32 234)'])),
(6, 'obiekt6', ST_Collect(ARRAY['LINESTRING(1 1, 3 2)', 'POINT(4 2)']));

-------------------------------------------------------------------------------------
--zad2
-------------------------------------------------------------------------------------
SELECT
    ST_Area(ST_Buffer(ST_ShortestLine(o1.geometria, o2.geometria), 5)) AS pole_buforu
FROM
    obiekty AS o1
CROSS JOIN
    obiekty AS o2
WHERE
    o1.nazwa = 'obiekt3'
    AND o2.nazwa = 'obiekt4';
	
-------------------------------------------------------------------------------------
--zad3
-------------------------------------------------------------------------------------
UPDATE obiekty
SET geometria = (
    SELECT
        ST_MakePolygon(ST_AddPoint(ST_AsText(geometria)::geometry, ST_MakePoint(20, 20)))
    FROM
        obiekty
    WHERE
        nazwa = 'obiekt4'
)
WHERE
    nazwa = 'obiekt4';

-------------------------------------------------------------------------------------
--zad4
-------------------------------------------------------------------------------------
WITH CTE_ObjectGeoms AS (
    SELECT
        o1.geometria AS obiekt3_geom,
        o2.geometria AS obiekt4_geom
    FROM
        obiekty AS o1
        CROSS JOIN obiekty AS o2
    WHERE
        o1.nazwa = 'obiekt3'
        AND o2.nazwa = 'obiekt4'
)

INSERT INTO obiekty (id, nazwa, geometria)
SELECT
    7,
    'obiekt7',
    ST_Collect(ARRAY[(SELECT obiekt3_geom FROM CTE_ObjectGeoms), (SELECT obiekt4_geom FROM CTE_ObjectGeoms)]);

-------------------------------------------------------------------------------------
--zad5
-------------------------------------------------------------------------------------
SELECT
	SUM(ST_Area(ST_Buffer(geometria, 5))) AS pole_powierzchni
FROM obiekty
WHERE ST_HasArc(geometria) = false;