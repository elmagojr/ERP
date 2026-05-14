/*par crear el cmapo en la tabla cobros x vale*/
ALTER TABLE "DBA"."Cobro_x_Vale" ADD "CXV_CLI_COD" CHAR(20) NULL;
/*llenar el campo cobros por vales*/
update "DBA"."Cobro_x_Vale" SET CXV_CLI_COD = (select bms_cod_cli from dba.F_BOD_MAE_S where bms_num= CXV_NUM_SALIDA) --WHERE CXV_SEQ IN (120000002,120000003)
