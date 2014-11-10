-- Triggers para revisar que las geometrias de las tablas sean del tipo necesario y validas x6

-- Trigger para revisar la relacion topologica de canton con provincia

-- Trigger para revisar la relacion topologica de distrito con canton

-- Trigger para revisar la relacion topologica de camino con canton, que calcula la longitud

-- Trigger para revisar la relacion topologica de estacion_bomberos con distrito

-- Trigger para revisar la relacion topologica de zonas_riesgo con distrito, que calcula el area

-- Procedimiento para insertar los datos de informacion de carreteras a canton x3

-- Procedimiento para insertar los datos de viviendas y poblacion a distrito

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