--Procedimientos almacenados.
USE DW_user4;

--Procedimiento almacenado para obtener numeros de un string
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
DECLARE
	@Canton VARCHAR(20),
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

SELECT * from viviendasYpoblacion
SELECT * FROM DISTRITO;


-- Procedimiento que (una vez establecidos los distritos y zonas de riesgo) calcula la interseccion de ambas tablas
DECLARE @CodDistrito	INTEGER,
	@GeomDistrito		geometry,
	@MesesSecos			INTEGER,
	@VelocidadViento	VARCHAR(10),
	@GeomZR				geometry,
	@Cobertura			FLOAT
DECLARE v_cursor_interDistrit CURSOR FOR
	SELECT Codigo,Geom FROM Distrito;
DECLARE v_cursor_interZR CURSOR FOR
	SELECT MesesSecos,VelocidadViento,Geom FROM Zonas_Riesgo;
OPEN v_cursor_interDistrit
FETCH NEXT FROM v_cursor_interDistrit INTO @CodDistrito,@GeomDistrito
WHILE @@FETCH_STATUS = 0
BEGIN
	OPEN v_cursor_interZR
	FETCH NEXT FROM v_cursor_interZR INTO @MesesSecos,@VelocidadViento,@GeomZR
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @GeomDistrito.STIntersects(@GeomZR) != null
		BEGIN
			SET @Cobertura = @GeomDistrito.STIntersection(@GeomZR).STArea() / @GeomDistrito.STArea();
			INSERT INTO Interseca VALUES (@CodDistrito,@MesesSecos,@VelocidadViento,@Cobertura);
		END
		FETCH NEXT FROM v_cursor_interZR INTO @MesesSecos,@VelocidadViento,@GeomZR
	END
	CLOSE v_cursor_interZR
	FETCH NEXT FROM v_cursor_interDistrit INTO @CodDistrito,@GeomDistrito
END
CLOSE v_cursor_interDistrit
DEALLOCATE v_cursor_interDistrit
DEALLOCATE v_cursor_interZR



-- Procedimiento para importar datos de carreteras asfaltadas a Cantones
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

-- Procedimiento para importar datos de carreteras de concreto a Cantones
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

-- Procedimiento para importar datos de carreteras de lastre a Cantones
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
--Procedimiento almacenado para pasar a mayúsculas y eliminar tildes
CREATE FUNCTION Normalizar_Nombre
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
