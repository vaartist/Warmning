use DW_user4;

-- Insertamos los caminos cuyo nombre es aceptable
Insert into Camino
Select RUTA, TIPO, 0, geom from caminoTmp2 where ruta != 'ND';
Delete from caminoTmp2 where ruta != 'ND';

-- Nivel de llamado
ALTER TABLE Camino ADD Nivel Integer;
Update Camino Set Nivel = 0;
ALTER TABLE Camino DROP COLUMN Nivel

-- Procedimiento para obtener nombres
Declare
	@ID			integer,
	@GEOM		geometry,
	@COUNT		integer,
	@RUTA		varchar(max),
	@TIPO		varchar(25),
	@ADICION	integer,
	@NIVEL		integer
SET @COUNT = 1
While( Exists ( Select ruta from caminoTmp2 ) )
BEGIN
	SET @NIVEL = (SELECT MAX(Nivel) FROM Camino);
	Print '-------- Iteracion numero ' + cast(@NIVEL as varchar(max)) + ' --------'
	Declare sin_nombre cursor for
		Select id, Tipo, geom
		From caminoTmp2
	Open sin_nombre
	Fetch from sin_nombre into @ID, @Tipo, @GEOM
	While( @@FETCH_STATUS = 0 )
	BEGIN
		Declare con_nombre cursor for
			Select TOP(1) NumeroRuta
			from Camino
			Where (Nivel = @NIVEL) AND (Geom.STIntersects( @GEOM ) = 1);
		Open con_nombre
		Fetch from con_nombre into @RUTA
		If( @@FETCH_STATUS = 0 )
		BEGIN
			SET @ADICION = 1
			-- Va a ver que revisar que no haya colisiones de nombre
			While( Exists ( Select numeroRuta From Camino Where NumeroRuta = @RUTA + '-' + cast(@ADICION as varchar(max)) ) )
				SET @ADICION = @ADICION + 1
			-- Agregar a una con nombre modificado y luego borrar de la vieja tabla
			Insert into Camino( NumeroRuta, Tipo, Geom, Nivel ) Values( @RUTA + '-' + cast(@ADICION as varchar(max)), @TIPO, @GEOM, @NIVEL + 1 );
			If( Exists ( Select numeroRuta From Camino Where NumeroRuta = @RUTA + '-' + cast(@ADICION as varchar(max)) ) )
			BEGIN
				Delete from caminoTmp2 where ID = @ID;
				Print 'Total rutas cambiadas: ' + cast(@COUNT as varchar(max)) + ', Nombre nuevo: ' + @RUTA + '-' + cast(@ADICION as varchar(max))
				SET @COUNT = @COUNT + 1
			END
			Else
				Print 'Se trato de insertar la ruta ' + cast(@ID as varchar(max)) + ' con el nombre ' + @RUTA + '-' + cast(@ADICION as varchar(max)) + ', pero no se pudo'
		END
		ELSE
			Print 'No se encontro nombre para ruta con id: ' + cast(@ID as varchar(max))
		Close con_nombre
		Deallocate con_nombre
		Fetch next from sin_nombre into @ID, @TIPO, @GEOM
	END
	Close sin_nombre
	Deallocate sin_nombre
END


Select * from camino

-- Trigger temporal
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
			@GeomCanton		geometry,
			@Nivel			int
	--Declararar el cursor
	DECLARE cursor_tabla CURSOR FOR
		SELECT	NumeroRuta, Tipo, Geom, Nivel
		FROM INSERTED
	--Abrir cursor y usar FETCH
	OPEN cursor_tabla
	FETCH cursor_tabla INTO @NumeroRuta, @Tipo, @Geom, @Nivel
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF( @Geom.STIsValid() = 1 AND (@Geom.STGeometryType() = 'LineString' OR @Geom.STGeometryType() = 'MultiLineString') )
		BEGIN
			Insert into Camino Values( @NumeroRuta, @Tipo, @Geom.STLength(), @Geom, @Nivel );
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
		FETCH NEXT FROM cursor_tabla INTO @NumeroRuta, @Tipo, @Geom, @Nivel
	END
	--Cerrar cursor
	CLOSE cursor_tabla
	DEALLOCATE cursor_tabla
--Fin de trigger

delete from cruza

-- Procedimiento que calcula las intersecciones de los caminos ya insertados en canton
DECLARE @NumeroRuta		varchar(255),
		@Tipo			varchar(25),
		@Geom			geometry,
		@CodCanton		int,
		@GeomCanton		geometry
--Declararar el cursor
DECLARE cursor_tabla CURSOR FOR
	SELECT	NumeroRuta, Tipo, Geom
	FROM Camino
--Abrir cursor y usar FETCH
OPEN cursor_tabla
FETCH FROM cursor_tabla INTO @NumeroRuta, @Tipo, @Geom
WHILE(@@FETCH_STATUS = 0)
BEGIN
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
	FETCH NEXT FROM cursor_tabla INTO @NumeroRuta, @Tipo, @Geom
END
--Cerrar cursor
CLOSE cursor_tabla
DEALLOCATE cursor_tabla