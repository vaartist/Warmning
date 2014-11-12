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

Delete from cantonTmp
Where NCANTON = 'NA';

Select * from cantonTmp;

-- Sin embargo, hay 62 cantones que intersecan con mas de una provincia...
Select NCANTON
From cantonTmp C join provinciaTmp P on C.geom.STIntersects(P.geom) = 1
Group by NCANTON
Having count(*) > 1;

-- Ejecutar cuando exista el trigger
Insert into Canton
Select codnum, ncanton, null, geom From cantonTmp;



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

Delete from distritoTmp
Where NDISTRITO = 'NA';

-- Ocurre que hay distritos que no son unicos...
Select CODDIST
From distritoTmp
Group by CODDIST
Having count(*) > 2;

-- Para exportar a la tabla distrito hay que hacer union de geometrias mediante coddist
Create Table distritoTmp2
(
	ID			int primary key,
	NDistrito	nvarchar(255),
	CODDIST		int,
	geom		geometry
);

Declare @ID integer,
		@NDistrito nvarchar(255),
		@Coddist int,
		@Geom geometry,
		@UnionGeo geometry
SET @ID = 1
Declare distritos_repetidos cursor for
	Select distinct CODDIST, NDISTRITO
	From distritoTmp
OPEN distritos_repetidos
FETCH NEXT FROM distritos_repetidos INTO @Coddist, @NDistrito
WHILE( @@FETCH_STATUS = 0 )
BEGIN
	-- Ciclo anidado
	Declare distritos_codigo cursor for
		Select geom
		From distritoTmp
		Where CODDIST = @Coddist
	OPEN distritos_codigo
	FETCH NEXT FROM distritos_codigo INTO @Geom
	WHILE( @@FETCH_STATUS = 0 )
	BEGIN
		SET @UnionGeo = @Geom.STUnion( @UnionGeo ) 
		FETCH NEXT FROM distritos_codigo INTO @Geom
	END
	INSERT INTO distritoTmp2 VALUES( @ID, @NDistrito, @Coddist, @Geom )
	CLOSE distritos_codigo
	DEALLOCATE distritos_codigo
	-- Fin ciclo anidado

	SET @ID = @ID + 1
	FETCH NEXT FROM distritos_repetidos INTO @Coddist, @NDistrito
END
CLOSE distritos_repetidos
DEALLOCATE distritos_repetidos

Select * from distritoTmp2;
Delete from distritoTmp2;

Drop Table distritoTmp2;

-- ¡Ya son unicos!
Select CODDIST
From distritoTmp2
Group by CODDIST
Having count(*) > 2;

-- Ejecutar cuando exista el trigger y los distritos sean unicos
Insert into Distrito
Select CODDIST, NDISTRITO, null, null, null, null, null, null, geom From distritoTmp2;



-- Limpieza de Bomberos
-- No hay geometrias invalidas
SELECT NOMBRE, geom.STIsValid()
FROM bomberosTmp
Where geom.STIsValid() = 0;

Select * from bomberosTmp;

-- Ejecutar cuando exista el trigger
Insert into Estacion_Bomberos
Select Nombre, Direccion, 0, geom From bomberosTmp;

Insert into Unidades_Estacion_Bomberos
Select Nombre, 'Extintoras', dbo.ParseNumber(Extintoras) From bomberosTmp Where NOMBRE in ( Select Nombre from Estacion_Bomberos );
Insert into Unidades_Estacion_Bomberos
Select Nombre, 'Rescate', dbo.ParseNumber(Rescate) From bomberosTmp Where NOMBRE in ( Select Nombre from Estacion_Bomberos );
Insert into Unidades_Estacion_Bomberos
Select Nombre, 'Forestales', dbo.ParseNumber(Forestales) From bomberosTmp Where NOMBRE in ( Select Nombre from Estacion_Bomberos );

-- No se pudo insertar 2 estaciones de bomberos puesto su geometria no coincidia con ningun distrito



-- Limpieza de Zonas Riesgo
-- Todas las geometrias son validas
SELECT CLASIFICAC, RIESGO, MESSEC, geom.STIsValid()
FROM zonas_riesgoTmp
Where geom.STIsValid() = 0;

-- Cerrar geometrias
UPDATE zonas_riesgoTmp
SET geom = geometry::STGeomFromWKB(geom.STUnion(geom.STStartPoint()).STAsBinary(), geom.STSrid);

-- Smoothing
UPDATE zonas_riesgoTmp
SET geom = geometry::STGeomFromWKB(geom.STBuffer(0.00001).STBuffer(-0.00001).STAsBinary(), geom.STSrid);

-- Remover puntos de mas
UPDATE zonas_riesgoTmp
SET geom = geometry::STGeomFromWKB(geom.Reduce(0.00001).STAsBinary(), geom.STSrid);

Select * from zonas_riesgoTmp;

-- Hay 2 que no cumplen la tercera forma normal como se propuso
Select grupo.messec, grupo.clasificac
From (Select distinct messec, clasificac, RIESGO
		From zonas_riesgoTmp) grupo
Group by MESSEC, CLASIFICAC
having count(*) > 1;

-- Ocupo el aggregate para unir las zonas por la llave

-- Ejecutar cuando el trigger que calcula las areas exista y los datos sean validos
Insert into Zonas_Riesgo
Select messec, clasificac, riesgo from zonas_riesgoTmp;



-- Limpieza de Caminos
-- 20 geometrias invalidas
SELECT Ruta, geom.STIsValid()
FROM caminoTmp
Where geom.STIsValid() = 0;

-- Validar
UPDATE caminoTmp
SET geom = geometry::STGeomFromWKB(geom.MakeValid().STAsBinary(), geom.STSrid)
WHERE geom.STIsValid() = 0;
-- Ahora todas son validas

-- Smoothing
UPDATE caminoTmp
SET geom = geometry::STGeomFromWKB(geom.STBuffer(0.00001).STBuffer(-0.00001).STAsBinary(), geom.STSrid);

-- Remover puntos de mas
UPDATE caminoTmp
SET geom = geometry::STGeomFromWKB(geom.Reduce(0.00001).STAsBinary(), geom.STSrid);

-- Unir caminos con mismo nombre
CREATE TABLE caminoTmp2(
	id INT,
	Ruta VARCHAR(255),
	Tipo VARCHAR(15),
	Geom geometry
);

DROP TABLE caminoTmp2;


Select * from caminoTmp;

