ALTER TRIGGER "trg_PagosF_Aju_Sald" after insert,delete,update order 1 on
DBA.F_PAGOS_F
referencing new as new_name
for each row
begin
  declare saldo decimal(19,2);
  declare saldo2 decimal(19,2);
  declare cliente char(15);
  declare total decimal(19,2);
  declare numero decimal(15);
  declare dollar tinyint;
  declare filial smallint;
  declare COMPANIA smallint;
  DECLARE TOTAL_VALES decimal(19,2);
  select USU_FILIAL,USU_COMPANIA into filial,compania from DBA.Usuarios where USU_CODIGO = current user;
  select FAM_COD_CLI into cliente from DBA.F_FACTURAS_M where FAM_NUM_FACT = new_name.PAF_NUM_FACT and fam_compania = compania;
  select FAM_DOLAR into dollar from DBA.F_FACTURAS_M where FAM_NUM_FACT = new_name.PAF_NUM_FACT and
    FAM_COMPANIA = COMPANIA;
  select sum(PAF_MTO_PAGO),sum(PAF_MTO_CARGO) into saldo,saldo2 from DBA.F_PAGOS_F where PAF_NUM_FACT = new_name.PAF_NUM_FACT and PAF_ESTADO < 3 and PAF_COMPANIA = COMPANIA;
  if(saldo2 is null) then
    set saldo2=0
  end if;
  if(saldo is null) then
    set saldo=0
  end if;
        
    if exists (select * from sys."SYSTABLE" where table_name in ('VALES_X_CLIENTE','Cobro_x_Vale')) then
        --total en vales
        SELECT  ifnull(sum(CXV_MONTO_VALE),0,sum(CXV_MONTO_VALE)) into TOTAL_VALES FROM DBA.Tipos_Vales TV JOIN DBA.VALES_X_CLIENTE VC ON TV.TVA_CODIGO = VC.VXC_TIPO_VALE JOIN DBA.Cobro_x_Vale CV ON VC.VXC_CODIGO_VALE = CV.CXV_CODIGO_VALE 
        WHERE CV.CXV_NUM_SALIDA = (select bms_num from dba."F_BOD_MAE_S" where bms_num_fact = new_name.PAF_NUM_FACT)  AND VC.VXC_CODIGO_CLIENTE = cliente;
    else
       set TOTAL_VALES =0;
    end if;

  update DBA.F_FACTURAS_M set FAM_MTO_OTROS = saldo2,FAM_MTO_SALDO = FAM_MTO_FACT+FAM_MTO_ISV+saldo2-saldo-TOTAL_VALES where FAM_NUM_FACT = new_name.PAF_NUM_FACT and fam_compania = compania;

  select sum(FAM_MTO_SALDO) into total from DBA.F_FACTURAS_M where FAM_COD_CLI = cliente and fam_compania = compania;
  if total is null then
    set total=0
  end if;


  --ACTUALIZA SALDO DEL PROVEEDOR
  if dollar = 1 then
    select sum(FAM_MTO_SALDO) into total from DBA.F_FACTURAS_M where FAM_COD_CLI = cliente and
      FAM_COMPANIA = COMPANIA and FAM_DOLAR = 1;
    if total is null then
      set total=0
    end if;
    --ACTUALIZAR EL SALDO DE LAS CUENTA EN DOLAR
    update DBA.F_CLIENTES set CLI_SALDO_DOLAR = total where CLI_COD = cliente and CLI_COMPANIA = COMPANIA
  else
    select sum(FAM_MTO_SALDO) into total from DBA.F_FACTURAS_M where FAM_COD_CLI = cliente and
      FAM_COMPANIA = COMPANIA and FAM_DOLAR <> 1; --MONEDA LOCAL
    if total is null then
      set total=0
    end if;
    update DBA.F_CLIENTES set CLI_SALDO = total where CLI_COD = cliente and CLI_COMPANIA = COMPANIA
  end if
end