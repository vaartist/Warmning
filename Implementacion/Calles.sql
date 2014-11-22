--Forma alternativa de nombrar caminos
USE DW_user4;
--Antes de empezar hay que pasar todas las calles que ya tienen nombre de caminoTmp2 a Camino
--con bit de revisado en 0.
--Declarar variables para el cursor:
DECLARE	@NumeroRuta	VARCHAR(1024),
		@Tipo		VARCHAR(32),
		@Longitud	FLOAT,
		@Geom		GEOMETRY
--Declararar el cursor:
DECLARE cursor_calles_nombradas CURSOR FOR
	SELECT	RUTA, TIPO, LONGITUD, geom
	FROM	caminoTmp2
	WHERE	RUTA != 'ND'
--Abrir cursor y usar FETCH
OPEN cursor_calles_nombradas
FETCH cursor_calles_nombradas INTO @NumeroRuta, @Tipo, @Longitud, @Geom
WHILE(@@FETCH_STATUS = 0)
BEGIN
	INSERT INTO Camino
	VALUES(@NumeroRuta, @Tipo, @Longitud, @Geom, 0)
	FETCH NEXT FROM cursor_calles_nombradas INTO @NumeroRuta, @Tipo, @Longitud, @Geom
END
--Cerrar cursor
CLOSE		cursor_calles_nombradas
DEALLOCATE	cursor_calles_nombradas
--Fin



--Primero crear índices espaciales sobre ambas tablas
CREATE SPATIAL INDEX IX_Camino_Geom	ON Camino(Geom)
	WITH( BOUNDING_BOX = ( 283582.5, 889283.75, 658921.875, 1241133.25 ), GRIDS = (LOW, LOW, LOW, LOW));
CREATE SPATIAL INDEX IX_Camino_Geom	ON caminoTmp2(geom)
	WITH( BOUNDING_BOX = ( 283582.5, 889283.75, 658921.875, 1241133.25 ), GRIDS = (LOW, LOW, LOW, LOW));
--DROP INDEX IX_Camino_Geom	ON Camino
--DROP INDEX IX_Camino_Geom	ON caminoTmp2
--Se pueden volver a crear entre corridas del procedimiento para actualizarlos



--Segundo crear un cursor para iterar por las calles que ya tienen nombres pero no han sido revisadas,
--y por cada una usar otro cursor para iterar por las calles que se intersecan con esa y que no han sido
--insertadas, para insertarlas con un nombre dependiente de la primera.
--Inicio
WHILE((SELECT COUNT(*) FROM Camino WHERE Revisado = 0) > 0)
BEGIN
	DECLARE	@NumeroRutaNombrada		VARCHAR(895),
			@GeomRutaNombrada		GEOMETRY,
			@NumeroRutaNuevo		VARCHAR(895),
			@GeomRutaSinNombrar		GEOMETRY,
			@TipoRutaSinNombrar		VARCHAR(32),
			@LongitudRutaSinNombrar	FLOAT,
			@CantidadCallesHijas	INT,
			@IDRutaInsertada		INT
	--Declararar el cursor para calles nombradas
	DECLARE cursor_calles_nombradas CURSOR FOR
		SELECT	NumeroRuta, Geom
		FROM	Camino
		WHERE	Revisado = 0
	--Abrir cursor principal y usar FETCH
	OPEN	cursor_calles_nombradas
	FETCH	cursor_calles_nombradas INTO @NumeroRutaNombrada, @GeomRutaNombrada
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		--Declarar el cursor para calles sin nombrar
		DECLARE cursor_calles_sin_nombrar CURSOR FOR
			SELECT	ID, TIPO, LONGITUD, geom
			FROM	caminoTmp2
			WHERE	Ruta = 'ND' AND @GeomRutaNombrada.STIntersects(geom) = 1
		--Empezar
		SET		@CantidadCallesHijas = 1
		OPEN	cursor_calles_sin_nombrar
		FETCH	cursor_calles_sin_nombrar INTO @IDRutaInsertada, @TipoRutaSinNombrar, @LongitudRutaSinNombrar, @GeomRutaSinNombrar
		WHILE(@@FETCH_STATUS = 0)
		BEGIN
			SET		@NumeroRutaNuevo = (@NumeroRutaNombrada + '-' + CONVERT(VARCHAR(32), @CantidadCallesHijas))
			INSERT INTO Camino
			VALUES(@NumeroRutaNuevo, @TipoRutaSinNombrar, @LongitudRutaSinNombrar, @GeomRutaSinNombrar, 0)
			DELETE	FROM caminoTmp2
			WHERE	ID = @IDRutaInsertada
			SET		@CantidadCallesHijas = @CantidadCallesHijas + 1
			FETCH NEXT FROM cursor_calles_sin_nombrar INTO @TipoRutaSinNombrar, @LongitudRutaSinNombrar, @GeomRutaSinNombrar
		END
		CLOSE		cursor_calles_sin_nombrar
		DEALLOCATE	cursor_calles_sin_nombrar
		UPDATE	Camino
		SET		Revisado = 1
		WHERE	NumeroRuta = @NumeroRutaNombrada
		FETCH NEXT FROM cursor_calles_nombradas INTO @NumeroRutaNombrada, @GeomRutaNombrada
	END
	--Cerrar cursor
	CLOSE		cursor_calles_nombradas
	DEALLOCATE	cursor_calles_nombradas
END
--Fin


--Revisiones
--Cantidad de caminos insertados
SELECT	COUNT(*) AS Insertados
FROM	Camino
--Cantidad de caminos insertados revisados
SELECT	COUNT(*) AS Revisados
FROM	Camino
WHERE	Revisado = 1
--Cantidad de caminos insertados sin revisar
SELECT	COUNT(*) AS Pendientes
FROM	Camino
WHERE	Revisado = 0


--Reiniciar
UPDATE	Camino
SET		Revisado = 0
--DELETE FROM Camino
--DELETE FROM caminoTmp2 WHERE RUTA != 'ND'
SELECT COUNT(*) FROM Camino
SELECT COUNT(*) FROM caminoTmp2
SELECT * FROM Cruza
WHERE RUTA != 'ND'
--66 657
-- 2 547 con nombre

ALTER TABLE	Camino
DROP COLUMN	Revisado

------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Por razones de tiempo se decide nombrar las calles según un enfoque diferente, se dejarán las calles ya nombradas intactas, las restantes se nombrarán según el
--cantón al que pertenece la mayor parte de su geometría, de forma que dentro de cada cantón se enumerarán las calles para nombrarlas.
WHILE ((SELECT COUNT(*) FROM caminoTmp2) > 0)
BEGIN
	DECLARE	@NumeroRutaNuevo		VARCHAR(895),
			@GeomRutaSinNombrar		GEOMETRY,
			@TipoRutaSinNombrar		VARCHAR(32),
			@LongitudRutaSinNombrar	FLOAT,
			@NumeroDentroDeCanton	INT,
			@IDRutaInsertada		INT,
			@Canton					VARCHAR(20),
			@NombreAux				VARCHAR(895)
	DECLARE cursor_calles_sin_nombrar CURSOR FOR
			SELECT	ID, TIPO, LONGITUD, geom
			FROM	caminoTmp2
	--Empezar
	OPEN	cursor_calles_sin_nombrar
	FETCH	cursor_calles_sin_nombrar INTO @IDRutaInsertada, @TipoRutaSinNombrar, @LongitudRutaSinNombrar, @GeomRutaSinNombrar
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		--PRINT	'ID: ' + CONVERT(VARCHAR(256), @IDRutaInsertada)
		SET		@Canton =  (SELECT		TOP 1 Codigo
							FROM		Canton
							GROUP BY	Codigo
							ORDER BY	MAX(Geom.STIntersection(@GeomRutaSinNombrar).STArea()) DESC)
		--PRINT	'Cantón: ' + @Canton
		SET		@NumeroDentroDeCanton =(SELECT	CantidadCalles
										FROM	Tabla_Temporal_Contadores_Calles_Cantones
										WHERE	CodigoCanton = @Canton)
		IF(@NumeroDentroDeCanton > 0)
		BEGIN
			UPDATE	Tabla_Temporal_Contadores_Calles_Cantones
			SET		CantidadCalles = @NumeroDentroDeCanton + 1
			WHERE	CodigoCanton = @Canton
		END
		ELSE
		BEGIN
			INSERT	INTO	Tabla_Temporal_Contadores_Calles_Cantones
			VALUES	(@Canton, 1)
			SET		@NumeroDentroDeCanton = 0
		END
		SET		@NumeroDentroDeCanton = @NumeroDentroDeCanton + 1
		--PRINT	'# dentro de cantón: ' + CONVERT(VARCHAR(256), @NumeroDentroDeCanton)
		SET		@Canton = (SELECT Nombre FROM Canton WHERE Codigo = @Canton)
		--PRINT	'Cantón: ' + @Canton
		SET		@NumeroRutaNuevo = (@Canton + ', calle ' + CONVERT(VARCHAR(32), @NumeroDentroDeCanton))
		--PRINT	'Nombre final: ' + @NumeroRutaNuevo
		INSERT INTO Camino
		VALUES	(@NumeroRutaNuevo, @TipoRutaSinNombrar, @LongitudRutaSinNombrar, @GeomRutaSinNombrar)
		DELETE	FROM caminoTmp2
		WHERE	ID = @IDRutaInsertada
		FETCH NEXT FROM cursor_calles_sin_nombrar INTO @IDRutaInsertada, @TipoRutaSinNombrar, @LongitudRutaSinNombrar, @GeomRutaSinNombrar
	END
	CLOSE		cursor_calles_sin_nombrar
	DEALLOCATE	cursor_calles_sin_nombrar
END

--SELECT * FROM Tabla_Temporal_Contadores_Calles_Cantones

SELECT COUNT(*) FROM Camino		--2910 antes de empezar
SELECT COUNT(*) FROM caminoTmp2 --64111 SIN NOMBRE Y SIN REPETIR GEOMETRÍAS
								--63747 sin nombre, después de borrar las que ya están en Camino (tomar en cuenta las que ya tenían nombre)
								--47193 fallaron

SELECT count(*),  geom.STGeometryType() from caminoTmp2 group by geom.STGeometryType()
SELECT count(*),  geom.STGeometryType() from Camino group by geom.STGeometryType()

select geom from camino where geom.STGeometryType() = 'Polygon'


	CREATE	TABLE Tabla_Temporal_Contadores_Calles_Cantones
	(
		CodigoCanton	INT,
		CantidadCalles	INT
	)


-- Recuperacion del maximo de las calles de la tabla
Declare @Numero		integer,
		@Canton		varchar(20),
		@Codigo		integer
Declare cursor_canton cursor for
	Select nombre, codigo from Canton
OPEN cursor_canton
FETCH FROM cursor_canton INTO @Canton, @Codigo
WHILE( @@FETCH_STATUS = 0 )
BEGIN
	SET @Numero = ( SELECT MAX( dbo.ParseNumber( NumeroRuta ) )
					FROM Camino
					Where NumeroRuta LIKE (@Canton + '%') )
	INSERT INTO Tabla_Temporal_Contadores_Calles_Cantones VALUES( @Codigo, @Numero + 1 )
	FETCH NEXT FROM cursor_canton INTO @Canton, @Codigo
END
CLOSE cursor_canton
DEALLOCATE cursor_canton

