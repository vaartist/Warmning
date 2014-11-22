USE DW_user4;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

-- 1) Selecciona la union de las tablas Distrito y Canton, tal que el distrito este contenido en el canton en mas de un 90% y el Canton pertenezca a San Jose
-- Tiempo de duración sin índices:
SELECT * FROM Distrito a,Canton c
WHERE c.CodigoProvincia=1 AND
a.Codigo IN( 
	SELECT d.Codigo FROM Distrito d 
	WHERE c.Geom.STIntersects(d.Geom)=1
)
AND a.Geom.STIntersection(c.Geom).STArea()/a.Geom.STArea() > 0.9;

-- Tiempo de duración con índices en HIGH: 27s
CREATE SPATIAL INDEX IX_distrito_geom ON Distrito ( Geom ) WITH (bounding_box = ( 283582.5, 889283.75, 658921.875, 1241133.25 ), GRIDS = (HIGH,HIGH,HIGH,HIGH));
CREATE SPATIAL INDEX IX_canton_geom ON Canton (Geom) WITH (bounding_box = ( 283582.5, 889283.75, 658921.875, 1241133.25 ), GRIDS = (HIGH,HIGH,HIGH,HIGH));

-- Tiempo de duración con índices en LOW: 14s
CREATE SPATIAL INDEX IX_distrito_geom ON Distrito ( Geom ) WITH (bounding_box = ( 283582.5, 889283.75, 658921.875, 1241133.25 ), GRIDS = (LOW,LOW,LOW,LOW));
CREATE SPATIAL INDEX IX_canton_geom ON Canton (Geom) WITH (bounding_box = ( 283582.5, 889283.75, 658921.875, 1241133.25 ), GRIDS = (LOW,LOW,LOW,LOW));

-- Borra los índices sobre las tablas
DROP INDEX IX_distrito_geom ON Distrito;
DROP INDEX IX_canton_geom ON Canton;

---------------------------------------------------------------------------------------------

-- 2) Select de los distritos en los cuales hay estaciones de bomberos
-- Tiempo de duración sin índices: 4s
SELECT * FROM Distrito
WHERE Codigo IN (
	SELECT DISTINCT(d.Codigo) FROM Distrito d WITH(INDEX(IX_distrito_geom)),Estacion_Bomberos e
	WHERE e.Geom.STIntersects(d.Geom)=1
);

-- Tiempo de duración con índices en HIGH: 1s
CREATE SPATIAL INDEX IX_distrito_geom ON Distrito ( Geom ) WITH (bounding_box = ( 283582.5, 889283.75, 658921.875, 1241133.25 ), GRIDS = (HIGH,HIGH,HIGH,HIGH));
CREATE SPATIAL INDEX IX_estacion_geom ON Estacion_Bomberos (Geom) WITH (bounding_box = ( 283582.5, 889283.75, 658921.875, 1241133.25 ), GRIDS = (HIGH,HIGH,HIGH,HIGH));

-- Tiempo de duración con índices en LOW: 0s
CREATE SPATIAL INDEX IX_distrito_geom ON Distrito ( Geom ) WITH (bounding_box = ( 283582.5, 889283.75, 658921.875, 1241133.25 ), GRIDS = (LOW,LOW,LOW,LOW));
CREATE SPATIAL INDEX IX_estacion_geom ON Estacion_Bomberos (Geom) WITH (bounding_box = ( 283582.5, 889283.75, 658921.875, 1241133.25 ), GRIDS = (LOW,LOW,LOW,LOW));

-- Borra los índices sobre las tablas
DROP INDEX IX_distrito_geom ON Distrito;
DROP INDEX IX_estacion_geom ON Estacion_Bomberos;

---------------------------------------------------------------------------------------------

-- 3) Selecciona los caminos que intersecan en algun punto al distrito de San Isidro de el General (codigo 11901)

SELECT * FROM Camino
WHERE NumeroRuta IN(
	SELECT c.NumeroRuta FROM Distrito d,Camino c WITH(INDEX(IX_camino_geom))
	WHERE d.Geom.STIntersects(c.Geom)=1
	AND d.Codigo=11901
);

CREATE SPATIAL INDEX IX_camino_geom ON Camino( Geom ) WITH (bounding_box = ( 283582.5, 889283.75, 658921.875, 1241133.25 ), GRIDS = (HIGH,HIGH,HIGH,HIGH));
CREATE SPATIAL INDEX IX_camino_geom ON Camino( Geom ) WITH (bounding_box = ( 283582.5, 889283.75, 658921.875, 1241133.25 ), GRIDS = (LOW,LOW,LOW,LOW));
DROP INDEX IX_camino_geom ON Camino;
