DROP TABLE Provincia;
DROP TABLE Canton;
DROP TABLE Distrito;
DROP TABLE Estacion_Bomberos;
DROP TABLE Camino;
DROP TABLE Zonas_Riesgo;
DROP TABLE Interseca;
DROP TABLE Cruza;
DROP TABLE Unidades_Estacion_Bomberos;
DROP TABLE Informacion_Carreteras_Canton;

/* Modificaciones a modelo relacional:
	- Las geometrias se llaman Geom en todas las tablas
	- Los codigos de provincia, canton y distrito son int, eso acelerara la velocidad de comparacion
	- A las foreign_key de canton, distrito, y estacion_bomberos las llame "PerteneceA" 
	- Zonas_Riesgo tambien aparece llamado ZonasRiesgo, pero elegi el que usa _
Cualquier cosa si quieren me avisan y lo cambio */


CREATE TABLE Provincia(
	Codigo						INTEGER,
	Nombre						VARCHAR(10) NOT NULL,
	Geom						geometry,
	
	CONSTRAINT pk_provincia PRIMARY KEY(codigo)
);
CREATE TABLE Canton(
	Codigo						INTEGER,
	Nombre						VARCHAR(20) NOT NULL,
	CodigoProvincia				INTEGER NOT NULL,
	Geom						geometry,
	
	CONSTRAINT pk_canton PRIMARY KEY(codigo),
	CONSTRAINT fk_canton_provincia FOREIGN KEY(codigoProvincia) REFERENCES Provincia
);
/* Agregar triggers de restricciones positivas para los integers */
CREATE TABLE Distrito(
	Codigo						INTEGER,
	Nombre						VARCHAR(20) NOT NULL,
	PerteneceA					INTEGER NOT NULL,
	Poblacion_H					INTEGER,
	Poblacion_M					INTEGER,
	ViviendasO					INTEGER,
	ViviendasD					INTEGER,
	ViviendasC					INTEGER,
	Geom						geometry,

	CONSTRAINT pk_distrito PRIMARY KEY(Codigo),
	CONSTRAINT fk_distrito_canton FOREIGN KEY(PerteneceA) REFERENCES Canton
);
/* Haremos trigger que calcule a que distrito pertenece la estacion_bomberos (la f.k)? */
CREATE TABLE Estacion_Bomberos(
	Nombre VARCHAR(25),
	Direccion VARCHAR(100),
	PerteneceA INTEGER,
	Geom geometry,

	CONSTRAINT pk_estacionbomberos PRIMARY KEY(Nombre),
	CONSTRAINT fk_estacionbomberos_distrito FOREIGN KEY(PerteneceA) REFERENCES Distrito
);
/* Trigger que calcule la longitud del camino */
CREATE TABLE Camino(
	Numero_Ruta VARCHAR(15),
	Tipo VARCHAR(15),
	Longitud FLOAT,
	Geom geometry,

	CONSTRAINT pk_camino PRIMARY KEY(Numero_Ruta)
);
CREATE TABLE Zonas_Riesgo(
	Meses_Secos INTEGER,
	Velocidad_Viento VARCHAR(10),
	Riesgo VARCHAR(10) NOT NULL,
	Geom geometry,

	CONSTRAINT pk_zonasriesgo PRIMARY KEY(Meses_Secos,Velocidad_Viento)
);
/* Hacer trigger que revise que cobertura es mayor a 0? */
CREATE TABLE Interseca(
	Codigo_Distrito INTEGER,
	Meses_Secos INTEGER,
	Velocidad_Viento VARCHAR(10),
	Cobertura FLOAT,

	CONSTRAINT pk_interseca PRIMARY KEY(Codigo_Distrito,Meses_Secos,Velocidad_Viento),
	CONSTRAINT fk_interseca_distrito FOREIGN KEY(Codigo_Distrito) REFERENCES Distrito,
	CONSTRAINT fk_interseca_zonasriesgo FOREIGN KEY(Meses_Secos,Velocidad_Viento) REFERENCES Zonas_Riesgo
);
/* Trigger que calcule longitud */
CREATE TABLE Cruza(
	Codigo_Canton INTEGER,
	Numero_Ruta_Camino VARCHAR(15),
	Longitud FLOAT,

	CONSTRAINT pk_cruza PRIMARY KEY(Codigo_Canton,Numero_Ruta_Camino),
	CONSTRAINT fk_cruza_canton FOREIGN KEY(Codigo_Canton) REFERENCES Canton,
	CONSTRAINT fk_cruza_camino FOREIGN KEY(Numero_Ruta_Camino) REFERENCES Camino
);
/* Trigger que revise que cantidad > 0*/
CREATE TABLE Unidades_Estacion_Bomberos(
	Nombre_Estacion VARCHAR(25),
	Tipo VARCHAR(10),
	Cantidad INTEGER,

	CONSTRAINT pk_unidades_estacion_bomberos PRIMARY KEY(Nombre_Estacion,Tipo),
	CONSTRAINT fk_unidadesestacionbomberos_estacionbomberos FOREIGN KEY(Nombre_Estacion) REFERENCES Estacion_Bomberos
);
/* Calcular longitud? Revisar que sea mayor a 0 */
CREATE TABLE Informacion_Carreteras_Canton(
	Codigo_Canton INTEGER,
	Tipo VARCHAR(10),
	Longitud FLOAT,

	CONSTRAINT pk_informacion_carreteras_canton PRIMARY KEY(Codigo_Canton,Tipo),
	CONSTRAINT fk_informacioncarreterascanton_canton FOREIGN KEY(Codigo_Canton) REFERENCES Canton
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


