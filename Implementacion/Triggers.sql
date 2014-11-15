--Triggers.
--USE DW_user4

/* Faltan:
	-Triggers para revisar que las geometrías de las tablas sean del tipo necesario y válidas x2
	-Trigger para revisar la relacion topológica de camino con canton, que calcula la longitud
	-Trigger para revisar la relacion topológica de estacion_bomberos con distrito
	-Trigger para revisar la relacion topológica de zonas_riesgo con distrito, que calcula el area
*/

--Trigger para revisar que la geometría de provincia es válida
DROP TRIGGER provincia_INSERT;
CREATE TRIGGER provincia_INSERT
ON provincia
INSTEAD OF INSERT
AS
	--Declarar variables para cursor
	DECLARE @Codigo INTEGER,
			@Nombre VARCHAR(10),
			@Geom GEOMETRY
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
			INSERT INTO Provincia VALUES( @Codigo, @Nombre, @Geom );
		ELSE
			PRINT 'ERROR: Geometría no válida para provincia con nombre ' + @Nombre
		FETCH NEXT FROM cursor_tabla INTO @Codigo, @Nombre, @Geom
	END
	--Cerrar cursor
	CLOSE cursor_tabla
	DEALLOCATE cursor_tabla
--Fin de trigger

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Trigger para revisar que la geometría de bomberos es válida, y su relacion topológica con distrito
DROP TRIGGER bomberos_INSERT;
CREATE TRIGGER bomberos_INSERT
ON estacion_bomberos
INSTEAD OF INSERT
AS
	--Declarar variables para cursor
	DECLARE @Nombre VARCHAR(55),
			@Direccion VARCHAR(120),
			@Geom geometry,
			@CodigoD INTEGER
	--Declararar el cursor
	DECLARE cursor_tabla CURSOR FOR
	SELECT Nombre, Direccion, Geom
	FROM INSERTed
	--Abrir cursor y usar FETCH
	OPEN cursor_tabla
	FETCH cursor_tabla INTO @Nombre, @Direccion, @Geom
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		--Revisar si la geometría es válida
		IF( @Geom.STIsValid() = 1 AND @Geom.STGeometryType() = 'Point' )
		BEGIN
			--Buscamos al distrito que interseca la estacion
			SET @CodigoD = ( SELECT Codigo FROM Distrito Where Geom.STIntersects(@Geom) = 1 )
			IF( @CodigoD is not null )
			BEGIN
				INSERT INTO Estacion_Bomberos VALUES( @Nombre, @Direccion, @CodigoD, @Geom );
			END
			ELSE
				PRINT 'ERROR: Estación de bomberos con el nombre ' + @Nombre + ' no pertenece a ningún distrito'
		END
		ELSE
			PRINT 'ERROR: Geometría no válida para provincia con nombre ' + @Nombre
		FETCH NEXT FROM cursor_tabla INTO @Nombre, @Direccion, @Geom
	END
	--Cerrar cursor
	CLOSE cursor_tabla
	DEALLOCATE cursor_tabla
--Fin de trigger
SELECT * FROM Estacion_Bomberos;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Trigger para revisar la relacion topológica de cantón con provincia al INSERTar cantones
DROP TRIGGER cantones_INSERT;
CREATE TRIGGER cantones_INSERT
ON Canton
INSTEAD OF INSERT
AS
	--Declarar variables para cursor
	DECLARE @Codigo						INTEGER,
			@Nombre						VARCHAR(20),
			@CodigoProvincia			INTEGER,
			@Geom						GEOMETRY,
			@CodigoProvinciaCorrecta	INTEGER
	--Declararar el cursor principal, hecho para iterar por todas las tuplas que se están INSERTando en la tabla de cantones.
	DECLARE cursor_tabla CURSOR FOR
	SELECT	*
	FROM INSERTED
	--Abrir cursor principal y usar FETCH
	OPEN cursor_tabla
	FETCH cursor_tabla INTO @Codigo, @Nombre, @CodigoProvincia, @Geom
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		--Determinar con cuál provincia es mayor el área de intersección con la geometría del nuevo cantón
		IF( @Geom.STIsValid() = 1 AND (@Geom.STGeometryType() = 'Polygon' OR @Geom.STGeometryType() = 'MultiPolygon') )
		BEGIN
			--Declarar el cursor interno, la consulta obtiene el código y las áreas de intersección entre el cantón y todas las provincias,
			--luego ordena por área y descendentemente para que el cursor obtenga el primer código (correspondiente al área de intersección mayor).
			DECLARE cursor_tabla_interna CURSOR FOR
			SELECT	Codigo
			FROM	Provincia
			GROUP BY Codigo
			ORDER BY MAX(Geom.STIntersection(@Geom).STArea()) DESC
			--Se usa el cursor interno para obtener el código de la provincia correspondiente al cantón
			OPEN cursor_tabla_interna
			FETCH cursor_tabla_interna INTO @CodigoProvinciaCorrecta
			--Se usa ese código para INSERTar el cantón de una vez
			INSERT INTO Canton
			VALUES(@Codigo, @Nombre, @CodigoProvinciaCorrecta, @Geom)
			--OPCIONAL, avisarle al usuario la provincia a la que se está asociando el cantón, en caso de que especIFicara una errónea se dará cuenta de la correción
			--PRINT 'El cantón fue asociado a la provincia ' + (SELECT Nombre FROM Provincia WHERE Codigo=@CodigoProvinciaCorrecta)
			CLOSE cursor_tabla_interna
			DEALLOCATE cursor_tabla_interna
		END
		ELSE
			PRINT 'ERROR: Geometría no válida para provincia con nombre ' + @Nombre
		FETCH NEXT FROM cursor_tabla INTO @Codigo, @Nombre, @CodigoProvincia, @Geom
	END
	--Cerrar cursor
	CLOSE cursor_tabla
	DEALLOCATE cursor_tabla
--Fin de trigger
--DELETE FROM Canton
--SELECT * FROM Canton

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Trigger para revisar la relacion topológica de distrito con canton
DROP TRIGGER distritos_INSERT;
CREATE TRIGGER distritos_INSERT
ON Distrito
INSTEAD OF INSERT
AS
	--Declarar variables para cursor
	DECLARE @Codigo						INTEGER,
			@Nombre						VARCHAR(25),
			@CodigoCanton				INTEGER,
			@PoblacionHombres			INTEGER,
			@PoblacionMujeres			INTEGER,
			@ViviendasOcupadas			INTEGER,
			@ViviendasDesocupadas		INTEGER,
			@ViviendasColectivas		INTEGER,
			@Geom						GEOMETRY,
			@CodigoDistritoCorrecto		INTEGER
	--Declararar el cursor principal, hecho para iterar por todas las tuplas que se están INSERTando en la tabla de cantones.
	DECLARE cursor_tabla CURSOR FOR
	SELECT	*
	FROM INSERTED
	--Abrir cursor principal y usar FETCH
	OPEN cursor_tabla
	FETCH cursor_tabla INTO @Codigo, @Nombre, @CodigoCanton, @PoblacionHombres, @PoblacionMujeres, @ViviendasOcupadas, @ViviendasDesocupadas, @ViviendasColectivas, @Geom
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		--Determinar con cuál provincia es mayor el área de intersección con la geometría del nuevo cantón
		IF( @Geom.STIsValid() = 1 AND (@Geom.STGeometryType() = 'Polygon' OR @Geom.STGeometryType() = 'MultiPolygon') )
		BEGIN
			--Declarar el cursor interno, la consulta obtiene el código y las áreas de intersección entre el cantón y todas las provincias,
			--luego ordena por área y descendentemente para que el cursor obtenga el primer código (correspondiente al área de intersección mayor).
			DECLARE cursor_tabla_interna CURSOR FOR
			SELECT	Codigo
			FROM	Canton
			GROUP BY Codigo
			ORDER BY MAX(Geom.STIntersection(@Geom).STArea()) DESC
			--Se usa el cursor interno para obtener el código de la provincia correspondiente al cantón
			OPEN cursor_tabla_interna
			FETCH cursor_tabla_interna INTO @CodigoDistritoCorrecto
			--Se usa ese código para INSERTar el cantón de una vez
			INSERT INTO Distrito
			VALUES(@Codigo, @Nombre, @CodigoDistritoCorrecto, @PoblacionHombres, @PoblacionMujeres, @ViviendasOcupadas, @ViviendasDesocupadas, @ViviendasColectivas, @Geom)
			--OPCIONAL, avisarle al usuario la provincia a la que se está asociando el cantón, en caso de que especIFicara una errónea se dará cuenta de la correción
			--PRINT 'El cantón fue asociado a la provincia ' + (SELECT Nombre FROM Provincia WHERE Codigo=@CodigoDistritoCorrecto)
			CLOSE cursor_tabla_interna
			DEALLOCATE cursor_tabla_interna
		END
		ELSE
			PRINT 'ERROR: Geometría no válida para provincia con nombre ' + @Nombre
		FETCH NEXT FROM cursor_tabla INTO @Codigo, @Nombre, @CodigoCanton, @PoblacionHombres, @PoblacionMujeres, @ViviendasOcupadas, @ViviendasDesocupadas, @ViviendasColectivas, @Geom
	END
	--Cerrar cursor
	CLOSE cursor_tabla
	DEALLOCATE cursor_tabla
--Fin de trigger
--DELETE FROM Distrito
--SELECT * FROM Distrito

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Trigger que al INSERTar zonas de riesgo calcula la interseccion
DROP TRIGGER zonas_riesgo_INSERT;
CREATE TRIGGER zonas_riesgo_INSERT
ON Zonas_Riesgo
AFTER INSERT
AS
	--Declarar variables para cursor
DECLARE @CodDistrito	INTEGER,
	@GeomDistrito		geometry,
	@MesesSecos			INTEGER,
	@VelocidadViento	VARCHAR(10),
	@GeomZR				geometry,
	@Cobertura			FLOAT
DECLARE v_cursor_interDistrit CURSOR FOR
	SELECT Codigo,Geom FROM Distrito;
DECLARE v_cursor_interZR CURSOR FOR
	SELECT MesesSecos,VelocidadViento,Geom FROM INSERTed;
OPEN v_cursor_interDistrit
FETCH NEXT FROM v_cursor_interDistrit INTO @CodDistrito,@GeomDistrito
WHILE (@@FETCH_STATUS = 0)
BEGIN
	OPEN v_cursor_interZR
	FETCH NEXT FROM v_cursor_interZR INTO @MesesSecos,@VelocidadViento,@GeomZR
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF (@GeomDistrito.STIntersects(@GeomZR) = 1)
		BEGIN
			SET @Cobertura = (@GeomDistrito.STIntersection(@GeomZR).STArea() / @GeomDistrito.STArea())*100;
			IF( @Cobertura > 0)
			BEGIN
				IF( @Cobertura > 100 )
				BEGIN
					SET @Cobertura = 100;
				END
				IF( @Cobertura > 0.0001 )
				BEGIN
					INSERT INTO Interseca VALUES (@CodDistrito,@MesesSecos,@VelocidadViento,@Cobertura);
				END
			END
		END
		FETCH NEXT FROM v_cursor_interZR INTO @MesesSecos,@VelocidadViento,@GeomZR
	END
	CLOSE v_cursor_interZR
	FETCH NEXT FROM v_cursor_interDistrit INTO @CodDistrito,@GeomDistrito
END
CLOSE v_cursor_interDistrit
DEALLOCATE v_cursor_interDistrit
DEALLOCATE v_cursor_interZR


--Trigger para revisar que la geometria de camino es valida y buscar relaciones topologicas
DROP TRIGGER camino_insert;
CREATE TRIGGER camino_insert
ON camino
INSTEAD OF INSERT
AS
	--Declarar variables para cursor
	DECLARE @NumeroRuta		varchar(255),
			@Tipo			varchar(25),
			@Geom			geometry,
			@CodCanton		int,
			@GeomCanton		geometry
	--Declararar el cursor
	DECLARE cursor_tabla CURSOR FOR
		SELECT	NumeroRuta, Tipo, Geom
		FROM INSERTED
	--Abrir cursor y usar FETCH
	OPEN cursor_tabla
	FETCH cursor_tabla INTO @NumeroRuta, @Tipo, @Geom
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF( @Geom.STIsValid() = 1 AND (@Geom.STGeometryType() = 'LineString' OR @Geom.STGeometryType() = 'MultiLineString') )
		BEGIN
			Insert into Camino Values( @NumeroRuta, @Tipo, @Geom.STLength(), @Geom );
			Declare cursor_canton cursor for
				Select Codigo, Geom
				From Canton
				Where Geom.STIntersects( @Geom ) = 1
			Open cursor_canton
			Fetch from cursor_canton into @CodCanton, @GeomCanton
			While( @@FETCH_STATUS = 0 )
			BEGIN
				Insert into Cruza Values( @CodCanton, @NumeroRuta, @GeomCanton.STIntersection( @Geom ).STLength() )
				Fetch next from cursor_canton into @CodCanton, @GeomCanton
			END
			Close cursor_canton
			Deallocate cursor_canton
		END
		Else
			Print 'ERROR: Geometría no válida para camino con nombre ' + @NumeroRuta
		FETCH NEXT FROM cursor_tabla INTO @NumeroRuta, @Tipo, @Geom
	END
	--Cerrar cursor
	CLOSE cursor_tabla
	DEALLOCATE cursor_tabla
--Fin de trigger
