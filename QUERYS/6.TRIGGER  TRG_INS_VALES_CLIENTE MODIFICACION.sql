ALTER TRIGGER "TRG_INS_VALES_CLIENTE" before insert order 1 on
DBA.VALES_X_CLIENTE
referencing new as new_name
for each row
when(current user <> 'DBA' and current user <> 'USR_SPS')
begin
  declare numero decimal(15);
  declare filial integer;
  declare compania smallint;
  select USU_FILIAL,USU_COMPANIA into filial,compania from DBA.Usuarios where USU_CODIGO = current user;
  set new_name.VXC_FILIAL=filial;
  set new_name.VXC_COMPANIA=compania;
  select func_llaves('VALES_X_CLIENTE.VXC_SEQ',filial) into numero from SYS.DUMMY;
  set new_name.VXC_SEQ=numero;
  set new_name.VXC_CODIGO_VALE=numero;
  set new_name.VXC_AGREGO=current user;
  set new_name.VXC_FECHA_AGR=current timestamp
end