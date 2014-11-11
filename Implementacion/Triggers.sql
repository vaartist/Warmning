--Triggers.
--USE DW_user4

/* Faltan:
	-Triggers para revisar que las geometrias de las tablas sean del tipo necesario y validas x4
	-Trigger para revisar la relacion topologica de camino con canton, que calcula la longitud
	-Trigger para revisar la relacion topologica de estacion_bomberos con distrito
	-Trigger para revisar la relacion topologica de zonas_riesgo con distrito, que calcula el area
*/

--Trigger para revisar que la geometria de provincia es valida
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
			Print 'ERROR: Geometr�a no v�lida para provincia con nombre ' + @Nombre
		FETCH NEXT FROM cursor_tabla INTO @Codigo, @Nombre, @Geom
	END
	--Cerrar cursor
	CLOSE cursor_tabla
	DEALLOCATE cursor_tabla
--Fin de trigger

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Trigger para revisar que la geometria de bomberos es valida, y su relacion topologica con distrito
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
		--Revisar si la geometria es valida
		IF( @Geom.STIsValid() = 1 AND @Geom.STGeometryType() = 'Point' )
		BEGIN
			--Buscamos al distrito que interseca la estacion
			DECLARE cursor_distrito CURSOR FOR
			Select Codigo, Geom
			From Distrito
			Where Geom.STIntersects(@Geom) = 1
			OPEN cursor_distrito
			FETCH cursor_distrito INTO @CodigoD, @GeomD
			IF(@@FETCH_STATUS = 0)
				Insert into Estacion_Bomberos Values( @Nombre, @Direccion, @CodigoD, @Geom );
			ELSE
				Print 'ERROR: Estaci�n de bomberos con el nombre ' + @Nombre + ' no pertenece a ning�n distrito'
			CLOSE cursor_distrito
		END
		ELSE
			Print 'ERROR: Geometr�a no v�lida para provincia con nombre ' + @Nombre
		FETCH NEXT FROM cursor_tabla INTO @Nombre, @Direccion, @PerteneceA, @Geom
	END
	--Cerrar cursor
	CLOSE cursor_tabla
	DEALLOCATE cursor_tabla
--Fin de trigger

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Trigger para revisar la relacion topol�gica de cant�n con provincia al insertar cantones
DROP TRIGGER cantones_insert;
CREATE TRIGGER cantones_insert
ON Canton
INSTEAD OF INSERT
AS
	--Declarar variables para cursor
	DECLARE @Codigo						INTEGER,
			@Nombre						VARCHAR(20),
			@CodigoProvincia			INTEGER,
			@Geom						GEOMETRY,
			@CodigoProvinciaCorrecta	INTEGER
	--Declararar el cursor principal, hecho para iterar por todas las tuplas que se est�n insertando en la tabla de cantones.
	DECLARE cursor_tabla CURSOR FOR
	SELECT	*
	FROM INSERTED
	--Abrir cursor principal y usar FETCH
	OPEN cursor_tabla
	FETCH cursor_tabla INTO @Codigo, @Nombre, @CodigoProvincia, @Geom
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		--Determinar con cu�l provincia es mayor el �rea de intersecci�n con la geometr�a del nuevo cant�n
		IF( @Geom.STIsValid() = 1 AND (@Geom.STGeometryType() = 'Polygon' OR @Geom.STGeometryType() = 'MultiPolygon') )
		BEGIN
			--Declarar el cursor interno, la consulta obtiene el c�digo y las �reas de intersecci�n entre el cant�n y todas las provincias,
			--luego ordena por �rea y descendentemente para que el cursor obtenga el primer c�digo (correspondiente al �rea de intersecci�n mayor).
			DECLARE cursor_tabla_interna CURSOR FOR
			SELECT	Codigo
			FROM	Provincia
			GROUP BY Codigo
			ORDER BY MAX(Geom.STIntersection(@Geom).STArea()) DESC
			--Se usa el cursor interno para obtener el c�digo de la provincia correspondiente al cant�n
			OPEN cursor_tabla_interna
			FETCH cursor_tabla_interna INTO @CodigoProvinciaCorrecta
			--Se usa ese c�digo para insertar el cant�n de una vez
			INSERT INTO Canton
			VALUES(@Codigo, @Nombre, @CodigoProvinciaCorrecta, @Geom)
			--OPCIONAL, avisarle al usuario la provincia a la que se est� asociando el cant�n, en caso de que especificara una err�nea se dar� cuenta de la correci�n
			--Print 'El cant�n fue asociado a la provincia ' + (SELECT Nombre FROM Provincia WHERE Codigo=@CodigoProvinciaCorrecta)
			CLOSE cursor_tabla_interna
			DEALLOCATE cursor_tabla_interna
		END
		ELSE
			Print 'ERROR: Geometr�a no valida para provincia con nombre ' + @Nombre
		FETCH NEXT FROM cursor_tabla INTO @Codigo, @Nombre, @CodigoProvincia, @Geom
	END
	--Cerrar cursor
	CLOSE cursor_tabla
	DEALLOCATE cursor_tabla
--Fin de trigger

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Trigger para revisar la relacion topologica de distrito con canton

