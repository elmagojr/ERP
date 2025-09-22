SELECT * FROM "DBA"."F_BOD_DET_E" where "BDE_COD_PROD" = 016000430594 
SELECT * FROM "DBA"."F_BOD_DET_S" where "BDS_COD_PROD" = 016000430594

SELECT 
(SELECT SUM(BDE_CANT) FROM "DBA"."F_BOD_DET_E" where "BDE_COD_PROD" IN (120000599) AND BDE_COMPANIA =1 and bde_num = 0) AS ENTRADAS,
(SELECT SUM(BDS_CANT) FROM "DBA"."F_BOD_DET_S" where "BDS_COD_PROD" IN (120000599)) AS SALIDAS,
ENTRADAS-SALIDAS AS EXIST

SELECT USU_COMPANIA, USU_FILIAL from DBA.USUARIOS where USU_CODIGO = current user;


SELECT * FROM "DBA"."F_BOD_DET_E" where "BDE_COD_PROD" = 016000409828

select * from dba.f_Articulos where art_cod_prod in ( 016000430594,016000409828)
    
        select * from DBA.F_BOD_DET_S where bds_num = 20029568

where BDS_COD_PROD = 016000409828 and BDS_COMPANIA = 1;
       
        select sum(BDR_CANT)  from DBA.F_BOD_DET_R where BDR_COD_PROD = 016000409828 and BDR_COMPANIA = 1;
      
        select sum(BDE_CANT)  from DBA.F_BOD_DET_E where BDE_COD_PROD = 016000409828 and BDE_COMPANIA = 1;
        
        































begin
  declare salida decimal(19,3);
  declare requis decimal(19,3);
  declare entrada decimal(19,3);
  declare prom decimal(19,3);
  declare COMPANIA tinyint;
  declare EXISTENCIAS decimal(15,2);
  declare FILIAL tinyint;
  declare X decimal(12,3);
  declare Y decimal(5,2);
  declare V decimal(12,3);
  declare TIPO_PROD tinyint;  
  declare codigo_producto varchar(20);
  declare CANTIDAD_PROD int default 0;
  declare COSTO_PROD decimal(12,3) default 0;

  set CANTIDAD_PROD = 24;
  SET COSTO_PROD = 30.00;
  set codigo_producto = '016000430594';
  select USU_COMPANIA,USU_FILIAL into COMPANIA,FILIAL from DBA.USUARIOS where USU_CODIGO = current user;
  select ART_TIPO_ARTICULO into TIPO_PROD from DBA.F_ARTICULOS where ART_COD_PROD = codigo_producto;
    if TIPO_PROD = 0 then
        --Buscar las existencias y el costo promedio actual
        select ART_CTO_PROM,ART_EXIST,ART_UTILIDAD into prom,EXISTENCIAS,Y from DBA.F_ARTICULOS where ART_COD_PROD = codigo_producto and
        ART_COMPANIA = COMPANIA and ART_FILIAL = FILIAL;
        --Calculando nuevo costo promedio (X)
        if EXISTENCIAS is null then
            set EXISTENCIA=0
        end if;
        if prom is null then
            set prom=0
        end if;
        if Y is null then
            set Y=0
        end if;
        if(EXISTENCIAS-CANTIDAD_PROD) <> 0 then
            set X=((EXISTENCIAS*prom)+(CANTIDAD_PROD*COSTO_PROD))/(EXISTENCIAS+CANTIDAD_PROD)
        else
            set X=0
        end if;
        select sum(BDS_CANT) into salida from DBA.F_BOD_DET_S where BDS_COD_PROD = codigo_producto and BDS_COMPANIA = COMPANIA;
        if salida is null then
            set salida=0
        end if;
        select sum(BDR_CANT) into requis from DBA.F_BOD_DET_R where BDR_COD_PROD = codigo_producto and BDR_COMPANIA = COMPANIA;
        if requis is null then
            set requis=0
        end if;
        select sum(BDE_CANT) into entrada from DBA.F_BOD_DET_E where BDE_COD_PROD = codigo_producto and BDE_COMPANIA = COMPANIA;
        if entrada is null then
            set entrada=0
        end if;
        if Y > 0 then
            set V=COSTO_PROD*(1+(Y/100))
        else
            set V=COSTO_PROD
        end if;
        SELECT EXISTENCIAS-CANTIDAD_PROD, X AS COSOT_PROMEDIO, entrada-salida-requis AS EXIST, V AS COSTO, '', prom AS ART_CTO_PROM,EXISTENCIAS AS ART_EXIST,Y AS ART_UTILIDAD,salida,entrada, entrada-salida AS TOTO
    --   update DBA.F_ARTICULOS set ART_CTO_PROM = X,ART_EXIST = entrada-salida-requis,ART_PRE_VTA = V where
--            update DBA.F_ARTICULOS set ART_CTO_PROM = X,ART_EXIST = entrada-salida-requis where
--            ART_COD_PROD = codigo_producto and ART_COMPANIA = COMPANIA and ART_FILIAL = FILIAL
    end if;
end