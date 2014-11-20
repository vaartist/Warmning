use DW_user4;

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
From Canton C join Distrito D on C.Codigo in ( Select TOP(1) Co.Codigo From Canton Co Order by Co.Geom.STIntersection( D.Geom ).STArea() DESC )
Group by C.Nombre, C.Codigo
