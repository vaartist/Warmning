--Consultas.
USE DW_user4;

--Implementar las siguientes consultas (en orden de prioridad):
--1.--Lista--Obtener información sobre las estaciones de bomberos más cercanas a un punto cualquiera en el país.
--2.--Falta--Obtener información sobre las estaciones de bomberos más cercanas a un punto cualquiera en el país, tomando en cuenta la distancia real que debe recorrerse (caminos).
--3.--Falta--Obtener nivel de peligro de incendio en cualquier punto del país, tomando en cuenta zonas de riesgo y distancia a las estaciones de bomberos más cercanas con distancia real.
--4.--Falta--Obtener "área de influencia" de una estación de bomberos (mostrar según distancias de caminos el área que puede cubrir rápidamente). (nueva)
--5.--Falta--Obtener la unión de esas áreas de influencia para determinar lugares en el país que no estén dentro de ninguna, para recomendar creación de nuevas estaciones. (nueva)
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
			@Localizacion.STDistance(Geom)	AS	'Distancia en línea recta (metros)',	--Considerar usar ROUND para redondear la distancia
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
			CalcularDistanciaReal(@Localizacion, Geom)	AS	'Distancia en línea recta (metros)',	--Considerar usar ROUND para redondear la distancia
			CodigoDistrito								AS	'Código del distrito',
			Geom.ToString()								AS	'Ubicación en el mapa'					--Opcional
FROM		Estacion_Bomberos
ORDER BY	CalcularDistanciaReal(@Localizacion, Geom)
--Fin de consulta

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Consulta 3: Obtener nivel de peligro de incendio en cualquier punto del país, tomando en cuenta zonas de riesgo y distancia a las estaciones de bomberos más cercanas con distancia real.
--Se muestran los datos de manera formal para la consulta.
--Fin de consulta

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Consulta 4: Obtener "área de influencia" de una estación de bomberos (mostrar según distancias de caminos el área que puede cubrir rápidamente).
--Se muestran los datos de manera formal para la consulta.
--Fin de consulta

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Consulta 5: Obtener la unión de esas áreas de influencia para determinar lugares en el país que no estén dentro de ninguna, para recomendar creación de nuevas estaciones.
--Se muestran los datos de manera formal para la consulta.
--Fin de consulta

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
	RETURN	@DistanciaReal
END
--Fin de función
--DROP FUNCTION dbo.CalcularDistanciaReal