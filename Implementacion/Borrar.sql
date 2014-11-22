USE DW_user4;

--

SELECT COUNT(*) FROM caminoTmp2
--102 760 tuplas antes de borrar...
-- 66 657 tuplas después de borrar...

--Borrar calles con la misma geometría, dejar sólo una
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

--Borrar de caminoTmp2 las rutas que ya fueron insertadas a Camino por el procedimiento largo, usando geometrías
DECLARE @Geom	GEOMETRY
DECLARE	cursor_tabla CURSOR FOR
	SELECT	geom
	FROM	Camino
OPEN cursor_tabla
FETCH cursor_tabla INTO @Geom
WHILE(@@FETCH_STATUS = 0)
BEGIN
	DELETE	FROM caminoTmp2
	WHERE	geom.STEquals(@Geom) = 1
	FETCH NEXT FROM cursor_tabla INTO @Geom
END
CLOSE cursor_tabla
DEALLOCATE cursor_tabla