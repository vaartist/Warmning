--Procedimientos almacenados.

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


-- Borrar las rows de 'Costa Rica' y 'Provincias'
DELETE FROM viviendasYpoblacion WHERE Hombres>160000;
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
			UPDATE Distrito SET PoblacionHombres=@Hombres,PoblacionMujeres=@Mujeres,ViviendasOcupadas=@Ocupadas,ViviendasDesocupadas=@Desocupadas,ViviendasColectivas=@Colectivas WHERE Nombre = @Distrito AND CodigoCanton = @FK_Canton;
		END
	END
	FETCH NEXT FROM v_cursor_viviendaTemp INTO @Distrito,@Hombres,@Mujeres,@Ocupadas,@Desocupadas,@Colectivas
END
CLOSE v_cursor_viviendaTemp
DEALLOCATE v_cursor_viviendaTemp


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

