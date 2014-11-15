--Algoritmo de Dijkstra para encontrar el camino más corto desde un nodo inicial a uno final.
--@StartNode: ID del nodo inicial.
--@EndNode: ID del nodo final, al encontrarse debe detenerse el algoritmo (si es NULL se encuentra el camino más corto a todos los otros nodos).
--DROP PROCEDURE dbo.Dijkstra
CREATE PROCEDURE dbo.Dijkstra
(
	@StartNode	INT,
	@EndNode	INT = NULL
)
AS
BEGIN
    --Hacer rollback automático si algo sale mal
    SET XACT_ABORT ON
    BEGIN TRAN

    --Aumenta el rendimiento sin interferir con los resultados
    SET NOCOUNT ON;
 
    --Crear una tabla temporal para almacenar los nodos explorados y pesos estimados
    CREATE TABLE #Nodes
    (
        ID			INT				NOT NULL PRIMARY KEY,
        Estimate	DECIMAL(10,3)	NOT NULL,				--Distancia al nodo
        Predecessor	INT				NULL,					--El nodo anterior, desde donde venimos
        Done		BIT				NOT NULL				--Si ya terminamos con este nodo o no
    )

    --Llenar la tabla temporal con datos iniciales
    INSERT INTO	#Nodes(ID, Estimate, Predecessor, Done)
    SELECT		ID, 9999999.999, NULL, 0
	FROM		dbo.Vertices_Calles
    
    --La distancia estimada hacia el nodo inicial es 0
    UPDATE		#Nodes
	SET			Estimate = 0
	WHERE		ID = @StartNode
    IF (@@ROWCOUNT <> 1)
    BEGIN
        DROP TABLE	#Nodes
        RAISERROR	('No se pudo actualizar el nodo inicial', 11, 1)
        ROLLBACK	TRAN
        RETURN		1
    END
	
    DECLARE	@FromNode			INT,
			@CurrentEstimate	INT
 
    --Correr el algoritmo hasta terminar
    WHILE (1 = 1) --while (true)
    BEGIN
        --Resetear la variable inicial, para poder detectar el no obtener nada en el siguiente paso
        SELECT		@FromNode = NULL
 
        --Obtener el ID y la estimación actual para un nodo no terminado, con la menor estimación
        SELECT		TOP 1
					@FromNode = ID,
					@CurrentEstimate = Estimate
        FROM		#Nodes
		WHERE		Done = 0	AND
					Estimate < 9999999.999
        ORDER BY	Estimate
         
        --Detenerse si ya no quedan nodos alcanzables sin visitar
        IF (@FromNode IS NULL	OR	@FromNode = @EndNode)
			BREAK
 
        --Terminar con el nodo
        UPDATE		#Nodes
		SET			Done = 1
		WHERE		ID = @FromNode
 
        --Actualizar los estimados de todos los nodos vecinos a este
        --Sólo actualizar el estimado si el nuevo es menor.
        UPDATE		#Nodes
        SET			Estimate = @CurrentEstimate + e.Longitud,
					Predecessor = @FromNode
        FROM		#Nodes n INNER JOIN dbo.Aristas_Calles e ON n.ID = e.VerticeFinal
        WHERE		Done = 0	AND
					e.VerticeInicio = @FromNode	AND
					(@CurrentEstimate + e.Longitud) < n.Estimate
		--Bidireccional:
		UPDATE		#Nodes
        SET			Estimate = @CurrentEstimate + e.Longitud,
					Predecessor = @FromNode
        FROM		#Nodes n INNER JOIN dbo.Aristas_Calles e ON n.ID = e.VerticeInicio
        WHERE		Done = 0	AND
					e.VerticeFinal = @FromNode	AND
					(@CurrentEstimate + e.Longitud) < n.Estimate
    END;
	
    --Seleccionar los resultados usando una expresion recursiva de tabla común
    --para obtener todo el camino desde el nodo inicial hasta el actual
    WITH	BacktraceCTE(ID, Name, Distance, Path, NamePath)
    AS
    (
        --Miembro base de la recursión
        SELECT	n.ID,
				node.Nombre,
				n.Estimate,
				CAST(n.ID AS varchar(8000)),
				CAST(node.Nombre AS varchar(8000))
        FROM	#Nodes n JOIN dbo.Vertices_Calles node ON n.ID = node.ID
        WHERE	n.ID = @StartNode
         
        UNION ALL
         
        --Miembro recursivo, seleccionar todos los nodos que tienen al previo
		--como predecesor, concatenar los caminos
        SELECT	n.ID,
				node.Nombre,
				n.Estimate,
				CAST(cte.Path + ',' + CAST(n.ID as varchar(10)) as varchar(8000)),
				CAST(cte.NamePath + ',' + node.Nombre AS varchar(8000))
        FROM	#Nodes n JOIN BacktraceCTE cte ON n.Predecessor = cte.ID
				JOIN dbo.Vertices_Calles node ON n.ID = node.ID
    )
    SELECT	ID,
			Name,
			Distance,
			Path,
			NamePath
	FROM	BacktraceCTE
    WHERE	ID = @EndNode	OR
			@EndNode IS NULL		--Tener cuidado con esto, mal plan de ejecución
    DROP TABLE	#Nodes
    COMMIT TRAN
    RETURN 0
END

------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Pruebas
--Crear tablas necesarias
--Tabla Vertices_Calles, contiene un ID de nodo, un nombre opcional y la geometría con la ubicación del punto.
CREATE TABLE Vertices_Calles
(
	ID		INT				IDENTITY(1,1),
	Nombre	VARCHAR(1000),
	Geom	GEOMETRY
	CONSTRAINT	PK_Vertices	PRIMARY KEY(ID)
);
--DROP TABLE Vertices_Calles
--
--Tabla Aristas_Calles, contiene los IDs de 
CREATE TABLE Aristas_Calles
(
	VerticeInicio	INT,
	VerticeFinal	INT,
	Longitud		FLOAT
	CONSTRAINT	PK_Aristas	PRIMARY KEY(VerticeInicio, VerticeFinal),
	CONSTRAINT	FK_NodoI	FOREIGN KEY(VerticeInicio)	REFERENCES Vertices_Calles(ID),
	CONSTRAINT	FK_NodoF	FOREIGN KEY(VerticeFinal)	REFERENCES Vertices_Calles(ID)
);
--DROP TABLE Aristas_Calles
--

--Insertar datos básicos de prueba, más adelante se usarán datos reales de la tabla Camino
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 1, 2 y 4', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 2, 3 y 5', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 4, 6 y 8', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 5, 7 y 9', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 8 y 10', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 9, 12 y 14', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 11, 12 y 13', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 14 y 15', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 10 y 16', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 15, 18 y 19', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 17, 18 y 22', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 19 y 20', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 20 y 21', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 1 y ?', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 3 y ?', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 16 y ?', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 22 y ?', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 21 y ?', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 23 y ?', null)
INSERT INTO Vertices_Calles
VALUES('Cruce entre calles 23 y ?', null)
INSERT INTO Vertices_Calles
VALUES('Final de calle 6', null)
INSERT INTO Vertices_Calles
VALUES('Final de calle 7', null)
INSERT INTO Vertices_Calles
VALUES('Final de calle 11', null)
INSERT INTO Vertices_Calles
VALUES('Final de calle 13', null)
INSERT INTO Vertices_Calles
VALUES('Final de calle 17', null)
--
SELECT	*	FROM	Vertices_Calles
DELETE		FROM	Vertices_Calles
--
INSERT INTO Aristas_Calles
VALUES(1, 2, 550)
INSERT INTO Aristas_Calles
VALUES(1, 3, 100)
INSERT INTO Aristas_Calles
VALUES(2, 4, 150)
INSERT INTO Aristas_Calles
VALUES(3, 5, 250)
INSERT INTO Aristas_Calles
VALUES(4, 6, 300)
INSERT INTO Aristas_Calles
VALUES(6, 7, 250)
INSERT INTO Aristas_Calles
VALUES(5, 9, 150)
INSERT INTO Aristas_Calles
VALUES(6, 8, 125)
INSERT INTO Aristas_Calles
VALUES(8, 10, 250)
INSERT INTO Aristas_Calles
VALUES(10, 11, 100)
INSERT INTO Aristas_Calles
VALUES(10, 12, 200)
INSERT INTO Aristas_Calles
VALUES(12, 13, 200)
INSERT INTO Aristas_Calles
VALUES(1, 14, 50)
INSERT INTO Aristas_Calles
VALUES(2, 15, 50)
INSERT INTO Aristas_Calles
VALUES(9, 16, 50)
INSERT INTO Aristas_Calles
VALUES(11, 17, 400)
INSERT INTO Aristas_Calles
VALUES(13, 18, 50)
INSERT INTO Aristas_Calles
VALUES(19, 20, 400)
INSERT INTO Aristas_Calles
VALUES(3, 21, 200)
INSERT INTO Aristas_Calles
VALUES(4, 22, 300)
INSERT INTO Aristas_Calles
VALUES(7, 23, 200)
INSERT INTO Aristas_Calles
VALUES(7, 24, 50)
INSERT INTO Aristas_Calles
VALUES(11, 25, 350)
--
SELECT	*	FROM	Aristas_Calles
DELETE		FROM	Aristas_Calles
--

EXEC	Dijkstra 1
EXEC	Dijkstra 5, 25
EXEC	Dijkstra 13, 25