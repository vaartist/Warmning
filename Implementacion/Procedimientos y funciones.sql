--Procedimientos almacenados.
USE DW_user4;

--Función para obtener numeros de un string
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
--

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
--

--Procedimiento para insertar los datos de viviendas y poblacion a distrito
DECLARE
	@Canton VARCHAR(20),
	@FK_Canton INTEGER,
	@Distrito VARCHAR(25),
	@Hombres INTEGER,
	@Mujeres INTEGER,
	@Ocupadas INTEGER,
	@Desocupadas INTEGER,
	@Colectivas INTEGER
DECLARE v_cursor_viviendaTemp CURSOR FOR
	SELECT * FROM viviendasYpoblacion;
OPEN v_cursor_viviendaTemp
FETCH NEXT FROM v_cursor_viviendaTemp INTO @Distrito,@Hombres,@Mujeres,@Ocupadas,@Desocupadas,@Colectivas
WHILE (@@FETCH_STATUS = 0)
BEGIN
	IF (LEN(@Distrito)>0)
	BEGIN
		SET @Distrito = dbo.Normalizar_Nombre(@Distrito);
		IF (LEN(@Canton)>0)
		BEGIN
			UPDATE Distrito SET PoblacionHombres=@Hombres,PoblacionMujeres=@Mujeres,ViviendasOcupadas=@Ocupadas,ViviendasDesocupadas=@Desocupadas,ViviendasColectivas=@Colectivas WHERE Nombre=@Distrito AND CodigoCanton = @FK_Canton;
		END
		ELSE
		BEGIN
			SET @Canton = @Distrito;
			SET @FK_Canton = (SELECT c.Codigo FROM Canton c WHERE c.Nombre=@Canton);
		END
	END
	ELSE
	BEGIN
		SET @Canton = @Distrito;
	END
	FETCH NEXT FROM v_cursor_viviendaTemp INTO @Distrito,@Hombres,@Mujeres,@Ocupadas,@Desocupadas,@Colectivas
END
CLOSE v_cursor_viviendaTemp
DEALLOCATE v_cursor_viviendaTemp
UPDATE Distrito SET PoblacionHombres=0,PoblacionMujeres=0,ViviendasOcupadas=0,ViviendasDesocupadas=0,ViviendasColectivas=0 WHERE Nombre='ISLA DEL COCO';
--
SELECT * from viviendasYpoblacion
SELECT * FROM DISTRITO;
--

--Procedimiento para importar datos de carreteras asfaltadas a Cantones
DECLARE @CodCanton INTEGER,
	@NombreCanton varchar(25),
	@Kilometros FLOAT
DECLARE cursor_tabla CURSOR FOR
	SELECT *	FROM carreteras_asfalto
OPEN cursor_tabla
FETCH NEXT FROM cursor_tabla INTO @NombreCanton, @Kilometros
WHILE( @@FETCH_STATUS = 0 )
BEGIN
	SET @CodCanton = ( SELECT Codigo FROM Canton Where Nombre = UPPER(@NombreCanton) )
	INSERT INTO Informacion_Carreteras_Canton VALUES( @CodCanton, 'Asfalto', @Kilometros )
	FETCH NEXT FROM cursor_tabla INTO @NombreCanton, @Kilometros
END
CLOSE cursor_tabla
DEALLOCATE cursor_tabla
--

--Procedimiento para importar datos de carreteras de concreto a Cantones
DECLARE @CodCanton INTEGER,
	@NombreCanton varchar(25),
	@Kilometros FLOAT
DECLARE cursor_tabla CURSOR FOR
	SELECT *	FROM carreteras_concreto
OPEN cursor_tabla
FETCH NEXT FROM cursor_tabla INTO @NombreCanton, @Kilometros
WHILE( @@FETCH_STATUS = 0 )
BEGIN
	SET @CodCanton = ( SELECT Codigo FROM Canton Where Nombre = UPPER(@NombreCanton) )
	INSERT INTO Informacion_Carreteras_Canton VALUES( @CodCanton, 'Concreto', @Kilometros )
	FETCH NEXT FROM cursor_tabla INTO @NombreCanton, @Kilometros
END
CLOSE cursor_tabla
DEALLOCATE cursor_tabla
--

--Procedimiento para importar datos de carreteras de lastre a Cantones
DECLARE @CodCanton INTEGER,
	@NombreCanton varchar(25),
	@Kilometros FLOAT
DECLARE cursor_tabla CURSOR FOR
	SELECT *	FROM carreteras_lastre
OPEN cursor_tabla
FETCH NEXT FROM cursor_tabla INTO @NombreCanton, @Kilometros
WHILE( @@FETCH_STATUS = 0 )
BEGIN
	SET @CodCanton = ( SELECT Codigo FROM Canton Where Nombre = UPPER(@NombreCanton) )
	INSERT INTO Informacion_Carreteras_Canton VALUES( @CodCanton, 'Lastre', @Kilometros )
	FETCH NEXT FROM cursor_tabla INTO @NombreCanton, @Kilometros
END
CLOSE cursor_tabla
DEALLOCATE cursor_tabla
--

--Función para pasar a mayúsculas y eliminar tildes
CREATE FUNCTION dbo.Normalizar_Nombre
(
	@STRING		VARCHAR(MAX)
)
RETURNS	VARCHAR(MAX)
AS
BEGIN
	--Primero pasar a mayúsculas, puede haber mayúsculas tildadas
	SET @STRING = UPPER(@STRING);
	--Reemplazar todos los caracteres raros (agregar más de ser necesario)
	SET @STRING = REPLACE(@STRING, 'Á', 'A');
	SET @STRING = REPLACE(@STRING, 'É', 'E');
	SET @STRING = REPLACE(@STRING, 'Í', 'I');
	SET @STRING = REPLACE(@STRING, 'Ó', 'O');
	SET @STRING = REPLACE(@STRING, 'Ú', 'U');
	SET @STRING = REPLACE(@STRING, 'Ñ', 'N');
	RETURN @STRING
END
GO
--DROP FUNCTION Normalizar_Nombre
--Probarlo
DECLARE @result VARCHAR(MAX)
SET		@result = 'San José Éstípulas';
SET		@result = dbo.Normalizar_Nombre(@result);
PRINT	@result;
--

--Eliminar caracteres alfabeticos del String
CREATE FUNCTION dbo.Eliminar_Alfabeticos
(
	@string VARCHAR(8000)
)
RETURNS VARCHAR(8000)
AS
BEGIN
	SET @string = SUBSTRING(@string,18,8000);
	SET @string = SUBSTRING(@string,1,CHARINDEX(' M/SEC',@string)-1);
	RETURN @string
END
GO
--DROP FUNCTION dbo.Eliminar_Alfabeticos
--Probarlo
DECLARE @result VARCHAR(MAX)
SET		@result = 'VELOCIDAD VIENTO 5-7 M/SEC';
SET		@result = dbo.Eliminar_Alfabeticos(@result);
PRINT	@result
--

--Unir rutas por su nombre de ruta
Create Table caminoTmp2
(
	ID		integer primary key,
	RUTA	nvarchar(255),
	Tipo	nvarchar(255),
	geom	geometry
);
--

--Al unir los caminos con nombre quedan 2657 caminos con nombres distintos
Declare @ID integer,
		@RUTA nvarchar(255),
		@TIPO nvarchar(255),
		@Geom geometry,
		@UnionGeo geometry
SET @ID = 1
Declare rutas_repetidas cursor for
	Select distinct RUTA
	From caminoTmp
	WHERE RUTA != '' AND RUTA != 'ND' ORDER BY RUTA
OPEN rutas_repetidas
FETCH NEXT FROM rutas_repetidas INTO @RUTA
WHILE( @@FETCH_STATUS = 0 )
BEGIN
	--Ciclo anidado
	SET @UnionGeo = null
	Declare camino_nombre cursor for
		Select TIPO, geom
		From caminoTmp
		Where RUTA = @RUTA
	OPEN camino_nombre
	FETCH NEXT FROM camino_nombre INTO @Tipo, @Geom
	WHILE( @@FETCH_STATUS = 0 )
	BEGIN
		SET @UnionGeo = @Geom.STUnion( @UnionGeo ) 
		FETCH NEXT FROM camino_nombre INTO @Tipo, @Geom
	END
	INSERT INTO caminoTmp2 VALUES( @ID, @RUTA, @Tipo, @Geom )
	CLOSE camino_nombre
	DEALLOCATE camino_nombre
	--Fin ciclo anidado

	SET @ID = @ID + 1
	FETCH NEXT FROM rutas_repetidas INTO @Ruta
END
CLOSE rutas_repetidas
DEALLOCATE rutas_repetidas
--

--En total 100110 rutas sin nombre, las insertamos
Declare @ID integer,
		@TIPO nvarchar(255),
		@Geom geometry,
		@UnionGeo geometry
SET @ID = (SELECT MAX(ID) + 1 FROM caminoTmp2)
Declare rutas_ND cursor for
	Select Tipo, Geom
	From caminoTmp
	Where RUTA = '' OR RUTA = 'ND'
OPEN rutas_ND
FETCH NEXT FROM rutas_ND INTO @TIPO, @GEOM
WHILE( @@FETCH_STATUS = 0 )
BEGIN
	INSERT INTO caminoTmp2 Values( @ID, 'ND', @TIPO, @GEOM )
	SET @ID = @ID + 1
	FETCH NEXT FROM rutas_ND INTO @TIPO, @GEOM
END
CLOSE rutas_ND
DEALLOCATE rutas_ND
--


--En total deberia ser 2657 + 100110 = 102767 caminos distintos
Select * from caminoTmp2;

--Procedimiento para dar a los caminos sin nombre un nuevo nombre
Declare @IDND			integer,
		@TIPOND			nvarchar(MAX),
		@RUTA			nvarchar(MAX),
		@TIPO			nvarchar(MAX),
		@Geom			geometry,
		@Cont			int
WHILE( Exists (Select Ruta From caminoTmp2 Where RUTA = 'ND') )
BEGIN
	Declare camino_nombrado cursor for
		Select RUTA, Tipo, geom
		FROM caminoTmp2
		WHERE RUTA != 'ND' ORDER BY RUTA
	OPEN camino_nombrado
	FETCH FROM camino_nombrado INTO @RUTA, @Tipo, @Geom
	WHILE( @@FETCH_STATUS = 0 )
	BEGIN
		SET @Cont = 1
		--Ciclo interno
		Declare camino_nd cursor for
			Select ID, TIPO
			FROM caminoTmp2
			WHERE RUTA = 'ND' AND geom.STIntersects(@Geom) = 1
		OPEN camino_nd
		FETCH FROM camino_nd INTO @IDND, @TIPOND
		WHILE( @@FETCH_STATUS = 0 )
		BEGIN
			IF( @TIPOND is null )
				SET @TIPOND = @TIPO
			UPDATE caminoTmp2 SET RUTA = ( @RUTA + '-' + CAST(@Cont AS varchar(10)) ), Tipo = @TIPOND WHERE ID = @IDND
			PRINT 'Cambiado nombre de ruta ND a ' + @RUTA + '-' + CAST(@Cont AS varchar(10))
			SET @Cont = @Cont + 1
			FETCH NEXT FROM camino_nd INTO @IDND, @TIPOND
		END
		CLOSE camino_nd
		DEALLOCATE camino_nd
		--Fin ciclo interno
		FETCH NEXT FROM camino_nombrado INTO @RUTA, @Tipo, @Geom
	END
	CLOSE camino_nombrado
	DEALLOCATE camino_nombrado
END
--

