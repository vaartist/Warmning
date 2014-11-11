-- Trigger para revisar que la geometria de provincia es valida
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

-- Trigger para revisar que la geometria de bomberos es valida, y su relacion topologica con distrito
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



/* Faltan:
	-Triggers para revisar que las geometrias de las tablas sean del tipo necesario y validas x4
	-Trigger para revisar la relacion topologica de canton con provincia
	-Trigger para revisar la relacion topologica de distrito con canton
	-Trigger para revisar la relacion topologica de camino con canton, que calcula la longitud
	-Trigger para revisar la relacion topologica de estacion_bomberos con distrito
	-Trigger para revisar la relacion topologica de zonas_riesgo con distrito, que calcula el area
	-Procedimiento para insertar los datos de informacion de carreteras a canton x3
*/

-- Procedimiento almacenado para obtener numeros de un string
CREATE FUNCTION dbo.ParseNumericChars
(
	@string VARCHAR(8000)
)
RETURNS VARCHAR(8000)
AS
BEGIN
	DECLARE @IncorrectCharLoc SMALLINT
	SET @IncorrectCharLoc = PATINDEX('%[^0-9]%', @string)
	WHILE @IncorrectCharLoc > 0
	BEGIN
		SET @string = STUFF(@string, @IncorrectCharLoc, 1, '')
		SET @IncorrectCharLoc = PATINDEX('%[^0-9]%', @string)
	END
	SET @string = @string
	RETURN @string
END
GO

CREATE FUNCTION dbo.ParseNumber
(
	@string VARCHAR(8000)
)
RETURNS INTEGER
AS
BEGIN
	SET @string  = dbo.ParseNumericChars(@string)
	RETURN ISNULL(Cast(@string as int),0)
END
GO


-- Procedimiento para insertar los datos de viviendas y poblacion a distrito
DECLARE @Canton VARCHAR(20),
	@FK_Canton INTEGER,
	@Distrito VARCHAR(20),
	@Hombres INTEGER,
	@Mujeres INTEGER,
	@Ocupadas INTEGER,
	@Desocupadas INTEGER,
	@Colectivas INTEGER
DECLARE v_cursor_viviendaTemp CURSOR FOR
	SELECT * FROM viviendasYpoblacion;
OPEN v_cursor_viviendaTemp
FETCH NEXT FROM v_cursor_viviendaTemp INTO @Distrito,@Hombres,@Mujeres,@Ocupadas,@Desocupadas,@Colectivas
WHILE @@FETCH_STATUS = 0
BEGIN
	IF @Distrito=NULL
	BEGIN
		SET @Canton = @Distrito;
	END
	ELSE
	BEGIN
		IF @Canton=NULL
		BEGIN
			SET @Canton = @Distrito;
			SET @FK_Canton = (SELECT c.Codigo FROM Canton c WHERE c.Nombre=@Canton);
		END
		ELSE
		BEGIN
			UPDATE Distrito SET Poblacion_H=@Hombres,Poblacion_M=@Mujeres,ViviendasO=@Ocupadas,ViviendasD=@Desocupadas,ViviendasC=@Colectivas WHERE Nombre = @Distrito AND PerteneceA = @FK_Canton;
		END
	END
	FETCH NEXT FROM v_cursor_viviendaTemp INTO @Distrito,@Hombres,@Mujeres,@Ocupadas,@Desocupadas,@Colectivas
END
CLOSE v_cursor_viviendaTemp
DEALLOCATE v_cursor_viviendaTemp