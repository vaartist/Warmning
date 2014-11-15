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


Create Spatial index camino_geom_idx
	on camino(geom)
	with( bounding_box = ( 283582.5, 889283.75, 658921.875, 1241133.25 ) )