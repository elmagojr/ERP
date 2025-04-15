select *, 
( 
SELECT 
CASE WHEN (SELECT COUNT(F_lotes.LOT_COD_BARRA) FROM DBA.F_lotes WHERE F_lotes.LOT_COD_PROD = F_Articulos.ART_COD_PROD AND F_lotes.LOT_COMPANIA = '1' AND F_lotes.LOT_FILIAL = '2') >1 THEN
(SELECT TOP 1 F_lotes.LOT_COD_BARRA FROM DBA.F_lotes WHERE F_lotes.LOT_COD_PROD = F_Articulos.ART_COD_PROD AND F_lotes.LOT_COMPANIA = '1' AND F_lotes.LOT_FILIAL = '2' ORDER BY LOT_SEQ DESC)
ELSE 
(SELECT F_lotes.LOT_COD_BARRA FROM DBA.F_lotes WHERE F_lotes.LOT_COD_PROD = F_Articulos.ART_COD_PROD AND F_lotes.LOT_COMPANIA = '1' AND F_lotes.LOT_FILIAL = '2')
END 


) AS COD
from "DBA".F_Articulos  where F_Articulos.ART_COMPANIA='1' and F_Articulos.ART_FILIAL='2' order by F_Articulos.ART_COD_PROD

SELECT * FROM DBA.F_lotes WHERE F_lotes.LOT_COD_PROD = '016000409828' AND F_lotes.LOT_COMPANIA = '1' AND F_lotes.LOT_FILIAL = '2'

SELECT * from "DBA".F_Articulos  where F_Articulos.ART_COMPANIA='1' and F_Articulos.ART_FILIAL='2' AND F_Articulos.ART_COD_PROD = 016000409828 order by F_Articulos.ART_COD_PROD


select 
--count(F_Articulos.ART_COD_PROD), F_Articulos.ART_COD_PROD
 F_lotes.LOT_COD_BARRA,* 
from "DBA".F_Articulos 
right join DBA.F_lotes  on F_lotes.LOT_COD_PROD = F_Articulos.ART_COD_PROD
 where F_Articulos.ART_COMPANIA='1' and F_Articulos.ART_FILIAL='2' 
--group by F_Articulos.ART_COD_PROD  
AND F_Articulos.ART_COD_PROD = 016000409828
order by F_Articulos.ART_COD_PROD