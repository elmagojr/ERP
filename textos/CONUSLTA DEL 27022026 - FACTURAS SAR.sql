select 
(SELECT CTF_DESCRIP  FROM DBA."F_CUENTAS_FIN" WHERE CTF_CODIGO = FAM_CTA_CONTA AND CTF_COMPANIA = 3 AND CTF_FILIAL = 1) AS CONTABLE,
BMS_NUM, * from dba.F_Facturas_M,dba.F_Bod_Mae_S where BMS_NUM_FACT = fam_num_fact and bms_fecha = fam_fecha AND F_Facturas_M.FAM_NUM_FACT_DEI=F_Facturas_M.FAM_NUM_FACT_DEI and BMS_COMPANIA = '3' 
and bms_filial = '1' and fam_fecha BETWEEN  '01/01/2026' and   '28/02/2026'  ORDER BY FAM_NUM_FACT desc

select 
TAR_CODIGO,
SUM(BDS_CANT*BDS_PRE_VTA) as compra,
sum(BDS_DESCUENTO) as descuento,
sum(bds_isv) as isv
from dba."F_BOD_DET_S"
join dba."F_ARTICULOS" on art_cod_prod =  bds_cod_prod
join dba."TIPO_ARTICULOS" on TAR_CODIGO = art_tipo
 where bds_num =300000019 
GROUP BY TAR_CODIGO
SELECT * FROM DBA."F_PDA_DETALLE" WHERE PDD_NUM =300000066

--F_Facturas_M,F_Bod_Mae_S,F_Clientes,#12D4,#13D4,#14D4,#10D4,F_Variables.STRING10,#24D4,#25D4,#26D4,#27D4,#28D4          [F_Bod_Mae_S.BMS_NUM]


select * from dba."F_ORDEN_COMPRA"
select * from "DBA".F_ORDEN_COMPRA  where F_ORDEN_COMPRA.OCM_NUM=(select max(F_ORDEN_COMPRA.OCM_NUM) from "DBA".F_ORDEN_COMPRA where F_ORDEN_COMPRA.OCM_COMPANIA='3' )  AND F_ORDEN_COMPRA.OCM_COMPANIA=3