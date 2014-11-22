--Consultas.
USE DW_user4;

--Implementar las siguientes consultas (en orden de prioridad):
--1.--Lista--Obtener información sobre las estaciones de bomberos más cercanas a un punto cualquiera en el país.
--2.--Falta--Obtener información sobre las estaciones de bomberos más cercanas a un punto cualquiera en el país, tomando en cuenta la distancia real que debe recorrerse (caminos).
--3.--Lista--Obtener nivel de peligro de incendio en cualquier punto del país, tomando en cuenta zonas de riesgo y distancia a las estaciones de bomberos más cercanas con distancia real.
--4.--Falta--Obtener "área de influencia" de una estación de bomberos (más adelante mostrar según distancias de caminos el área que puede cubrir rápidamente). (nueva)
--5.--Falta--Obtener la unión de esas áreas de influencia para determinar lugares en el país que no estén dentro de ninguna, para recomendar creación de nuevas estaciones. (nueva)
--6.--Falta--Obtener la cantidad de unidades distintas de las estaciones cuya área de influencia tocan un distrito.
--Agregar más porque 3 suena como muy poco...

SELECT	*	FROM	Provincia			--Listo
SELECT	*	FROM	Canton				--Listo
SELECT	*	FROM	Distrito			--Listo
SELECT	*	FROM	Zonas_Riesgo		--Listo
SELECT	*	FROM	Camino				--Falta--
SELECT	*	FROM	Cruza				--Falta--
SELECT	*	FROM	Interseca			--Listo
SELECT	*	FROM	Estacion_Bomberos	--Listo

--REVISAR:
SELECT	*	FROM	Canton	WHERE	Nombre='HEREDIA';
--Parece que el cantón de Heredia abarca dos áreas, al centro y arriba debajo de Sarapiquí, y está bien:
-- http://www.mapasdecostarica.info/atlascantonal/heredia.htm
--Borrar esto después.




--Problemas a resolver:
--1.Cómo obtener las coordenadas de cualquier punto en el país de una forma fácil, por ejemplo usando el mapa.
--  Por ahora se toman coordenadas de estaciones de bomberos y se modifican ligeramente para simular locaciones.
--2.Cómo implementar la función de CalcularDistanciaReal. Se puede usar el algoritmo de Dijkstra para determinar
--  el camino más corto entre dos punto, pero éste necesita nodos en cada vértice, y los caminos de esta BD sólo
--  se intersecan, no poseen nodos en las intersecciones. En cuanto al peso de cada arista, se usaría la distancia
--  del camino.



--Consulta 1: Obtener información sobre las estaciones de bomberos más cercanas a un punto cualquiera en el país.
--Se muestran los datos de manera formal para la consulta, y se muestra información de las tres estaciones más cercanas (modificable).
DECLARE		@Localizacion	GEOMETRY
SET			@Localizacion = GEOMETRY::Point(478543.64500605746, 1106318.5944643875, 0) --el SRID usado es el 0
--Más pruebas:
--SET		@Localizacion = GEOMETRY::Point(, , 0)
--SET		@Localizacion = GEOMETRY::Point(, , 0)
--SET		@Localizacion = GEOMETRY::Point(, , 0)
SELECT		TOP 3
			Nombre							AS	'Nombre de la estación',
			Direccion						AS	'Dirección de la estación',
			@Localizacion.STDistance(Geom)	AS	'Distancia en línea recta (kilometros)',	--Considerar usar ROUND para redondear la distancia
			CodigoDistrito					AS	'Código del distrito',
			Geom.ToString()					AS	'Ubicación en el mapa'					--Opcional
FROM		Estacion_Bomberos
ORDER BY	@Localizacion.STDistance(Geom)
--Fin de consulta

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Consulta 2: Obtener información sobre las estaciones de bomberos más cercanas a un punto cualquiera en el país, tomando en cuenta la distancia real que debe recorrerse (caminos).
--Se muestran los datos de manera formal para la consulta, y se muestra información de las tres estaciones más cercanas (modificable).
DECLARE		@Localizacion	GEOMETRY
SET			@Localizacion = GEOMETRY::Point(478543.64500605746, 1106318.5944643875, 0) --el SRID usado es el 0
--Más pruebas:
--SET		@Localizacion = GEOMETRY::Point(, , 0)
--SET		@Localizacion = GEOMETRY::Point(, , 0)
--SET		@Localizacion = GEOMETRY::Point(, , 0)
SELECT		TOP 3
			Nombre										AS	'Nombre de la estación',
			Direccion									AS	'Dirección de la estación',
			CalcularDistanciaReal(@Localizacion, Geom)	AS	'Distancia en línea recta (kilometros)',	--Considerar usar ROUND para redondear la distancia
			CodigoDistrito								AS	'Código del distrito',
			Geom.ToString()								AS	'Ubicación en el mapa'					--Opcional
FROM		Estacion_Bomberos
ORDER BY	CalcularDistanciaReal(@Localizacion, Geom)
--Fin de consulta

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Consulta 3: Obtener nivel de peligro de incendio en cualquier punto del país, tomando en cuenta zonas de riesgo y distancia a las estaciones de bomberos más cercanas con distancia real.
--Se muestran los datos de manera formal para la consulta.
DECLARE		@Localizacion	GEOMETRY,
			@NivelPeligro	VARCHAR(10),
			@Distancia		FLOAT,
			@RangoRiesgo	INT
SET			@Localizacion = GEOMETRY::Point(478543.64500605746, 1106318.5944643875, 0) --el SRID usado es el 0
--Más pruebas:
--SET		@Localizacion = GEOMETRY::Point(, , 0)
--SET		@Localizacion = GEOMETRY::Point(, , 0)
--SET		@Localizacion = GEOMETRY::Point(, , 0)
--Primero hay que fijarse si interseca con una zona de riesgo, y si es así, revisar el nivel de riesgo de la misma
--Luego hay que obtener la distancia real a la estación de bomberos más cercana, y según esta disminuir o aumentar el nivel de peligro
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

--Consulta 4: Obtener "área de influencia" de una estación de bomberos (más adelante mostrar según distancias de caminos el área que puede cubrir rápidamente). (nueva)
--Se muestran los datos de manera formal para la consulta.
DECLARE		@Estacion		GEOMETRY,
			@Radio			INT
SET			@Estacion = (SELECT Geom FROM Estacion_Bomberos WHERE Nombre='BOMBEROS JUAN SANTAMARIA')
--Más pruebas:
--SET			@Localizacion = (SELECT Geom FROM Estacion_Bomberos WHERE Nombre='CENTRAL BOMBEROS ALAJUELA')
--SET			@Localizacion = (SELECT Geom FROM Estacion_Bomberos WHERE Nombre='CENTRAL BOMBEROS CARTAGO')
--SET			@Localizacion = (SELECT Geom FROM Estacion_Bomberos WHERE Nombre='CENTRAL BOMBEROS OROTINA')
--Primero hay que determinar un radio de influencia apropiado, por ejemplo 10 KILOmetros
SET			@Radio = 20000
--Luego hay que obtener el área alrededor, o un "buffer"
SELECT		@Estacion.STBuffer(@Radio)
--Fin de consulta

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Consulta 5: Obtener la unión de esas áreas de influencia para determinar lugares en el país que no estén dentro de ninguna, para recomendar creación de nuevas estaciones.
--Se muestran los datos de manera formal para la consulta.
DECLARE		@AreasInfluencia	GEOMETRY,
			@Localizacion		GEOMETRY,
			@Radio				INT,
			@AreaTotal			GEOMETRY,
			@AreasRiesgo		GEOMETRY
SET			@Radio = 20000
--Primero se usa un cursor para iterar por la tabla de estaciones de bomberos e ir uniendo las geometrías de las áreas de influencia de cada una
DECLARE		Cursor_Estaciones	CURSOR FOR
			SELECT				Geom
			FROM				Estacion_Bomberos
OPEN		Cursor_Estaciones
FETCH NEXT	FROM Cursor_Estaciones INTO @Localizacion
IF (@@FETCH_STATUS = 0)
			SET			@AreasInfluencia = @Localizacion.STBuffer(@Radio)								--Se iguala a la primera, luego se le unen las demás
FETCH NEXT	FROM Cursor_Estaciones INTO @Localizacion
WHILE (@@FETCH_STATUS = 0)
BEGIN
			SET			@AreasInfluencia = @AreasInfluencia.STUnion(@Localizacion.STBuffer(@Radio))		--Se le unen las demás
			FETCH NEXT	FROM Cursor_Estaciones INTO @Localizacion
END
CLOSE		Cursor_Estaciones
DEALLOCATE	Cursor_Estaciones
--SELECT		@AreasInfluencia
--Después se obtiene con otro cursor la geometría de todo el país (la unión de todas las provincias), a pie, para hacer más
DECLARE		Cursor_Provincias	CURSOR FOR
			SELECT				Geom
			FROM				Provincia
OPEN		Cursor_Provincias
FETCH NEXT	FROM Cursor_Provincias INTO @Localizacion												--Se reutiliza la variable "localización"
IF (@@FETCH_STATUS = 0)
			SET			@AreaTotal = @Localizacion													--Se iguala a la primera, luego se le unen las demás
FETCH NEXT	FROM Cursor_Provincias INTO @Localizacion
WHILE (@@FETCH_STATUS = 0)
BEGIN
			SET			@AreaTotal = @AreaTotal.STUnion(@Localizacion)								--Se le unen las demás
			FETCH NEXT	FROM Cursor_Provincias INTO @Localizacion
END
CLOSE		Cursor_Provincias
DEALLOCATE	Cursor_Provincias
--SELECT		@AreaTotal
--Luego se obtiene la diferencia de todo el país y lo obtenido anteriormente
SET			@AreasRiesgo = @AreaTotal.STDifference(@AreasInfluencia)
SELECT		@AreasRiesgo
--Fin de consulta

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Consulta 6. Obtener la cantidad de unidades distintas de las estaciones cuya área de influencia tocan un distrito.
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

--Función para calcular distancia real (según caminos) entre dos puntos.
CREATE FUNCTION dbo.CalcularDistanciaReal
(
	@LocalizacionA	GEOMETRY,
	@LocalizacionB	GEOMETRY
)
RETURNS	INT
AS
BEGIN
	DECLARE	@DistanciaReal	INT
	--Primero hay que encontrar la ruta óptima
	RETURN	@DistanciaReal
END
--Fin de función
--DROP FUNCTION dbo.CalcularDistanciaReal