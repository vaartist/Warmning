use DW_user4;

DROP TABLE Informacion_Carreteras_Canton;
DROP TABLE Unidades_Estacion_Bomberos;
DROP TABLE Estacion_Bomberos;
DROP TABLE Interseca;
DROP TABLE Zonas_Riesgo;
DROP TABLE Distrito;
DROP TABLE Cruza;
DROP TABLE Camino;
DROP TABLE Canton;
DROP TABLE Provincia;



/* Modificaciones a modelo relacional:
	- Las geometrias se llaman Geom en todas las tablas
	- Los codigos de provincia, canton y distrito son int, eso acelerara la velocidad de comparación
	- A las foreign_key de canton, distrito, y estacion_bomberos las llamé "PerteneceA" 
	- Zonas_Riesgo también aparece llamado ZonasRiesgo, pero elegí el que usa _
Cualquier cosa si quieren me avisan y lo cambio */


CREATE TABLE Provincia
(
	Codigo						INTEGER,
	Nombre						VARCHAR(10) NOT NULL,
	Geom						GEOMETRY,
	
	CONSTRAINT pk_provincia PRIMARY KEY(codigo)
);

CREATE TABLE Canton
(
	Codigo						INTEGER,
	Nombre						VARCHAR(20) NOT NULL,
	CodigoProvincia				INTEGER NOT NULL,
	Geom						GEOMETRY,
	
	CONSTRAINT pk_canton PRIMARY KEY(codigo),
	CONSTRAINT fk_canton_provincia FOREIGN KEY(codigoProvincia) REFERENCES Provincia
		ON DELETE CASCADE 
		ON UPDATE CASCADE
);
/* Agregar triggers de restricciones positivas para los integers */

CREATE TABLE Distrito
(
	Codigo						INTEGER,
	Nombre						VARCHAR(25) NOT NULL,
	CodigoCanton				INTEGER NOT NULL,
	PoblacionHombres			INTEGER,
	PoblacionMujeres			INTEGER,
	ViviendasOcupadas			INTEGER,
	ViviendasDesocupadas		INTEGER,
	ViviendasColectivas			INTEGER,
	Geom						GEOMETRY,

	CONSTRAINT pk_distrito PRIMARY KEY(Codigo),
	CONSTRAINT fk_distrito_canton FOREIGN KEY(CodigoCanton) REFERENCES Canton
		ON DELETE CASCADE
		ON UPDATE CASCADE
);
/* Haremos trigger que calcule a que distrito pertenece la estacion_bomberos (la f.k)? */

CREATE TABLE Estacion_Bomberos
(
	Nombre					VARCHAR(55),
	Direccion				VARCHAR(120),
	CodigoDistrito			INTEGER,
	Geom					GEOMETRY,

	CONSTRAINT pk_estacionbomberos PRIMARY KEY(Nombre),
	CONSTRAINT fk_estacionbomberos_distrito FOREIGN KEY(CodigoDistrito) REFERENCES Distrito
		ON DELETE CASCADE
		ON UPDATE CASCADE
);
/* Trigger que calcule la longitud del camino */
CREATE TABLE Camino(
	NumeroRuta				VARCHAR(895),
	Tipo					VARCHAR(32),
	Longitud				FLOAT, -- Kilometros
	Geom					GEOMETRY,
	Revisado				BIT,

	CONSTRAINT pk_camino PRIMARY KEY(NumeroRuta)
);

CREATE TABLE Zonas_Riesgo
(
	MesesSecos					INTEGER,
	VelocidadViento				VARCHAR(10),
	Riesgo						VARCHAR(10) NOT NULL,
	Geom						GEOMETRY,

	CONSTRAINT pk_zonasriesgo PRIMARY KEY(MesesSecos,VelocidadViento)
);
/* Hacer trigger que revise que cobertura es mayor a 0? */

CREATE TABLE Interseca
(
	CodigoDistrito				INTEGER,
	MesesSecosZR				INTEGER,
	VelocidadVientoZR			VARCHAR(10),
	Cobertura					FLOAT, -- Porcentaje

	CONSTRAINT pk_interseca PRIMARY KEY(CodigoDistrito,MesesSecosZR,VelocidadVientoZR),
	CONSTRAINT fk_interseca_distrito FOREIGN KEY(CodigoDistrito) REFERENCES Distrito
		ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_interseca_zonasriesgo FOREIGN KEY(MesesSecosZR,VelocidadVientoZR) REFERENCES Zonas_Riesgo
		ON DELETE CASCADE ON UPDATE CASCADE
);
/* Trigger que calcule longitud */

CREATE TABLE Cruza
(
	CodigoCanton			INTEGER,
	NumeroRutaCamino		VARCHAR(895),
	Longitud FLOAT,

	CONSTRAINT pk_cruza PRIMARY KEY(CodigoCanton,NumeroRutaCamino),
	CONSTRAINT fk_cruza_canton FOREIGN KEY(CodigoCanton) REFERENCES Canton
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	CONSTRAINT fk_cruza_camino FOREIGN KEY(NumeroRutaCamino) REFERENCES Camino
		ON DELETE CASCADE
		ON UPDATE CASCADE
);
/* Trigger que revise que cantidad > 0*/

CREATE TABLE Unidades_Estacion_Bomberos
(
	NombreEstacion			VARCHAR(55),
	Tipo					VARCHAR(10),
	Cantidad				INTEGER,

	CONSTRAINT pk_unidades_estacion_bomberos PRIMARY KEY(NombreEstacion,Tipo),
	CONSTRAINT fk_unidadesestacionbomberos_estacionbomberos FOREIGN KEY(NombreEstacion) REFERENCES Estacion_Bomberos
		ON DELETE CASCADE
		ON UPDATE CASCADE
);
/* Calcular longitud? Revisar que sea mayor a 0 */

CREATE TABLE Informacion_Carreteras_Canton
(
	CodigoCanton				INTEGER,
	Tipo						VARCHAR(10),
	Longitud					FLOAT,

	CONSTRAINT pk_informacion_carreteras_canton PRIMARY KEY(CodigoCanton,Tipo),
	CONSTRAINT fk_informacioncarreterascanton_canton FOREIGN KEY(CodigoCanton) REFERENCES Canton
		ON DELETE CASCADE
		ON UPDATE CASCADE
);


/* CREACION DE INDICES */
/*
CREATE INDEX state_spatial_idx ON Provincia(Geom)
INDEXTYPE IS MDSYS.SPATIAL_INDEX;

CREATE INDEX state_spatial_idx ON Canton(Geom)
INDEXTYPE IS MDSYS.SPATIAL_INDEX;

CREATE INDEX state_spatial_idx ON Distrito(Geom)
INDEXTYPE IS MDSYS.SPATIAL_INDEX;

CREATE INDEX state_spatial_idx ON Estacion_Bomberos(Geom)
INDEXTYPE IS MDSYS.SPATIAL_INDEX;

CREATE INDEX state_spatial_idx ON Camino(Geom)
INDEXTYPE IS MDSYS.SPATIAL_INDEX;

CREATE INDEX state_spatial_idx ON Zonas_Riesgo(Geom)
INDEXTYPE IS MDSYS.SPATIAL_INDEX;
*/


