--Triggers


--Trigger para revisar que la geometría de provincia es válida
DROP TRIGGER provincia_insert;
CREATE TRIGGER provincia_insert
ON provincia
INSTEAD OF INSERT
AS
	--Declarar variables para cursor
	DECLARE @Codigo INTEGER,
			@Nombre VARCHAR(10),
			@Geom geometry
	--Declararar el cursor
	DECLARE cursor_tabla CURSOR FOR
	SELECT	*
	FROM INSERTED
	--Abrir cursor y usar FETCH
	OPEN cursor_tabla
	FETCH cursor_tabla INTO @Codigo, @Nombre, @Geom
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF( @Geom.STIsValid() = 1 AND (@Geom.STGeometryType() = 'Polygon' OR @Geom.STGeometryType() = 'MultiPolygon') )
			Insert into Provincia Values( @Codigo, @Nombre, @Geom );
		Else
			Print 'ERROR: Geometria no valida para provincia con nombre ' + @Nombre
		FETCH NEXT FROM cursor_tabla INTO @Codigo, @Nombre, @Geom
	END
	--Cerrar cursor
	CLOSE cursor_tabla
	DEALLOCATE cursor_tabla
--Fin de trigger
--

-- Trigger para revisar que la geometría de bomberos es válida, y su relacion topológica con distrito
DROP TRIGGER bomberos_insert;
CREATE TRIGGER bomberos_insert
ON estacion_bomberos
INSTEAD OF INSERT
AS
	--Declarar variables para cursor
	DECLARE @Nombre VARCHAR(25),
			@Direccion VARCHAR(100),
			@PerteneceA INTEGER,
			@Geom geometry,
			@CodigoD INTEGER,
			@GeomD geometry
	--Declararar el cursor
	DECLARE cursor_tabla CURSOR FOR
	SELECT	*
	FROM INSERTED
	--Abrir cursor y usar FETCH
	OPEN cursor_tabla
	FETCH cursor_tabla INTO @Nombre, @Direccion, @PerteneceA, @Geom
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		-- Revisar si la geometria es valida
		IF( @Geom.STIsValid() = 1 AND @Geom.STGeometryType() = 'Point' )
		BEGIN
			-- Buscamos al distrito que interseca la estacion
			DECLARE cursor_distrito CURSOR FOR
			Select Codigo, Geom
			From Distrito
			Where Geom.STIntersects(@Geom) = 1
			OPEN cursor_distrito
			FETCH cursor_distrito INTO @CodigoD, @GeomD
			IF(@@FETCH_STATUS = 0)
				Insert into Estacion_Bomberos Values( @Nombre, @Direccion, @CodigoD, @Geom );
			ELSE
				Print 'ERROR: Estacion de bomberos con el nombre ' + @Nombre + ' no pertenece a ningun distrito'
			CLOSE cursor_distrito
		END
		ELSE
			Print 'ERROR: Geometria no valida para provincia con nombre ' + @Nombre
		FETCH NEXT FROM cursor_tabla INTO @Nombre, @Direccion, @PerteneceA, @Geom
	END
	--Cerrar cursor
	CLOSE cursor_tabla
	DEALLOCATE cursor_tabla
--Fin de trigger
--


/* Faltan:
	-Triggers para revisar que las geometrias de las tablas sean del tipo necesario y validas x4
	-Trigger para revisar la relacion topologica de canton con provincia
	-Trigger para revisar la relacion topologica de distrito con canton
	-Trigger para revisar la relacion topologica de camino con canton, que calcula la longitud
	-Trigger para revisar la relacion topologica de estacion_bomberos con distrito
	-Trigger para revisar la relacion topologica de zonas_riesgo con distrito, que calcula el area
	-Procedimiento para insertar los datos de informacion de carreteras a canton x3
*/