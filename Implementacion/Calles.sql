--Forma alternativa de nombrar caminos

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
			SET		@CantidadCallesHijas = @CantidadCallesHijas + 1
			FETCH NEXT FROM cursor_calles_sin_nombrar INTO @TipoRutaSinNombrar, @LongitudRutaSinNombrar, @GeomRutaSinNombrar
		END
		CLOSE		cursor_calles_sin_nombrar
		DEALLOCATE	cursor_calles_sin_nombrar
		UPDATE	Camino
		SET		Revisado = 1
		WHERE	NumeroRuta = @NumeroRutaNombrada
		DELETE	FROM caminoTmp2
		WHERE	ID = @IDRutaInsertada
		FETCH NEXT FROM cursor_calles_nombradas INTO @IDRutaInsertada, @NumeroRutaNombrada, @GeomRutaNombrada
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
--DELETE FROM caminoTmp2
SELECT * FROM Camino
SELECT * FROM caminoTmp2

SELECT *
FROM Camino c, caminoTmp2 t
WHERE c.NumeroRuta != t.Ruta and c.Geom.STIntersects(t.geom) = 1

DELETE FROM caminoTmp2
WHERE RUTA != 'ND'

DECLARE	@GeomRutaNombrada		GEOMETRY
	--Declararar el cursor para calles nombradas
	DECLARE cursor_calles_nombradas CURSOR FOR
		SELECT	Geom
		FROM	Camino
	--Abrir cursor principal y usar FETCH
	OPEN	cursor_calles_nombradas
	FETCH	cursor_calles_nombradas INTO @GeomRutaNombrada
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		DELETE	FROM caminoTmp2
		WHERE	@GeomRutaNombrada.STEquals(geom) = 1
		FETCH NEXT FROM cursor_calles_nombradas INTO @GeomRutaNombrada
	END
	--Cerrar cursor
	CLOSE		cursor_calles_nombradas
	DEALLOCATE	cursor_calles_nombradas
--11 674 deberían borrarse de las 102760 rutas en total
--deberían quedar 91086
SELECT	COUNT(*)
FROM	caminoTmp2