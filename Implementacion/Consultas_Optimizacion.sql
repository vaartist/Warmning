use DW_user4;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SET SHOWPLAN_TEXT ON;
SET SHOWPLAN_TEXT OFF;
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
Select		C.Nombre, count(*)
From		Canton C join (Distrito D join Estacion_Bomberos EB on D.Codigo = EB.CodigoDistrito) on C.Codigo = D.CodigoCanton
Group by	C.Nombre
Having		count(*) in ( 1, 3, 5 )


-- Or
Select C.Nombre, count(*)
From Canton C join (Distrito D join Estacion_Bomberos EB on D.Codigo = EB.CodigoDistrito) on C.Codigo = D.CodigoCanton
Group by C.Nombre
Having count(*) = 1 OR count(*) = 3 OR count(*) = 5

