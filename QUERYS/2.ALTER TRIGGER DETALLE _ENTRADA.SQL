ALTER TRIGGER "trg_aft_entr" after insert order 1 on
DBA.F_BOD_DET_E
referencing new as new_name
for each row
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
  select USU_COMPANIA,USU_FILIAL into COMPANIA,FILIAL from DBA.USUARIOS where USU_CODIGO = current user;
  select ART_TIPO_ARTICULO into TIPO_PROD from DBA.F_ARTICULOS where ART_COD_PROD = new_name.BDE_COD_PROD;
    if TIPO_PROD = 0 then
        --Buscar las existencias y el costo promedio actual
        select ART_CTO_PROM,ART_EXIST,ART_UTILIDAD into prom,EXISTENCIAS,Y from DBA.F_ARTICULOS where ART_COD_PROD = new_name.BDE_COD_PROD and
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
        if(EXISTENCIAS+new_name.BDE_CANT) > 0 then
            set X=((EXISTENCIAS*prom)+(new_name.BDE_CANT*new_name.BDE_COSTO))/(EXISTENCIAS+new_name.BDE_CANT)
        else
            set X=0
        end if;
        select sum(BDS_CANT) into salida from DBA.F_BOD_DET_S where BDS_COD_PROD = new_name.BDE_COD_PROD and BDS_COMPANIA = COMPANIA;
        if salida is null then
            set salida=0
        end if;
        select sum(BDR_CANT) into requis from DBA.F_BOD_DET_R where BDR_COD_PROD = new_name.BDE_COD_PROD and BDR_COMPANIA = COMPANIA;
        if requis is null then
            set requis=0
        end if;
        select sum(BDE_CANT) into entrada from DBA.F_BOD_DET_E where BDE_COD_PROD = new_name.BDE_COD_PROD and BDE_COMPANIA = COMPANIA;
        if entrada is null then
            set entrada=0      
        end if;                
        if Y > 0 then
            set V=new_name.BDE_COSTO*(1+(Y/100))
        else
            set V=new_name.BDE_COSTO
        end if;
    --   update DBA.F_ARTICULOS set ART_CTO_PROM = X,ART_EXIST = entrada-salida-requis,ART_PRE_VTA = V where
            update DBA.F_ARTICULOS set ART_CTO_PROM = X,ART_EXIST = entrada-salida-requis where
            ART_COD_PROD = new_name.BDE_COD_PROD and ART_COMPANIA = COMPANIA and ART_FILIAL = FILIAL
    end if;
end