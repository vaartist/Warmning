--Consultas.
USE DW_user4;

--Implementar las siguientes consultas (en orden de prioridad):
--1.--Lista--Obtener informaci�n sobre las estaciones de bomberos m�s cercanas a un punto cualquiera en el pa�s.
--2.--Falta--Obtener informaci�n sobre las estaciones de bomberos m�s cercanas a un punto cualquiera en el pa�s, tomando en cuenta la distancia real que debe recorrerse (caminos).
--3.--Falta--Obtener nivel de peligro de incendio en cualquier punto del pa�s, tomando en cuenta zonas de riesgo y distancia a las estaciones de bomberos m�s cercanas con distancia real.
--4.--Falta--Obtener "�rea de influencia" de una estaci�n de bomberos (mostrar seg�n distancias de caminos el �rea que puede cubrir r�pidamente). (nueva)
--5.--Falta--Obtener la uni�n de esas �reas de influencia para determinar lugares en el pa�s que no est�n dentro de ninguna, para recomendar creaci�n de nuevas estaciones. (nueva)
--Agregar m�s porque 3 suena como muy poco...

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
--Parece que el cant�n de Heredia abarca dos �reas, al centro y arriba debajo de Sarapiqu�, y est� bien:
-- http://www.mapasdecostarica.info/atlascantonal/heredia.htm
--Borrar esto despu�s.




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
			@Localizacion.STDistance(Geom)	AS	'Distancia en l�nea recta (metros)',	--Considerar usar ROUND para redondear la distancia
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
			Nombre										AS	'Nombre de la estaci�n',
			Direccion									AS	'Direcci�n de la estaci�n',
			CalcularDistanciaReal(@Localizacion, Geom)	AS	'Distancia en l�nea recta (metros)',	--Considerar usar ROUND para redondear la distancia
			CodigoDistrito								AS	'C�digo del distrito',
			Geom.ToString()								AS	'Ubicaci�n en el mapa'					--Opcional
FROM		Estacion_Bomberos
ORDER BY	CalcularDistanciaReal(@Localizacion, Geom)
--Fin de consulta

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Consulta 3: Obtener nivel de peligro de incendio en cualquier punto del pa�s, tomando en cuenta zonas de riesgo y distancia a las estaciones de bomberos m�s cercanas con distancia real.
--Se muestran los datos de manera formal para la consulta.
--Fin de consulta

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Consulta 4: Obtener "�rea de influencia" de una estaci�n de bomberos (mostrar seg�n distancias de caminos el �rea que puede cubrir r�pidamente).
--Se muestran los datos de manera formal para la consulta.
--Fin de consulta

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Consulta 5: Obtener la uni�n de esas �reas de influencia para determinar lugares en el pa�s que no est�n dentro de ninguna, para recomendar creaci�n de nuevas estaciones.
--Se muestran los datos de manera formal para la consulta.
--Fin de consulta

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
	DECLARE	@DistanciaReal	INT
	RETURN	@DistanciaReal
END
--Fin de funci�n
--DROP FUNCTION dbo.CalcularDistanciaReal