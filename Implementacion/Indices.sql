use DW_user4;

-- Minimum bounding box de todo Costa Rica
Declare @geom		geometry,
		@unionGeom	geometry
Declare cursor_tabla cursor for
	Select geom from Provincia
Open cursor_tabla
Fetch from cursor_tabla into @geom
SET @unionGeom = @GEOM
While( @@FETCH_STATUS = 0 )
BEGIN
	SET @unionGeom = @geom.STUnion( @unionGeom )
	Fetch next from cursor_tabla into @geom
END
Close cursor_tabla
Deallocate cursor_tabla
Select @unionGeom.STEnvelope().STAsText()
-- POLYGON ((283582.5 889283.75, 658921.875 889283.75, 658921.875 1241133.25, 283582.5 1241133.25, 283582.5 889283.75))
-- bounding_box = ( 283582.5, 889283.75, 658921.875, 1241133.25 )


CREATE SPATIAL INDEX IX_provincia_geom
	ON Provincia ( Geom ) WITH (bounding_box = ( 283582.5, 889283.75, 658921.875, 1241133.25 ));
CREATE SPATIAL INDEX IX_canton_geom
	ON Canton (Geom) WITH (bounding_box = ( 283582.5, 889283.75, 658921.875, 1241133.25 ));
CREATE SPATIAL INDEX IX_distrito_geom
	ON Distrito ( Geom ) WITH (bounding_box = ( 283582.5, 889283.75, 658921.875, 1241133.25 ));
CREATE SPATIAL INDEX IX_estacion_bomberos_geom
	ON Estacion_Bomberos (Geom) WITH (bounding_box = ( 283582.5, 889283.75, 658921.875, 1241133.25 ));
CREATE SPATIAL INDEX IX_zonas_riesgo_geom
	ON Zonas_Riesgo (Geom) WITH (bounding_box = ( 283582.5, 889283.75, 658921.875, 1241133.25 ));
CREATE SPATIAL INDEX IX_Camino_Geom
	ON Camino(Geom)
	WITH( BOUNDING_BOX = ( 283582.5, 889283.75, 658921.875, 1241133.25 ));
