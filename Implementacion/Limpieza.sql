use DW_user4;

--Limpieza a Provincia
--Obtenemos que Cartago, Guanacaste, Limon y Puntarenas tienen geometrias no validas
SELECT Provincia, geom.STIsValid()
FROM provinciaTmp;

--Remover la provincia con forma de cuadrado alrededor de la isla del Coco
Delete from provinciaTmp
Where PROVINCIA = 'NA';

--Validar
UPDATE provinciaTmp
SET geom = geometry::STGeomFromWKB(geom.MakeValid().STAsBinary(), geom.STSrid)
WHERE geom.STIsValid() = 0;
--Ahora todas son validas

--Cerrar geometrias
UPDATE provinciaTmp
SET geom = geometry::STGeomFromWKB(geom.STUnion(geom.STStartPoint()).STAsBinary(), geom.STSrid);

--Smoothing
UPDATE provinciaTmp
SET geom = geometry::STGeomFromWKB(geom.STBuffer(0.00001).STBuffer(-0.00001).STAsBinary(), geom.STSrid);

--Remover puntos de mas
UPDATE provinciaTmp
SET geom = geometry::STGeomFromWKB(geom.Reduce(0.00001).STAsBinary(), geom.STSrid);

Select Provincia, geom from provinciaTmp;

Select P1.Provincia, P2.Provincia
From provinciaTmp P1, provinciaTmp P2
Where P1.geom.STIntersects(P2.geom) = 1 AND P1.COD_PROV < P2.COD_PROV;

--Importar
Insert into Provincia
Select COD_PROV, PROVINCIA, geom From provinciaTmp;

Select * from Provincia;



--Limpieza a Canton
--5 Cantones con geometrias invalidas
SELECT NCANTON, geom.STIsValid()
FROM cantonTmp
Where geom.STIsValid() = 0;

--Validar
UPDATE cantonTmp
SET geom = geometry::STGeomFromWKB(geom.MakeValid().STAsBinary(), geom.STSrid)
WHERE geom.STIsValid() = 0;
--Ahora todas son validas

--Cerrar geometrias
UPDATE cantonTmp
SET geom = geometry::STGeomFromWKB(geom.STUnion(geom.STStartPoint()).STAsBinary(), geom.STSrid);

--Smoothing
UPDATE cantonTmp
SET geom = geometry::STGeomFromWKB(geom.STBuffer(0.00001).STBuffer(-0.00001).STAsBinary(), geom.STSrid);

--Remover puntos de mas
UPDATE cantonTmp
SET geom = geometry::STGeomFromWKB(geom.Reduce(0.00001).STAsBinary(), geom.STSrid);

Delete from cantonTmp
Where NCANTON = 'NA';

Select * from cantonTmp;

--Sin embargo, hay 62 cantones que intersecan con mas de una provincia...
Select NCANTON
From cantonTmp C join provinciaTmp P on C.geom.STIntersects(P.geom) = 1
Group by NCANTON
Having count(*) > 1;

--Ejecutar cuando exista el trigger
Insert into Canton
Select codnum, ncanton, null, geom From cantonTmp;
UPDATE Canton SET Nombre='VASQUEZ DE CORONADO' WHERE Nombre='VAZQUEZ DE CORONADO';
UPDATE Canton SET Nombre='ZARCERO' WHERE Nombre='ALFARO RUIZ';
UPDATE CANTON SET NOMBRE = dbo.Normalizar_Nombre(Nombre);


--Limpieza de Distrito
--4 geometrias invalidas
SELECT NDISTRITO, geom.STIsValid()
FROM distritoTmp
Where geom.STIsValid() = 0;

--Validar
UPDATE distritoTmp
SET geom = geometry::STGeomFromWKB(geom.MakeValid().STAsBinary(), geom.STSrid)
WHERE geom.STIsValid() = 0;
--Ahora todas son validas

--Cerrar geometrias
UPDATE distritoTmp
SET geom = geometry::STGeomFromWKB(geom.STUnion(geom.STStartPoint()).STAsBinary(), geom.STSrid);

--Smoothing
UPDATE distritoTmp
SET geom = geometry::STGeomFromWKB(geom.STBuffer(0.00001).STBuffer(-0.00001).STAsBinary(), geom.STSrid);

--Remover puntos de mas
UPDATE distritoTmp
SET geom = geometry::STGeomFromWKB(geom.Reduce(0.00001).STAsBinary(), geom.STSrid);

Select * from distritoTmp;

Delete from distritoTmp
Where NDISTRITO = 'NA';

--Ocurre que hay distritos que no son unicos...
Select CODDIST
From distritoTmp
Group by CODDIST
Having count(*) > 2;

--Para exportar a la tabla distrito hay que hacer union de geometrias mediante coddist
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
	--Ciclo anidado
	SET @UnionGeo = null
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
	--Fin ciclo anidado

	SET @ID = @ID + 1
	FETCH NEXT FROM distritos_repetidos INTO @Coddist, @NDistrito
END
CLOSE distritos_repetidos
DEALLOCATE distritos_repetidos

Select * from distritoTmp2;
Delete from distritoTmp2;

Drop Table distritoTmp2;

--¡Ya son unicos!
Select CODDIST
From distritoTmp2
Group by CODDIST
Having count(*) > 2;

--Ejecutar cuando exista el trigger y los distritos sean unicos
Insert into Distrito
Select CODDIST, NDISTRITO, null, null, null, null, null, null, geom From distritoTmp2;

Select * from Distrito

UPDATE Distrito SET Nombre='SAN FRANCISCO DE DOS RIOS' WHERE Nombre='SAN FCO. DE DOS RIOS';
UPDATE Distrito SET Nombre='LA TRINIDAD' WHERE Nombre='TRINIDAD';
UPDATE Distrito SET Nombre='EL GENERAL' WHERE Nombre='GENERAL';
UPDATE Distrito SET Nombre='SAN ISIDRO DE EL GENERAL' WHERE Nombre='SAN ISIDRO DEL GENERAL';
UPDATE Distrito SET Nombre='LA GRANJA' WHERE Nombre='GRANJA';
UPDATE Distrito SET Nombre='EL ROSARIO' WHERE Nombre='ROSARIO';
UPDATE Distrito SET Nombre='LA CEIBA' WHERE Nombre='CEIBA';
UPDATE Distrito SET Nombre='SAN JOSECITO' WHERE Nombre='SAN JOCESITO';
UPDATE Distrito SET Nombre='EL MASTATE' WHERE Nombre='MASTATE';
UPDATE Distrito SET Nombre='BUENAVISTA' WHERE Nombre='BUENA VISTA';
UPDATE Distrito SET Nombre='LA FORTUNA' WHERE Nombre='FORTUNA';
UPDATE Distrito SET Nombre='LA PALMERA' WHERE Nombre='PALMERA';
UPDATE Distrito SET Nombre='LA TIGRA' WHERE Nombre='TIGRA';
UPDATE Distrito SET Nombre='LAS JUNTAS' WHERE Nombre='JUNTAS';
UPDATE Distrito SET Nombre='LAS HORQUETAS' WHERE Nombre='HORQUETAS';
UPDATE Distrito SET Nombre='EL TEJAR' WHERE Nombre='TEJAR';
UPDATE Distrito SET Nombre='LA UNION' WHERE Nombre='UNION';
UPDATE Distrito SET Nombre='EL CAIRO' WHERE Nombre='CAIRO';
UPDATE Distrito SET Nombre='COLORADO' WHERE Nombre='COLORADO (CMD)';
UPDATE Distrito SET Nombre='LA ASUNCION' WHERE Nombre='ASUNCION';
UPDATE Distrito SET Nombre='VALLE LA ESTRELLA' WHERE Nombre='VALLE DE LA ESTRELLA';
UPDATE Distrito SET NOMBRE = LTRIM(RTRIM(dbo.Normalizar_Nombre(Nombre)));

--Limpieza de Bomberos
--No hay geometrias invalidas
SELECT NOMBRE, geom.STIsValid()
FROM bomberosTmp
Where geom.STIsValid() = 0;

Select * from bomberosTmp;

--Ejecutar cuando exista el trigger
Insert into Estacion_Bomberos
Select Nombre, Direccion, 0, geom From bomberosTmp;

Insert into Unidades_Estacion_Bomberos
Select Nombre, 'Extintoras', dbo.ParseNumber(Extintoras) From bomberosTmp Where NOMBRE in ( Select Nombre from Estacion_Bomberos );
Insert into Unidades_Estacion_Bomberos
Select Nombre, 'Rescate', dbo.ParseNumber(Rescate) From bomberosTmp Where NOMBRE in ( Select Nombre from Estacion_Bomberos );
Insert into Unidades_Estacion_Bomberos
Select Nombre, 'Forestales', dbo.ParseNumber(Forestales) From bomberosTmp Where NOMBRE in ( Select Nombre from Estacion_Bomberos );

--No se pudo insertar 2 estaciones de bomberos puesto su geometria no coincidia con ningun distrito



--Limpieza de Zonas Riesgo
--Todas las geometrias son validas
SELECT CLASIFICAC, RIESGO, MESSEC, geom.STIsValid()
FROM zonas_riesgoTmp
Where geom.STIsValid() = 0;

--Cerrar geometrias
UPDATE zonas_riesgoTmp
SET geom = geometry::STGeomFromWKB(geom.STUnion(geom.STStartPoint()).STAsBinary(), geom.STSrid);

--Smoothing
UPDATE zonas_riesgoTmp
SET geom = geometry::STGeomFromWKB(geom.STBuffer(0.00001).STBuffer(-0.00001).STAsBinary(), geom.STSrid);

--Remover puntos de mas
UPDATE zonas_riesgoTmp
SET geom = geometry::STGeomFromWKB(geom.Reduce(0.00001).STAsBinary(), geom.STSrid);

Select * from zonas_riesgoTmp;

--Hay 2 que no cumplen la tercera forma normal como se propuso
Select grupo.messec, grupo.clasificac
From (Select distinct messec, clasificac, RIESGO
		From zonas_riesgoTmp) grupo
Group by MESSEC, CLASIFICAC
having count(*) > 1;


--Unir las Zonas Riesgo por llave
Create table zonas_riesgoTmp2
(
	ID			int primary key,
	MESSEC		int,
	CLASIFICAC	nvarchar(255),
	RIESGO		nvarchar(255),
	geom		geometry
);

Declare @ID integer,
		@MESSEC nvarchar(255),
		@CLASIFICAC nvarchar(255),
		@RIESGO nvarchar(255),
		@RIESGO2 nvarchar(255),
		@Geom geometry,
		@UnionGeo geometry
SET @ID = 1
Declare zonas_repetidas cursor for
	Select distinct MESSEC, CLASIFICAC
	From zonas_riesgoTmp
OPEN zonas_repetidas
FETCH NEXT FROM zonas_repetidas INTO @MESSEC, @CLASIFICAC
WHILE( @@FETCH_STATUS = 0 )
BEGIN
	--Ciclo anidado
	SET @UnionGeo = null
	Declare zonas_llave cursor for
		Select geom
		From zonas_riesgoTmp
		Where MESSEC = @MESSEC AND CLASIFICAC = @CLASIFICAC
	OPEN zonas_llave
	FETCH NEXT FROM zonas_llave INTO @Geom
	WHILE( @@FETCH_STATUS = 0 )
	BEGIN
		SET @UnionGeo = @Geom.STUnion( @UnionGeo ) 
		FETCH NEXT FROM zonas_llave INTO @Geom
	END

	--Revisamos si rompe tercera forma normal
	Declare v cursor for
		Select DISTINCT RIESGO
		From zonas_riesgoTmp
		Where MESSEC = @MESSEC AND CLASIFICAC = @CLASIFICAC
		Group by MESSEC, CLASIFICAC, RIESGO
	OPEN v
	FETCH FROM v into @RIESGO
	FETCH NEXT FROM v into @RIESGO2
	IF( @@FETCH_STATUS = 0 )
		SET @RIESGO = 'BAJO-MEDIO'
	CLOSE v
	DEALLOCATE v
	--

	INSERT INTO zonas_riesgoTmp2 VALUES( @ID, @MESSEC, @CLASIFICAC, @RIESGO, @Geom )
	CLOSE zonas_llave
	DEALLOCATE zonas_llave
	--Fin ciclo anidado

	SET @ID = @ID + 1
	FETCH NEXT FROM zonas_repetidas INTO @MESSEC, @CLASIFICAC
END
CLOSE zonas_repetidas
DEALLOCATE zonas_repetidas

--Ya estan agrupadas y cumplen la tercera forma normal propuesta
Select * from zonas_riesgoTmp2;

--Eliminar caracteres innecesarios
UPDATE zonas_riesgoTmp2 SET CLASIFICAC = dbo.Eliminar_Alfabeticos(CLASIFICAC);

--Ejecutar cuando el trigger que calcula las areas exista y los datos sean validos
Insert into Zonas_Riesgo
Select messec, clasificac,riesgo,geom from zonas_riesgoTmp2;



--Limpieza de Caminos
--20 geometrias invalidas
SELECT Ruta, geom.STIsValid()
FROM caminoTmp
Where geom.STIsValid() = 0;

--Validar
UPDATE caminoTmp
SET geom = geometry::STGeomFromWKB(geom.MakeValid().STAsBinary(), geom.STSrid)
WHERE geom.STIsValid() = 0;
--Ahora todas son validas

--Smoothing
UPDATE caminoTmp
SET geom = geometry::STGeomFromWKB(geom.STBuffer(0.00001).STBuffer(-0.00001).STAsBinary(), geom.STSrid);

--Remover puntos de mas
UPDATE caminoTmp
SET geom = geometry::STGeomFromWKB(geom.Reduce(0.00001).STAsBinary(), geom.STSrid);

--Unir caminos con mismo nombre
CREATE TABLE caminoTmp2(
	id INT,
	Ruta VARCHAR(255),
	Tipo VARCHAR(15),
	Geom geometry
);

DROP TABLE caminoTmp2;


--Un problema en el archivo de viviendas y poblacion
UPDATE viviendasYpoblacion SET Lugar = 'San José' WHERE Lugar='San José o Pizote';
UPDATE viviendasYpoblacion SET Lugar = 'Aguacaliente' WHERE Lugar='Aguacaliente o San Francisco';
UPDATE viviendasYpoblacion SET Lugar = 'Guadalupe' WHERE Lugar='Guadalupe o Arenilla';
UPDATE viviendasYpoblacion SET Lugar = 'Puerto Carrillo' WHERE Lugar='Puente Carrillo';
UPDATE viviendasYpoblacion SET Lugar = LTRIM(RTRIM(Lugar));
