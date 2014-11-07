use DW_user4;

-- Limpieza a Provincia
-- Obtenemos que Cartago, Guanacaste, Limon y Puntarenas tienen geometrias no validas
SELECT Provincia, geom.STIsValid()
FROM provinciaTmp;

-- Remover la provincia con forma de cuadrado alrededor de la isla del Coco
Delete from provinciaTmp
Where PROVINCIA = 'NA';

-- Validar
UPDATE provinciaTmp
SET geom = geometry::STGeomFromWKB(geom.MakeValid().STAsBinary(), geom.STSrid)
WHERE geom.STIsValid() = 0;
-- Ahora todas son validas

-- Cerrar geometrias
UPDATE provinciaTmp
SET geom = geometry::STGeomFromWKB(geom.STUnion(geom.STStartPoint()).STAsBinary(), geom.STSrid);

-- Smoothing
UPDATE provinciaTmp
SET geom = geometry::STGeomFromWKB(geom.STBuffer(0.00001).STBuffer(-0.00001).STAsBinary(), geom.STSrid);

-- Remover puntos de mas
UPDATE provinciaTmp
SET geom = geometry::STGeomFromWKB(geom.Reduce(0.00001).STAsBinary(), geom.STSrid);

Select Provincia, geom from provinciaTmp;

Select P1.Provincia, P2.Provincia
From provinciaTmp P1, provinciaTmp P2
Where P1.geom.STIntersects(P2.geom) = 1 AND P1.COD_PROV < P2.COD_PROV;

-- Importar
Insert into Provincia
Select COD_PROV, PROVINCIA, geom From provinciaTmp;

Select * from Provincia;



-- Limpieza a Canton
-- 5 Cantones con geometrias invalidas
SELECT NCANTON, geom.STIsValid()
FROM cantonTmp
Where geom.STIsValid() = 0;

-- Validar
UPDATE cantonTmp
SET geom = geometry::STGeomFromWKB(geom.MakeValid().STAsBinary(), geom.STSrid)
WHERE geom.STIsValid() = 0;
-- Ahora todas son validas

-- Cerrar geometrias
UPDATE cantonTmp
SET geom = geometry::STGeomFromWKB(geom.STUnion(geom.STStartPoint()).STAsBinary(), geom.STSrid);

-- Smoothing
UPDATE cantonTmp
SET geom = geometry::STGeomFromWKB(geom.STBuffer(0.00001).STBuffer(-0.00001).STAsBinary(), geom.STSrid);

-- Remover puntos de mas
UPDATE cantonTmp
SET geom = geometry::STGeomFromWKB(geom.Reduce(0.00001).STAsBinary(), geom.STSrid);

Select * from cantonTmp;

-- Sin embargo, hay 62 cantones que intersecan con mas de una provincia...
Select NCANTON
From cantonTmp C join provinciaTmp P on C.geom.STIntersects(P.geom) = 1
Group by NCANTON
Having count(*) > 1;


-- Limpieza de Distrito
-- 4 geometrias invalidas
SELECT NDISTRITO, geom.STIsValid()
FROM distritoTmp
Where geom.STIsValid() = 0;

-- Validar
UPDATE distritoTmp
SET geom = geometry::STGeomFromWKB(geom.MakeValid().STAsBinary(), geom.STSrid)
WHERE geom.STIsValid() = 0;
-- Ahora todas son validas

-- Cerrar geometrias
UPDATE distritoTmp
SET geom = geometry::STGeomFromWKB(geom.STUnion(geom.STStartPoint()).STAsBinary(), geom.STSrid);

-- Smoothing
UPDATE distritoTmp
SET geom = geometry::STGeomFromWKB(geom.STBuffer(0.00001).STBuffer(-0.00001).STAsBinary(), geom.STSrid);

-- Remover puntos de mas
UPDATE distritoTmp
SET geom = geometry::STGeomFromWKB(geom.Reduce(0.00001).STAsBinary(), geom.STSrid);

Select * from distritoTmp;

-- Ocurre que hay distritos que no son unicos...
Select CODDIST, count(*)
From distritoTmp
Group by CODDIST
Having count(*) > 2;

-- Para exportar a la tabla distrito hay que hacer union de geometrias mediante coddist
Select CODDIST, NDISTRITO, geometry::UnionAggregate( geom )
From distritoTmp
Group By CODDIST, NDISTRITO;

