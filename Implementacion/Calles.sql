--Forma alternativa de nombrar caminos
CREATE TABLE Calle
(
	NumeroRuta				VARCHAR(1024),
	Tipo					VARCHAR(32),
	Longitud				FLOAT,			--Kilometros
	Geom					GEOMETRY,
	Revisada				BIT				--Usado para nombramiento

	CONSTRAINT PK_Calle	PRIMARY KEY(NumeroRuta)
);
--Procedimiento
--Antes de empezar hay que pasar todas las calles que ya tienen nombre
DECLARE	@Ruta		VARCHAR(1024),
		@Tipo		VARCHAR(32),
		@Longitud	FLOAT,
		@Geom		GEOMETRY
	--Declararar el cursor
	DECLARE cursor_calles_nombradas CURSOR FOR
	SELECT	*
	FROM	caminoTmp
	--Abrir cursor y usar FETCH
	OPEN cursor_tabla
	FETCH cursor_tabla INTO @Codigo, @Nombre, @Geom
--Primero crear un cursor para iterar por las calles que ya tienen nombres pero no han sido revisadas