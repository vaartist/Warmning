use DW_user4;

--Limpieza a Provincia
--Obtenemos que Cartago, Guanacaste, Limon y Puntarenas tienen geometrias no válidas
SELECT Provincia, geom.STIsValid()
FROM provinciaTmp;
--

--Remover la provincia con FORma de cuadrado alrededor de la isla del Coco
DELETE FROM provinciaTmp
WHERE PROVINCIA = 'NA';
--

--Validar
UPDATE provinciaTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.MakeValid().STAsBinary(), geom.STSrid)
WHERE geom.STIsValid() = 0;
--Ahora todas son válidas
--

--Cerrar geometrias
UPDATE provinciaTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.STUnion(geom.STStartPoint()).STAsBinary(), geom.STSrid);
--

--Smoothing
UPDATE provinciaTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.STBuffer(0.00001).STBuffer(-0.00001).STAsBinary(), geom.STSrid);
--

--Remover puntos de mas
UPDATE provinciaTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.Reduce(0.00001).STAsBinary(), geom.STSrid);

SELECT Provincia, GEOM FROM provinciaTmp;

SELECT P1.Provincia, P2.Provincia
FROM provinciaTmp P1, provinciaTmp P2
WHERE P1.geom.STIntersects(P2.geom) = 1 AND P1.COD_PROV < P2.COD_PROV;
--

--Importar
INSERT INTO Provincia
SELECT COD_PROV, PROVINCIA, GEOM FROM provinciaTmp;

SELECT * FROM Provincia;
--



--Limpieza a Canton
--5 Cantones con geometrias inválidas
SELECT NCANTON, geom.STIsValid()
FROM cantonTmp
WHERE geom.STIsValid() = 0;
--

--Validar
UPDATE cantonTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.MakeValid().STAsBinary(), geom.STSrid)
WHERE geom.STIsValid() = 0;
--Ahora todas son válidas
--

--Cerrar geometrias
UPDATE cantonTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.STUnion(geom.STStartPoint()).STAsBinary(), geom.STSrid);
--

--Smoothing
UPDATE cantonTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.STBuffer(0.00001).STBuffer(-0.00001).STAsBinary(), geom.STSrid);
--

--Remover puntos de mas
UPDATE cantonTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.Reduce(0.00001).STAsBinary(), geom.STSrid);
--

DELETE FROM cantonTmp
WHERE NCANTON = 'NA';

SELECT * FROM cantonTmp;
--

--Sin embargo, hay 62 cantones que intersecan con más de una provincia...
SELECT NCANTON
FROM cantonTmp C join provinciaTmp P on C.geom.STIntersects(P.geom) = 1
GROUP BY NCANTON
HAVING COUNT(*) > 1;
--

--Ejecutar cuando exista el trigger
INSERT INTO Canton
SELECT codnum, ncanton, null, GEOM FROM cantonTmp;
UPDATE Canton SET Nombre='VASQUEZ DE CORONADO' WHERE Nombre='VAZQUEZ DE CORONADO';
UPDATE Canton SET Nombre='ZARCERO' WHERE Nombre='ALFARO RUIZ';
UPDATE CANTON SET NOMBRE = dbo.Normalizar_Nombre(Nombre);
--



--Limpieza de Distrito
--4 geometrias inválidas
SELECT NDISTRITO, geom.STIsValid()
FROM distritoTmp
WHERE geom.STIsValid() = 0;
--

DELETE FROM distritoTmp
WHERE NDISTRITO = 'NA';

--Validar
UPDATE distritoTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.MakeValid().STAsBinary(), geom.STSrid)
WHERE geom.STIsValid() = 0;
--Ahora todas son válidas
--

--Cerrar geometrias
UPDATE distritoTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.STUnion(geom.STStartPoint()).STAsBinary(), geom.STSrid);
--

--Smoothing
UPDATE distritoTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.STBuffer(0.00001).STBuffer(-0.00001).STAsBinary(), geom.STSrid);
--

--Remover puntos de mas
UPDATE distritoTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.Reduce(0.00001).STAsBinary(), geom.STSrid);

SELECT * FROM distritoTmp;


--

--Ocurre que hay distritos que no son unicos...
SELECT CODDIST
FROM distritoTmp
GROUP BY CODDIST
HAVING COUNT(*) > 2;
--

--Para exportar a la tabla distrito hay que hacer union de geometrias mediante coddist
Create TABLE distritoTmp2
(
	ID			INT PRIMARY KEY,
	NDistrito	NVARCHAR(255),
	CODDIST		INT,
	geom		GEOMETRY
);

DECLARE @ID INT,
		@NDistrito NVARCHAR(255),
		@Coddist INT,
		@GEOM GEOMETRY,
		@UnionGeo GEOMETRY
SET @ID = 1
DECLARE distritos_repetidos CURSOR FOR
	SELECT DISTINCT CODDIST, NDISTRITO
	FROM distritoTmp
OPEN distritos_repetidos
FETCH NEXT FROM distritos_repetidos INTO @Coddist, @NDistrito
WHILE( @@FETCH_STATUS = 0 )
BEGIN
	--Ciclo anidado
	SET @UnionGeo = null
	DECLARE distritos_codigo CURSOR FOR
		SELECT geom
		FROM distritoTmp
		WHERE CODDIST = @Coddist
	OPEN distritos_codigo
	FETCH FROM distritos_codigo INTO @Geom
	WHILE( @@FETCH_STATUS = 0 )
	BEGIN
		IF( @UnionGeo.IsNull = 0 )
			SET @UnionGeo = @UnionGeo.STUnion( @GEOM )
		ELSE
			SET @UnionGeo = @GEOM
		FETCH NEXT FROM distritos_codigo INTO @Geom
	END
	INSERT INTO distritoTmp2 VALUES( @ID, @NDistrito, @Coddist, @UnionGeo )
	CLOSE distritos_codigo
	DEALLOCATE distritos_codigo
	--Fin ciclo anidado

	SET @ID = @ID + 1
	FETCH NEXT FROM distritos_repetidos INTO @Coddist, @NDistrito
END
CLOSE distritos_repetidos
DEALLOCATE distritos_repetidos

SELECT * FROM distritoTmp2;
DELETE FROM distritoTmp2;

DROP TABLE distritoTmp2;
--

--¡Ya son unicos!
SELECT CODDIST
FROM distritoTmp2
GROUP BY CODDIST
HAVING COUNT(*) > 2;
--

--Ejecutar cuando exista el trigger y los distritos sean unicos
INSERT INTO Distrito
SELECT CODDIST, NDISTRITO, null, null, null, null, null, null, GEOM FROM distritoTmp2;

SELECT * FROM Distrito
--Correcciones manuales
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
--

--Limpieza de Bomberos
--No hay geometrias inválidas
SELECT NOMBRE, geom.STIsValid()
FROM bomberosTmp
WHERE geom.STIsValid() = 0;

SELECT * FROM bomberosTmp;
--

--Ejecutar cuando exista el trigger
INSERT INTO Estacion_Bomberos
SELECT Nombre, Direccion, 0, GEOM FROM bomberosTmp;

INSERT INTO Unidades_Estacion_Bomberos
SELECT Nombre, 'Extintoras', dbo.ParseNumber(Extintoras) FROM bomberosTmp WHERE NOMBRE in ( SELECT Nombre FROM Estacion_Bomberos );
INSERT INTO Unidades_Estacion_Bomberos
SELECT Nombre, 'Rescate', dbo.ParseNumber(Rescate) FROM bomberosTmp WHERE NOMBRE in ( SELECT Nombre FROM Estacion_Bomberos );
INSERT INTO Unidades_Estacion_Bomberos
SELECT Nombre, 'Forestales', dbo.ParseNumber(Forestales) FROM bomberosTmp WHERE NOMBRE in ( SELECT Nombre FROM Estacion_Bomberos );
--No se pudo insertar 2 estaciones de bomberos puesto su geometria no coincidia con ningun distrito
--



--Limpieza de Zonas Riesgo
--Todas las geometrias son válidas
SELECT CLASIFICAC, RIESGO, MESSEC, geom.STIsValid()
FROM zonas_riesgoTmp
WHERE geom.STIsValid() = 0;
--

--Cerrar geometrias
UPDATE zonas_riesgoTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.STUnion(geom.STStartPoint()).STAsBinary(), geom.STSrid);
--

--Smoothing
UPDATE zonas_riesgoTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.STBuffer(0.00001).STBuffer(-0.00001).STAsBinary(), geom.STSrid);
--

--Remover puntos de mas
UPDATE zonas_riesgoTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.Reduce(0.00001).STAsBinary(), geom.STSrid);

SELECT * FROM zonas_riesgoTmp;
--

--Hay 2 que no cumplen la tercera forma normal como se propuso
SELECT grupo.messec, grupo.clasificac
FROM (SELECT DISTINCT messec, clasificac, RIESGO
		FROM zonas_riesgoTmp) grupo
GROUP BY MESSEC, CLASIFICAC
HAVING COUNT(*) > 1;
--


--Unir las Zonas Riesgo por llave
Create TABLE zonas_riesgoTmp2
(
	ID			INT PRIMARY KEY,
	MESSEC		INT,
	CLASIFICAC	NVARCHAR(255),
	RIESGO		NVARCHAR(255),
	geom		GEOMETRY
);

DECLARE @ID INT,
		@MESSEC NVARCHAR(255),
		@CLASIFICAC NVARCHAR(255),
		@RIESGO NVARCHAR(255),
		@RIESGO2 NVARCHAR(255),
		@GEOM GEOMETRY,
		@UnionGeo GEOMETRY
SET @ID = 1
DECLARE zonas_repetidas CURSOR FOR
	SELECT DISTINCT MESSEC, CLASIFICAC
	FROM zonas_riesgoTmp
OPEN zonas_repetidas
FETCH NEXT FROM zonas_repetidas INTO @MESSEC, @CLASIFICAC
WHILE( @@FETCH_STATUS = 0 )
BEGIN
	--Ciclo anidado
	SET @UnionGeo = null
	DECLARE zonas_llave CURSOR FOR
		SELECT geom
		FROM zonas_riesgoTmp
		WHERE MESSEC = @MESSEC AND CLASIFICAC = @CLASIFICAC
	OPEN zonas_llave
	FETCH NEXT FROM zonas_llave INTO @Geom
	WHILE( @@FETCH_STATUS = 0 )
	BEGIN
		IF( @UnionGeo.IsNull = 0 )
			SET @UnionGeo = @UnionGeo.STUnion( @GEOM )
		ELSE
			SET @UnionGeo = @GEOM
		FETCH NEXT FROM zonas_llave INTO @Geom
	END

	--Revisamos si rompe tercera forma normal
	DECLARE v CURSOR FOR
		SELECT DISTINCT RIESGO
		FROM zonas_riesgoTmp
		WHERE MESSEC = @MESSEC AND CLASIFICAC = @CLASIFICAC
		GROUP BY MESSEC, CLASIFICAC, RIESGO
	OPEN v
	FETCH FROM v INTO @RIESGO
	FETCH NEXT FROM v INTO @RIESGO2
	IF( @@FETCH_STATUS = 0 )
		SET @RIESGO = 'BAJO-MEDIO'
	CLOSE v
	DEALLOCATE v
	--

	INSERT INTO zonas_riesgoTmp2 VALUES( @ID, @MESSEC, @CLASIFICAC, @RIESGO, @UnionGeo )
	CLOSE zonas_llave
	DEALLOCATE zonas_llave
	--Fin ciclo anidado

	SET @ID = @ID + 1
	FETCH NEXT FROM zonas_repetidas INTO @MESSEC, @CLASIFICAC
END
CLOSE zonas_repetidas
DEALLOCATE zonas_repetidas
--

--Ya estan agrupadas y cumplen la tercera forma normal propuesta
SELECT * FROM zonas_riesgoTmp2;
--

--Eliminar caracteres innecesarios
UPDATE zonas_riesgoTmp2 SET CLASIFICAC = dbo.Eliminar_Alfabeticos(CLASIFICAC);
--

--Ejecutar cuando el trigger que calcula las areas exista y los datos sean validos
INSERT INTO Zonas_Riesgo
SELECT messec, clasificac,riesgo,GEOM FROM zonas_riesgoTmp2;
--



--Limpieza de Caminos
--20 geometrias inválidas
SELECT Ruta, geom.STIsValid()
FROM caminoTmp
WHERE geom.STIsValid() = 0;
--

--Validar
UPDATE caminoTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.MakeValid().STAsBinary(), geom.STSrid)
WHERE geom.STIsValid() = 0;
--Ahora todas son válidas
--

--Smoothing
UPDATE caminoTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.STBuffer(0.00001).STBuffer(-0.00001).STAsBinary(), geom.STSrid);
--

--Remover puntos de mas
UPDATE caminoTmp
SET GEOM = GEOMETRY::STGeomFromWKB(geom.Reduce(0.00001).STAsBinary(), geom.STSrid);
--

--Unir caminos con mismo nombre
DROP TABLE caminoTmp2
CREATE TABLE caminoTmp2(
	Id			INT				IDENTITY(1,1),
	Ruta		VARCHAR(1024),
	Tipo		VARCHAR(32),
	Longitud	FLOAT,
	geom		GEOMETRY
	CONSTRAINT PK_caminoTmp2 PRIMARY KEY(Id)
);
--Unir caminos con el mismo nombre, genera una única tupla con el primer tipo encontrado de entre
--los caminos del mismo nombre, con la suma de sus longitudes, y con la unión de sus geometrías
DECLARE @Ruta			VARCHAR(1024),
		@Tipo			VARCHAR(32),
		@SumaLongitudes	FLOAT,
		@GEO			GEOMETRY,
		@UnionGeom		GEOMETRY
DECLARE cursor_tabla CURSOR FOR
	SELECT		DISTINCT RUTA
	FROM		caminoTmp
	WHERE		RUTA != 'ND'
OPEN cursor_tabla
FETCH NEXT FROM cursor_tabla INTO @Ruta
WHILE( @@FETCH_STATUS = 0 )
BEGIN
	SET @UnionGeom = null
	DECLARE cursor_interno CURSOR FOR
		SELECT	geom
		FROM	caminoTmp
		WHERE	RUTA = @Ruta
	OPEN cursor_interno
	FETCH FROM cursor_interno INTO @GEO
	WHILE( @@FETCH_STATUS = 0 )
	BEGIN
		IF( @UnionGeom.IsNull = 0 )
			SET @UnionGeom = @UnionGeom.STUnion( @GEO )
		ELSE
			SET @UnionGeom = @GEO
		FETCH NEXT FROM cursor_interno INTO @GEO
	END
	SET	@Tipo =				(SELECT	TOP 1 TIPO		FROM	caminoTmp	WHERE	RUTA = @Ruta)
	SET	@SumaLongitudes =	(SELECT	SUM(LONGITUD)	FROM	caminoTmp	WHERE	RUTA = @Ruta)
	INSERT INTO caminoTmp2 VALUES(@Ruta, @Tipo, @SumaLongitudes, @UnionGeom)
	CLOSE cursor_interno
	DEALLOCATE cursor_interno
	--PRINT 'Insertada la ruta ' + @Ruta
	FETCH NEXT FROM cursor_tabla INTO @Ruta
END
CLOSE cursor_tabla
DEALLOCATE cursor_tabla
--
--ahora insertar las sin nombre
DECLARE @Tipo			VARCHAR(32),
		@Longitud		FLOAT,
		@GEOM			GEOMETRY
DECLARE cursor_tabla CURSOR FOR
	SELECT		TIPO, LONGITUD, geom
	FROM		caminoTmp
	WHERE		RUTA = 'ND'
OPEN cursor_tabla
FETCH NEXT FROM cursor_tabla INTO @Tipo, @Longitud, @GEOM
WHILE( @@FETCH_STATUS = 0 )
BEGIN
	INSERT INTO caminoTmp2 VALUES('ND', @Tipo, @Longitud, @GEOM)
	FETCH NEXT FROM cursor_tabla INTO @Tipo, @Longitud, @GEOM
END
CLOSE cursor_tabla
DEALLOCATE cursor_tabla
--
--Luego borrar geometrías repetidas
--
DECLARE @ID		INT,
		@Geom	GEOMETRY
--Declararar el cursor
DECLARE	cursor_tabla CURSOR FOR
SELECT		ID, geom
FROM		caminoTmp2
--Abrir cursor y usar FETCH
OPEN cursor_tabla
FETCH cursor_tabla INTO @ID, @Geom
WHILE(@@FETCH_STATUS = 0)
BEGIN
	DELETE	FROM caminoTmp2
	WHERE	@Geom.STEquals(geom) = 1 AND ID != @ID
	FETCH NEXT FROM cursor_tabla INTO @ID, @Geom
END
--Cerrar cursor
CLOSE cursor_tabla
DEALLOCATE cursor_tabla
--
--
--
--Revisiones:
SELECT		DISTINCT RUTA
FROM		caminoTmp
WHERE		RUTA != 'ND'
--2658 rutas con nombre (distinto)
SELECT		COUNT(*)
FROM		caminoTmp
WHERE		RUTA = 'ND'
--100102 sin nombre
--102760 rutas en total
--
SELECT	*
FROM	caminoTmp2
WHERE	RUTA != 'ND'
--2658 filas de rutas con nombre y unidas, bien
SELECT		COUNT(*)
FROM		caminoTmp2
WHERE		RUTA = 'ND'
--100102 rutas sin nombre, todo bien






DROP TABLE caminoTmp2;


--Un problema en el archivo de viviendas y poblacion
UPDATE viviendasYpoblacion SET Lugar = 'San José' WHERE Lugar='San José o Pizote';
UPDATE viviendasYpoblacion SET Lugar = 'Aguacaliente' WHERE Lugar='Aguacaliente o San Francisco';
UPDATE viviendasYpoblacion SET Lugar = 'Guadalupe' WHERE Lugar='Guadalupe o Arenilla';
UPDATE viviendasYpoblacion SET Lugar = 'Puerto Carrillo' WHERE Lugar='Puente Carrillo';
UPDATE viviendasYpoblacion SET Lugar = 'El Rosario' WHERE Lugar='Rosario';
UPDATE viviendasYpoblacion SET Lugar = LTRIM(RTRIM(Lugar));
--