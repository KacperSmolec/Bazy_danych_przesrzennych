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












