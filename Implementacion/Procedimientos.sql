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