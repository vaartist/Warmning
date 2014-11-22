--Consultas.
USE DW_user4;

--Implementar las siguientes consultas (en orden de prioridad):
--1.--Lista--Obtener informaci�n sobre las estaciones de bomberos m�s cercanas a un punto cualquiera en el pa�s.
--2.--Falta--Obtener informaci�n sobre las estaciones de bomberos m�s cercanas a un punto cualquiera en el pa�s, tomando en cuenta la distancia real que debe recorrerse (caminos).
--3.--Lista--Obtener nivel de peligro de incendio en cualquier punto del pa�s, tomando en cuenta zonas de riesgo y distancia a las estaciones de bomberos m�s cercanas con distancia real.
--4.--Falta--Obtener "�rea de influencia" de una estaci�n de bomberos (m�s adelante mostrar seg�n distancias de caminos el �rea que puede cubrir r�pidamente). (nueva)
--5.--Falta--Obtener la uni�n de esas �reas de influencia para determinar lugares en el pa�s que no est�n dentro de ninguna, para recomendar creaci�n de nuevas estaciones. (nueva)
--6.--Falta--Obtener la cantidad de unidades distintas de las estaciones cuya �rea de influencia tocan un distrito.
--Agregar m�s porque 3 suena como muy poco...

SELECT	*	FROM	Provincia			--Listo
SELECT	*	FROM	Canton				--Listo
SELECT	*	FROM	Distrito			--Listo
SELECT	*	FROM	Zonas_Riesgo		--Listo
SELECT	*	FROM	Camino				--Falta--
SELECT	*	FROM	Cruza				--Falta--
SELECT	*	FROM	Interseca			--Listo
SELECT	*	FROM	Estacion_Bomberos	--Listo



--Problemas a resolver:
--1.C�mo obtener las coordenadas de cualquier punto en el pa�s de una forma f�cil, por ejemplo usando el mapa.
--  Por ahora se toman coordenadas de estaciones de bomberos y se modifican ligeramente para simular locaciones.
--2.C�mo implementar la funci�n de CalcularDistanciaReal. Se puede usar el algoritmo de Dijkstra para determinar
--  el camino m�s corto entre dos punto, pero �ste necesita nodos en cada v�rtice, y los caminos de esta BD s�lo
--  se intersecan, no poseen nodos en las intersecciones. En cuanto al peso de cada arista, se usar�a la distancia
--  del camino.



--Consulta 1: Obtener informaci�n sobre las estaciones de bomberos m�s cercanas a un punto cualquiera en el pa�s.
--Se muestran los datos de manera formal para la consulta, y se muestra informaci�n de las tres estaciones m�s cercanas (modificable).
DECLARE		@Localizacion	GEOMETRY
SET			@Localizacion = GEOMETRY::Point(478543.64500605746, 1106318.5944643875, 0) --el SRID usado es el 0
--M�s pruebas:
--SET		@Localizacion = GEOMETRY::Point(, , 0)
--SET		@Localizacion = GEOMETRY::Point(, , 0)
--SET		@Localizacion = GEOMETRY::Point(, , 0)
SELECT		TOP 3
			Nombre							AS	'Nombre de la estaci�n',
			Direccion						AS	'Direcci�n de la estaci�n',
			@Localizacion.STDistance(Geom)	AS	'Distancia en l�nea recta (kilometros)',	--Considerar usar ROUND para redondear la distancia
			CodigoDistrito					AS	'C�digo del distrito',
			Geom.ToString()					AS	'Ubicaci�n en el mapa'					--Opcional
FROM		Estacion_Bomberos
ORDER BY	@Localizacion.STDistance(Geom)
--Fin de consulta

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Consulta 2: Obtener informaci�n sobre las estaciones de bomberos m�s cercanas a un punto cualquiera en el pa�s, tomando en cuenta la distancia real que debe recorrerse (caminos).
--Se muestran los datos de manera formal para la consulta, y se muestra informaci�n de las tres estaciones m�s cercanas (modificable).
DECLARE		@Localizacion	GEOMETRY
SET			@Localizacion = GEOMETRY::Point(478543.64500605746, 1106318.5944643875, 0) --el SRID usado es el 0
--M�s pruebas:
--SET		@Localizacion = GEOMETRY::Point(, , 0)
--SET		@Localizacion = GEOMETRY::Point(, , 0)
--SET		@Localizacion = GEOMETRY::Point(, , 0)
SELECT		TOP 3
			Nombre											AS	'Nombre de la estaci�n',
			Direccion										AS	'Direcci�n de la estaci�n',
			dbo.CalcularDistanciaReal(@Localizacion, Geom)	AS	'Distancia real',			--Considerar usar ROUND para redondear la distancia
			CodigoDistrito									AS	'C�digo del distrito',
			Geom.ToString()									AS	'Ubicaci�n en el mapa'		--Opcional
FROM		Estacion_Bomberos
ORDER BY	dbo.CalcularDistanciaReal(@Localizacion, Geom)
--Fin de consulta

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Consulta 3: Obtener nivel de peligro de incendio en cualquier punto del pa�s, tomando en cuenta zonas de riesgo y distancia a las estaciones de bomberos m�s cercanas con distancia real.
--Se muestran los datos de manera formal para la consulta.
DECLARE		@Localizacion	GEOMETRY,
			@NivelPeligro	VARCHAR(10),
			@Distancia		FLOAT,
			@RangoRiesgo	INT
SET			@Localizacion = GEOMETRY::Point(478543.64500605746, 1106318.5944643875, 0) --el SRID usado es el 0
--M�s pruebas:
--SET		@Localizacion = GEOMETRY::Point(, , 0)
--SET		@Localizacion = GEOMETRY::Point(, , 0)
--SET		@Localizacion = GEOMETRY::Point(, , 0)
--Primero hay que fijarse si interseca con una zona de riesgo, y si es as�, revisar el nivel de riesgo de la misma
--Luego hay que obtener la distancia real a la estaci�n de bomberos m�s cercana, y seg�n esta disminuir o aumentar el nivel de peligro
SET @NivelPeligro = (SELECT TOP 1 ZR.Riesgo FROM Zonas_Riesgo ZR WHERE ZR.Geom.STIntersects( @Localizacion ) = 1 ORDER BY ( Select TOP 1 NR.Nivel FROM Nivel_Riesgo NR Where NR.Riesgo = ZR.Riesgo  ) DESC )
IF( @NivelPeligro is not null )
BEGIN
	SET @Distancia = ( SELECT TOP 1 @Localizacion.STDistance(Geom) FROM Estacion_Bomberos ORDER BY @Localizacion.STDistance(Geom) )
	SET @RangoRiesgo = ( SELECT Nivel FROM Nivel_Riesgo WHERE Riesgo = @NivelPeligro )
	IF( @Distancia < 10 AND @RangoRiesgo > 1 )
		SET @RangoRiesgo = @RangoRiesgo - 1
	IF( @Distancia > 50 AND @RangoRiesgo < 5 )
		SET @RangoRiesgo = @RangoRiesgo + 1
	SET @NivelPeligro = ( SELECT Riesgo FROM Nivel_Riesgo WHERE Nivel = @RangoRiesgo )
END
Select @NivelPeligro
--Fin de consulta
-- Tabla de evaluacion de nivel de riesgo
CREATE TABLE Nivel_Riesgo
(
	Nivel		int,
	Riesgo		varchar(10)
);
Insert Into Nivel_Riesgo Values( 1, 'BAJO' ), ( 2, 'BAJO-MEDIO' ), ( 3, 'MEDIO' ), ( 4, 'ALTO' ), ( 5, 'MUY ALTO' )

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Consulta 4: Obtener "�rea de influencia" de una estaci�n de bomberos (m�s adelante mostrar seg�n distancias de caminos el �rea que puede cubrir r�pidamente). (nueva)
--Se muestran los datos de manera formal para la consulta.
DECLARE		@Estacion		GEOMETRY,
			@Radio			INT
SET			@Estacion = (SELECT Geom FROM Estacion_Bomberos WHERE Nombre='BOMBEROS JUAN SANTAMARIA')
--M�s pruebas:
--SET			@Localizacion = (SELECT Geom FROM Estacion_Bomberos WHERE Nombre='CENTRAL BOMBEROS ALAJUELA')
--SET			@Localizacion = (SELECT Geom FROM Estacion_Bomberos WHERE Nombre='CENTRAL BOMBEROS CARTAGO')
--SET			@Localizacion = (SELECT Geom FROM Estacion_Bomberos WHERE Nombre='CENTRAL BOMBEROS OROTINA')
--Primero hay que determinar un radio de influencia apropiado, por ejemplo 10 KILOmetros
SET			@Radio = 20000
--Luego hay que obtener el �rea alrededor, o un "buffer"
SELECT		@Estacion.STBuffer(@Radio)
--Fin de consulta

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Consulta 5: Obtener la uni�n de esas �reas de influencia para determinar lugares en el pa�s que no est�n dentro de ninguna, para recomendar creaci�n de nuevas estaciones.
--Se muestran los datos de manera formal para la consulta.
DECLARE		@AreasInfluencia	GEOMETRY,
			@Localizacion		GEOMETRY,
			@Radio				INT,
			@AreaTotal			GEOMETRY,
			@AreasRiesgo		GEOMETRY
SET			@Radio = 20000
--Primero se usa un cursor para iterar por la tabla de estaciones de bomberos e ir uniendo las geometr�as de las �reas de influencia de cada una
DECLARE		Cursor_Estaciones	CURSOR FOR
			SELECT				Geom
			FROM				Estacion_Bomberos
OPEN		Cursor_Estaciones
FETCH NEXT	FROM Cursor_Estaciones INTO @Localizacion
IF (@@FETCH_STATUS = 0)
			SET			@AreasInfluencia = @Localizacion.STBuffer(@Radio)								--Se iguala a la primera, luego se le unen las dem�s
FETCH NEXT	FROM Cursor_Estaciones INTO @Localizacion
WHILE (@@FETCH_STATUS = 0)
BEGIN
			SET			@AreasInfluencia = @AreasInfluencia.STUnion(@Localizacion.STBuffer(@Radio))		--Se le unen las dem�s
			FETCH NEXT	FROM Cursor_Estaciones INTO @Localizacion
END
CLOSE		Cursor_Estaciones
DEALLOCATE	Cursor_Estaciones
--SELECT		@AreasInfluencia
--Despu�s se obtiene con otro cursor la geometr�a de todo el pa�s (la uni�n de todas las provincias), a pie, para hacer m�s
DECLARE		Cursor_Provincias	CURSOR FOR
			SELECT				Geom
			FROM				Provincia
OPEN		Cursor_Provincias
FETCH NEXT	FROM Cursor_Provincias INTO @Localizacion												--Se reutiliza la variable "localizaci�n"
IF (@@FETCH_STATUS = 0)
			SET			@AreaTotal = @Localizacion													--Se iguala a la primera, luego se le unen las dem�s
FETCH NEXT	FROM Cursor_Provincias INTO @Localizacion
WHILE (@@FETCH_STATUS = 0)
BEGIN
			SET			@AreaTotal = @AreaTotal.STUnion(@Localizacion)								--Se le unen las dem�s
			FETCH NEXT	FROM Cursor_Provincias INTO @Localizacion
END
CLOSE		Cursor_Provincias
DEALLOCATE	Cursor_Provincias
--SELECT		@AreaTotal
--Luego se obtiene la diferencia de todo el pa�s y lo obtenido anteriormente
SET			@AreasRiesgo = @AreaTotal.STDifference(@AreasInfluencia)
SELECT		@AreasRiesgo
--Fin de consulta

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Consulta 6. Obtener la cantidad de unidades distintas de las estaciones cuya �rea de influencia tocan un distrito.
--Se muestran los datos de manera formal para la consulta.
DECLARE	@Codigo_Distrito	integer,
		@Geom_Distrito		geometry,
		@Radio				integer
SET		@Codigo_Distrito = 40205
SET		@Radio = 20000
SET		@Geom_Distrito = ( SELECT Geom FROM Distrito WHERE Codigo = @Codigo_Distrito )
SELECT Tipo as 'Tipo De Unidad', SUM(Cantidad) as 'Cantidad'
FROM Estacion_Bomberos join Unidades_Estacion_Bomberos on Nombre = NombreEstacion
WHERE Geom.STBuffer(@Radio).STIntersects( @Geom_Distrito ) = 1
GROUP BY Tipo

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Funci�n para calcular distancia real (seg�n caminos) entre dos puntos.
CREATE FUNCTION dbo.CalcularDistanciaReal
(
	@LocalizacionA	GEOMETRY,
	@LocalizacionB	GEOMETRY
)
RETURNS	INT
AS
BEGIN
	--Primero hay que procesar los caminos alrededor del punto de incendio, almacenando
	--sus nodos y aristas en las tablas respectivas
	dbo.ProcesarCaminosAlrededorDe(@LocalizacionA)
	--Luego hay que encontrar la ruta �ptima usando la variaci�n del algoritmo de Dijsktra
	RETURN	dbo.Dijkstra(@LocalizacionA, @LocalizacionB)
END
--Fin de funci�n
--DROP FUNCTION dbo.CalcularDistanciaReal

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Calcular on-demand los v�rtices y aristas de las calles cuando se consulten distancias reales
CREATE FUNCTION dbo.ProcesarCaminosAlrededorDe
(
	@Localizacion	GEOMETRY
)
RETURNS VOID
AS
BEGIN
	DECLARE	@DistanciaEstacionMasLejana	INT,
			@BufferAlrededorDeLocacion	GEOMETRY,
			@NumeroRutaCamino			VARCHAR(895),
			@GeometriaCamino			GEOMETRY
	--Primero se calcula la distancia a la estaci�n m�s lejana de las (por ahora 3) m�s cercanas
	SET		@DistanciaEstacionMasLejana = (SELECT		TOP 1
														Distancia
											FROM		(SELECT		TOP 3
																	@Localizacion.STDistance(Geom) AS Distancia
														FROM		Estacion_Bomberos
														ORDER BY	@Localizacion.STDistance(Geom)) AS Resultado
											ORDER BY	Distancia DESC)
	--Luego se obtiene un buffer alrededor de la locaci�n usando esa distancia m�s un poco m�s (5 kil�metros por ahora)
	SET		@BufferAlrededorDeLocacion = @Localizacion.STBuffer(@DistanciaEstacionMasLejana + 5000)
	--Despu�s con un cursor se itera por los caminos que intersecan ese buffer y no han sido procesados,
	--para procesarlos (agregar sus nodos y aristas a las tablas respectivas)
	DECLARE	cursor_caminos	CURSOR FOR
		SELECT	NumeroRuta, Geom
		FROM	Camino
		WHERE	Procesado = 0 AND Geom.STIntersects(@BufferAlrededorDeLocacion) = 1
	--Abrir cursor y usar FETCH
	OPEN cursor_caminos
	FETCH cursor_caminos INTO @NumeroRutaCamino, @GeometriaCamino
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		--Se declara otro cursor para iterar por todos los "puntos" donde el camino se interseca con otro
		--y agregar �stos a la tabla de nodos

		--Luego se divide ese camino en aristas usando los nodos existentes, tal que si dos nodos intersecan
		--al camino, se agrega la arista a la tabla como el subcamino comprendido entre esos dos nodos
		FETCH NEXT FROM cursor_tabla INTO @NumeroRutaCamino, @GeometriaCamino
	END
	--Cerrar cursor
	CLOSE cursor_caminos
	DEALLOCATE cursor_caminos
END
--Fin de funci�n
--DROP FUNCTION dbo.ProcesarCaminosAlrededorDe
