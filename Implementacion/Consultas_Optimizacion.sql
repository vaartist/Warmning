use DW_user4;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

-- 2
-- Obtener la cantidad total de poblacion y cantidad de viviendas por canton, traida desde distritos

-- 2.a
Select	C.Nombre,
		C.Codigo,
		Sum(D.PoblacionHombres) as Hombres,
		Sum(D.PoblacionMujeres) as Mujeres,
		Sum(D.ViviendasOcupadas) as Ocupadas,
		Sum(D.ViviendasDesocupadas) as Desocupadas,
		Sum(D.ViviendasColectivas) as Colectivas
From Canton C join Distrito D on C.Codigo = D.CodigoCanton
Group by C.Nombre, C.Codigo


-- 2.b
Select	C.Nombre,
		C.Codigo,
		Sum(D.PoblacionHombres) as Hombres,
		Sum(D.PoblacionMujeres) as Mujeres,
		Sum(D.ViviendasOcupadas) as Ocupadas,
		Sum(D.ViviendasDesocupadas) as Desocupadas,
		Sum(D.ViviendasColectivas) as Colectivas
From Canton C join Distrito D on C.Codigo = D.CodigoCanton
Where C.Codigo in ( Select TOP(1) Co.Codigo From Canton Co Order by Co.Geom.STIntersection( D.Geom ).STArea() DESC )
Group by C.Nombre, C.Codigo


-- 2.c
Select	C.Nombre,
		C.Codigo,
		Sum(D.PoblacionHombres) as Hombres,
		Sum(D.PoblacionMujeres) as Mujeres,
		Sum(D.ViviendasOcupadas) as Ocupadas,
		Sum(D.ViviendasDesocupadas) as Desocupadas,
		Sum(D.ViviendasColectivas) as Colectivas
From Canton C join Distrito D on C.Geom.STIntersects( D.Geom ) = 1
Where C.Codigo in ( Select TOP(1) Co.Codigo From Canton Co Order by Co.Geom.STIntersection( D.Geom ).STArea() DESC )
Group by C.Nombre, C.Codigo



-- 3

-- Nested
Select	C.Nombre,
		C.Codigo,
		Sum(D.PoblacionHombres) as Hombres,
		Sum(D.PoblacionMujeres) as Mujeres,
		Sum(D.ViviendasOcupadas) as Ocupadas,
		Sum(D.ViviendasDesocupadas) as Desocupadas,
		Sum(D.ViviendasColectivas) as Colectivas
From Canton C inner loop join Distrito D on C.Codigo = D.CodigoCanton
Group by C.Nombre, C.Codigo


-- Merge
Select	C.Nombre,
		C.Codigo,
		Sum(D.PoblacionHombres) as Hombres,
		Sum(D.PoblacionMujeres) as Mujeres,
		Sum(D.ViviendasOcupadas) as Ocupadas,
		Sum(D.ViviendasDesocupadas) as Desocupadas,
		Sum(D.ViviendasColectivas) as Colectivas
From Canton C inner merge join Distrito D on C.Codigo = D.CodigoCanton
Group by C.Nombre, C.Codigo


-- Hash
Select	C.Nombre,
		C.Codigo,
		Sum(D.PoblacionHombres) as Hombres,
		Sum(D.PoblacionMujeres) as Mujeres,
		Sum(D.ViviendasOcupadas) as Ocupadas,
		Sum(D.ViviendasDesocupadas) as Desocupadas,
		Sum(D.ViviendasColectivas) as Colectivas
From Canton C inner hash join Distrito D on C.Codigo = D.CodigoCanton
Group by C.Nombre, C.Codigo



-- 4
-- In
Select Nombre, Codigo, Geom
From Distrito
Where CodigoCanton in ( 401, 402, 403, 404, 405, 406, 407, 408, 409 )


-- Or
Select Nombre, Codigo, Geom
From Distrito
Where CodigoCanton = 401 OR CodigoCanton = 401 OR CodigoCanton = 402 OR CodigoCanton = 403 OR CodigoCanton = 404 OR CodigoCanton = 405 OR CodigoCanton = 406 OR CodigoCanton = 407 OR CodigoCanton = 408 OR CodigoCanton = 409 