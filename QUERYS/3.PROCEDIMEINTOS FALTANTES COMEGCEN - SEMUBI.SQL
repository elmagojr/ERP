CREATE PROCEDURE "DBA"."Anulacion_Planilla_Empresarial"
(in vcompania varchar(5),
in vfilial varchar(5),
in vno_partida integer, 
in vFecha date,
in vPatrono INTEGER,
out vmnesaje varchar (100))


------------------XXXXXXXXXXXX------------------
--se debe de revisar que los días esten abietos
------------------XXXXXXXXXXXX------------------
begin
declare CODIGO_RESP      numeric(5) =0;
declare CODIGO_TRANSAC   numeric(5) =0;
declare DESCRIPCION_RESP varchar(100);

--ACTUALIZAR ESTADO DE SOCIOS PLANILLA
BEGIN
        UPDATE "DBA"."Socios_Planilla"
        SET SOC_NUM_PDA =0, SOC_STATUS =0
        where SOC_NUM_PDA = vno_partida
        AND SOC_PATRONO = vPatrono
        AND SOC_FECHA = vFecha
        AND SOC_COMPANIA= vcompania
        AND SOC_FILIAL=vfilial;
EXCEPTION WHEN OTHERS THEN
        SET CODIGO_RESP = -1;
        SET DESCRIPCION_RESP = 'Se presento un error al actualizar Socios Planlla..';
        SET CODIGO_TRANSAC = -1;
        ROLLBACK;
END;


--ACTUALIZAR TRANSACCIONES DE AHORRO
BEGIN
        update "DBA"."TRANS_AHORRO"
        set TRA_MTO_DEPOSITO =0
        where TRA_FECHA_TRANS = vFecha
        and TRA_COMPANIA =vcompania
        and TRA_FILIAL= vfilial
        and TRA_NO_DOCTO =vno_partida;
EXCEPTION WHEN OTHERS THEN
        SET CODIGO_RESP = -2;
        SET DESCRIPCION_RESP = 'Se presento un error al actualizar trans ahorro..';
        SET CODIGO_TRANSAC = -2;
        ROLLBACK;
END;

--ACTUALIZAR TRANSACCIONES DE CREDITO
BEGIN
        UPDATE "DBA"."TRANS_CREDITO"
        SET TRC_MTO_CAPITAL =0, TRC_MTO_INTERES =0, TRC_MTO_MORA =0, TRC_MTO_COBRADO=0, TRC_INTS_ORDEN =0, TRC_OTROS_CARGOS=0
        where TRC_FECHA_TRANS=vFecha
        and TRC_COMPANIA=vcompania
        and TRC_FILIAL=vfilial
        and TRC_NO_COMPROB=vno_partida;
EXCEPTION WHEN OTHERS THEN
        SET CODIGO_RESP = -3;
        SET DESCRIPCION_RESP = 'Se presento un error al actualizar trans credito..';
        SET CODIGO_TRANSAC = -3;
        ROLLBACK;
END;

--ACTUALIZAR TRANSACCIONES DE SEGURO 
BEGIN
        UPDATE "DBA"."TRANS_SEGURO"
        SET TRS_PAGOS =0
        WHERE TRS_FECHA_TRANS=vFecha
        AND TRS_COMPANIA=vcompania
        AND TRS_FILIAL=vfilial
        AND TRS_NO_COMPROB =vno_partida;
EXCEPTION WHEN OTHERS THEN
        SET CODIGO_RESP = -4;
        SET DESCRIPCION_RESP = 'Se presento un error al actualizar trans seguros..';
        SET CODIGO_TRANSAC = -4;
        ROLLBACK;
END;

--ACTUALIZAR F_FACTURAS_M
BEGIN
        UPDATE "DBA"."F_FACTURAS_M"
        SET FAM_MTO_FACT= 0, FAM_MTO_ISV=0, FAM_MTO_OTROS =0, FAM_MTO_SALDO =0
        WHERE FAM_FECHA=vFecha
        and FAM_COMPANIA=vcompania
        and FAM_FILIAL=vfilial
        and FAM_NO_PDA= vno_partida;
EXCEPTION WHEN OTHERS THEN
        SET CODIGO_RESP = -5;
        SET DESCRIPCION_RESP = 'Se presento un error al actualizar f_facturas_m..';
        SET CODIGO_TRANSAC = -5;
        ROLLBACK;
END;

--ACTUALIZAR F_PAGOS_F
BEGIN
        UPDATE "DBA"."F_PAGOS_F"
        SET PAF_MTO_PAGO =0, PAF_MTO_CARGO =0
        where PAF_FECHA = vFecha
        and PAF_COMPANIA=vcompania
        and PAF_FILIAL=vfilial
        and PAF_NO_PDA = vno_partida;
EXCEPTION WHEN OTHERS THEN
        SET CODIGO_RESP = -6;
        SET DESCRIPCION_RESP = 'Se presento un error al actualizar f_pagos_f..';
        SET CODIGO_TRANSAC = -6;
        ROLLBACK;
END;

--ACTUALIZAR Partida detalle
BEGIN
        UPDATE  "DBA"."F_PDA_DETALLE"
        SET PDD_MTO_DEBE =0, PDD_MTO_HABER =0
        where PDD_FECHA=vFecha
        and PDD_COMPANIA=vcompania
        and PDD_FILIAL=vfilial
        and PDD_NUM =vno_partida;
EXCEPTION WHEN OTHERS THEN
        SET CODIGO_RESP = -7;
        SET DESCRIPCION_RESP = 'Se presento un error al actualizar Partida detalle..';
        SET CODIGO_TRANSAC = -7;
        ROLLBACK;
END;

IF CODIGO_RESP =0 THEN
 SET DESCRIPCION_RESP = 'El proceso se realizo con exito';
 SET CODIGO_RESP = 1;
COMMIT ;
End if;


set vmnesaje = DESCRIPCION_RESP;
    
end;



CREATE FUNCTION "DBA"."f_pr_calcula_interes_gracia"(in pdi_fec_calculo date,in pvi_cuenta varchar(20),in pit_compania tinyint)
returns decimal (18,2)
begin
  declare filial tinyint;
  declare compania tinyint;
  declare estado tinyint;
  declare tgracia tinyint;
  declare tgracia_in tinyint;
  declare saldo decimal(19,2);
  declare fecha_ini date;
  declare tasa decimal(10,2);
  declare int_ant decimal(15,2);
  declare int_orden_ant decimal(15,2);
  declare int_gracia decimal(15,4);
  declare int_orden_hoy_gracia decimal(15,4);
  declare int_orden_hoy decimal(15,4);
  declare mto_pagado decimal(19,2);
  declare mto_pagar decimal(19,2);
  declare dias_atraso integer; 
  declare param_prov integer;
  declare existe_prov integer;
  declare c_capital_pagar decimal(15,2);
  declare c_fecha_pago date;
  declare p_dias_mora integer;
  declare int_pagar decimal (18,2);
  declare p_int_orden decimal (18,2);
  declare int_x_pagar decimal (18,2);
  declare fecha_inicial date;
  declare fecha_final date;
  declare fecha_inicial_c date;
  declare fecha_final_c date;
  declare fecha_gracia_in_1 date;
  declare fecha_gracia_in_2 date;
  declare fondo integer;
  declare bandera tinyint;
 
  declare Pr_plan_pago dynamic scroll cursor for select plp_fecha_pago,plp_capital_pagar from dba.Plan_de_Pago where plp_cuenta=pvi_cuenta and PLP_COMPANIA=pit_compania order by plp_fecha_pago asc;
 
  set int_gracia=0.0;
  set int_orden_hoy=0.00;
  set int_orden_hoy_gracia = 0.00;
  set c_capital_pagar=0;
  set dias_atraso     = 0;
  set int_orden_ant   = 0;

  select CRE_FILIAL,CRE_COMPANIA,CRE_ESTADO,CRE_TIEMPO_GRACIA,CRE_TIEMPO_GRACIA_IN,cre_fondo into Filial,Compania,estado,tgracia,tgracia_in,fondo from dba.creditos where CRE_CODIGO_CTA=pvi_cuenta and CRE_COMPANIA=pit_compania ;
  select top 1 rmc_fecha_i into fecha_ini from dba.reg_mensual_cre where (dateformat(rmc_fecha_i,'mm-yyyy')=dateformat(pdi_fec_calculo,'mm-yyyy')or rmc_fecha_i<=pdi_fec_calculo) and rmc_compania=Compania order by rmc_fecha_i desc ;
  select  sum(isnull(trc_prov_int_gracia,0)) into int_ant from DBA.TRANS_CREDITO where TRC_CODIGO_CTA = pvi_cuenta
  and trc_fecha_trans<=pdi_fec_calculo AND TRC_COMPANIA=pit_compania ;
  select  top 1 TI_TASA into tasa from DBA.F_CRED_INT_TASA where TI_CUENTA = pvi_cuenta AND TI_COMPANIA=pit_compania and ti_fecha_inicial in (select max (ti_fecha_inicial) from DBA.F_CRED_INT_TASA where TI_CUENTA = pvi_cuenta AND TI_COMPANIA=pit_compania) and ti_aplicada=1 order by ti_seq; 
  select isnull(sum(TRC_MTO_OTORGADO-TRC_MTO_CAPITAL),0) into saldo from DBA.TRANS_CREDITO where TRC_CODIGO_CTA = pvi_cuenta and TRC_COMPANIA=pit_compania AND TRC_FECHA_TRANS < fecha_ini;
    
  select PTT_C_PROVISION_INTERES into param_prov FROM DBA.F_Param_Tipos_Trans WHERE PTT_COMPANIA=pit_compania ;
  select count() into existe_prov from DBA.TRANS_CREDITO where TRC_CODIGO_CTA = pvi_cuenta and TRC_TIPO_TRANS=param_prov AND TRC_PROVISION>0 and TRC_COMPANIA=pit_compania and TRC_FECHA_TRANS between date(dateadd(dd,-(day(pdi_fec_calculo)-1),pdi_fec_calculo)) and pdi_fec_calculo;
  Select PAR_DIAS_INTS_CXC into p_dias_mora  from dba.PARAMETROS where PAR_FILIAL=Filial and PAR_COMPANIA=Compania;
  open Pr_plan_pago;
  fetch Pr_plan_pago into c_fecha_pago,c_capital_pagar;
  while mto_pagado>=c_capital_pagar and (@@sqlstatus <> 2) loop
  set mto_pagado=mto_pagado-c_capital_pagar; 
  fetch Pr_plan_pago into c_fecha_pago,c_capital_pagar;
  end loop;
  close Pr_plan_pago; 

  IF (existe_prov = 0 ) and estado not in (3,9) THEN 
    while fecha_ini <= pdi_fec_calculo and datepart(day,fecha_ini)<31  loop-- Mejora Josseleen A.
    if c_fecha_pago is null then
    set dias_atraso = 0;
    else 
    call dba.pr_calcula_dias(c_fecha_pago,fecha_ini,dias_atraso);
     if dias_atraso < 0 then
      set dias_atraso = 0
     end if; 
    end if;
      if dias_atraso>p_dias_mora then 
         If tgracia =1 then      
          for i as gracia_or dynamic scroll cursor for
                SELECT i.DGM_FECHA_INICIAL ,i.DGM_FECHA_FINAL  FROM DBA.F_Cred_Gracia_Mora as i WHERE i.DGM_TIPO_FONDO = fondo AND i.DGM_COMPANIA= pit_compania and i.DGM_FILIAL=filial and  i.DMG_FILI_O_COMP=0 and i.DMG_GRACIA_CAP=1 and i.DMG_GRACIA_INT=1 AND i.DMG_ESTADO=1 order by i.DGM_FECHA_INICIAL asc
          do
             set fecha_inicial = DGM_FECHA_INICIAL;
             set fecha_final = DGM_FECHA_FINAL;
           
            If fecha_ini>=fecha_inicial and fecha_ini<=fecha_final then
             set BANDERA = 1;
            Else
              set BANDERA = 0;
            end if;    
          end for;      
         for i as gracia_compania_or dynamic scroll cursor for
            SELECT i.DGM_FECHA_INICIAL ,i.DGM_FECHA_FINAL  FROM DBA.F_Cred_Gracia_Mora as i WHERE i.DGM_TIPO_FONDO = fondo AND i.DGM_COMPANIA= pit_compania and i.DMG_FILI_O_COMP=1 and i.DMG_GRACIA_CAP=1 and i.DMG_GRACIA_INT=1 AND i.DMG_ESTADO=1 order by i.DGM_FECHA_INICIAL asc
         do
           set fecha_inicial_c = DGM_FECHA_INICIAL;
           set fecha_final_c = DGM_FECHA_FINAL;
           
          If fecha_ini>=fecha_inicial_c and fecha_ini<=fecha_final_c then
            set BANDERA = 1;
          Else
            set BANDERA = 0;
         end if;
          
        end for;      
      end if;
      If tgracia_in =1 then
      for i as gracia_in_or dynamic scroll cursor for
        SELECT i.CGI_FECHA_INICIAL  ,i.CGI_FECHA_FINAL  from  DBA.F_Cred_Gracia_Individual as i where i.CGI_NO_CREDITO = pvi_cuenta and i.CGI_COMPANIA=pit_compania
        and i.CGI_GRACIA_CAP=1 and i.CGI_GRACIA_INT=1 AND i.CGI_ESTADO=1 order by i.CGI_FECHA_INICIAL asc
      
      do
      set fecha_gracia_in_1 = CGI_FECHA_INICIAL;
      set fecha_gracia_in_2 = CGI_FECHA_FINAL;
      
      If fecha_ini>=fecha_gracia_in_1 and fecha_ini<=fecha_gracia_in_2 then
           set BANDERA = 1
       Else
           set BANDERA = 0
      end if;
    end for;
    
       if BANDERA = 1 THEN
         set int_orden_hoy_gracia = int_orden_hoy_gracia+((saldo*tasa)/36000);
     
       ELSE
          set int_orden_hoy_gracia =0;
       END IF;
      else 
        
      If tgracia =1 then      
          for i as gracia dynamic scroll cursor for
                SELECT i.DGM_FECHA_INICIAL ,i.DGM_FECHA_FINAL  FROM DBA.F_Cred_Gracia_Mora as i WHERE i.DGM_TIPO_FONDO = fondo AND i.DGM_COMPANIA= pit_compania and i.DGM_FILIAL=filial and  i.DMG_FILI_O_COMP=0 and i.DMG_GRACIA_CAP=1 and i.DMG_GRACIA_INT=1 AND i.DMG_ESTADO=1 order by i.DGM_FECHA_INICIAL asc
          do
             set fecha_inicial = DGM_FECHA_INICIAL;
             set fecha_final = DGM_FECHA_FINAL;
           
            If fecha_ini>=fecha_inicial and fecha_ini<=fecha_final then
             set BANDERA = 1;
            Else
              set BANDERA = 0;
            end if;    
          end for;      
         for i as gracia_compania dynamic scroll cursor for
            SELECT i.DGM_FECHA_INICIAL ,i.DGM_FECHA_FINAL  FROM DBA.F_Cred_Gracia_Mora as i WHERE i.DGM_TIPO_FONDO = fondo AND i.DGM_COMPANIA= pit_compania and i.DMG_FILI_O_COMP=1 and i.DMG_GRACIA_CAP=1 and i.DMG_GRACIA_INT=1 AND i.DMG_ESTADO=1 order by i.DGM_FECHA_INICIAL asc
         do
           set fecha_inicial_c = DGM_FECHA_INICIAL;
           set fecha_final_c = DGM_FECHA_FINAL;
           
          If fecha_ini>=fecha_inicial_c and fecha_ini<=fecha_final_c then
            set BANDERA = 1;
          Else
            set BANDERA = 0;
         end if;
          
        end for;      
      end if;
      If tgracia_in =1 then
      for i as gracia_in dynamic scroll cursor for
        SELECT i.CGI_FECHA_INICIAL  ,i.CGI_FECHA_FINAL  from  DBA.F_Cred_Gracia_Individual as i where i.CGI_NO_CREDITO = pvi_cuenta and i.CGI_COMPANIA=pit_compania
        and i.CGI_GRACIA_CAP=1 and i.CGI_GRACIA_INT=1 AND i.CGI_ESTADO=1 order by i.CGI_FECHA_INICIAL asc
      
      do
      set fecha_gracia_in_1 = CGI_FECHA_INICIAL;
      set fecha_gracia_in_2 = CGI_FECHA_FINAL;
      
      If fecha_ini>=fecha_gracia_in_1 and fecha_ini<=fecha_gracia_in_2 then
           set BANDERA = 1
       Else
           set BANDERA = 0
      end if;
    end for;
    
    end if;
      If BANDERA=1 then
        set int_gracia=int_gracia+((saldo*tasa)/36000);
      else
         set int_gracia = 0;
       End If
     end if;
      end if;
        select isnull(sum(TRC_MTO_OTORGADO-TRC_MTO_CAPITAL),0) into saldo from DBA.TRANS_CREDITO where TRC_CODIGO_CTA = pvi_cuenta and TRC_COMPANIA=pit_compania and TRC_FECHA_TRANS <= fecha_ini;
      
        set fecha_ini=fecha_ini+1;
           if datepart(dd,fecha_ini)=31 then 
           set fecha_ini=fecha_ini+1;
        end if;
    end loop;
    set int_pagar=int_ant+int_gracia;
    set p_int_orden=int_orden_ant+int_orden_hoy_gracia;
  ELSE
    set int_pagar=int_ant;
    set p_int_orden=int_orden_ant;
  ENDIF;
set int_x_pagar=int_pagar+p_int_orden;
return int_x_pagar
end;



CREATE FUNCTION "DBA"."functionListaPaquetigos"( 
  in soapPayload xml ) 
returns xml
url
'http://172.16.50.68:8080/ServiciosCLARO/ServiciosCLARO' type
'HTTP:POST:text/xml' header
'Content-Type: text/xml;charset=UTF-8\x0ASOAPAction:"http://claro.unired.com/ServiciosCLARO/ListaPaquetigosRequest"\x0AHost: 172.16.50.68:8080';



CREATE PROCEDURE "DBA"."ListaPaquetigos"()

BEGIN
    DECLARE payload XML;
    DECLARE response XML;
    SET payload =
'<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:clar="http://claro.unired.com/">
   <soapenv:Header/>
   <soapenv:Body>
      <clar:ListaPaquetigos/>
   </soapenv:Body>
</soapenv:Envelope>';


    SET response = functionListaPaquetigos( payload );

SELECT *
FROM      OPENXML (response, '/*:Envelope/*:Body/*:ListaPaquetigosResponse/return')
    WITH ( codRet char(5) 'codRet', 
           Msg VARCHAR(200) 'msg', 
        PM_MENU   VARCHAR(50) 'pm_menu', 
        PM_OPCION INTEGER 'pm_opcion',
        PM_DESCRIPCION VARCHAR(150) 'pm_descripcion',
        PM_VIGENCIA   VARCHAR(20) 'pm_vigencia',
        PM_PRECIO    DECIMAL(12,2) 'pm_precio',
        PM_HIBRIDO CHAR(2) 'pm_hibrido',
        PM_PROVEEDOR TINYINT 'pm_proveedor',
        PM_SELECTOR INTEGER 'pm_selector' 
    )ORDER by PM_MENU ASC ;

    SELECT response;
END;

CREATE PROCEDURE "DBA"."Rep_cumplimiento"(in PFECHA1 Date,in PFECHA2 Date,in MONTO1 numeric(18,2), in MONTO2 numeric(18,2),in MONEDA integer)
/* RESULT( column_name column_type, ... ) */
BEGIN

    SET OPTION PUBLIC.request_timeout   = 11500;      
    SET OPTION PUBLIC.query_mem_timeout = 11500000;
    SET OPTION PUBLIC.remote_idle_timeout = 1155;
begin

delete dba.tmp_trans_multiples;

--for names as g sensitive cursor for
insert into dba.tmp_trans_multiples 
 SELECT a.coop_codigo                        --sum(monto) as "Valor_Movintos"
    FROM (  SELECT 'AHO' AS "Producto",
                   coop_codigo,
                   isnull (SUM (TRA_MTO_DEPOSITO), 0) AS "Monto"
              FROM dba.cooperativistas, dba.ahorros, dba.Trans_Ahorro
             WHERE     COOP_COMPANIA = 1
                   AND aho_compania = COOP_COMPANIA
                   AND aho_codigo_coo = coop_codigo
                   AND AHO_DOLARES = MONEDA
                   AND tra_compania = aho_compania
                   AND TRA_CODIGO_CTA = AHO_CODIGO_CTA
                   AND TRA_FECHA_TRANS >= PFECHA1
                   AND TRA_FECHA_TRANS <= PFECHA2
                   AND TRA_TIPO_PAGO IN (0, 6)
                   AND TRA_MTO_DEPOSITO > 0
                   AND TRA_MTO_DEPOSITO < MONTO1
          GROUP BY 'AHO', coop_codigo
          UNION ALL
          SELECT 'DPF' AS "Producto",
                 coop_codigo,
                 isnull (SUM (TRD_MTO_DEPOSITO), 0) AS "Monto"
            FROM dba.cooperativistas, dba.Depositos, dba.Transac_Deposit
           WHERE     COOP_COMPANIA = 1
                 AND Dpf_compania = COOP_COMPANIA
                 AND dpf_codigo_coop = coop_codigo
                 AND DPF_DOLARES = MONEDA
                 AND trd_compania = Dpf_compania
                 AND trd_CODIGO_CTA = Dpf_CODIGO_CTA
                 AND TRd_FECHA_TRAN >= PFECHA1
                 AND TRD_FECHA_TRAN <= PFECHA2
                 AND TRD_TIPO_PAGO IN (0, 6)
                 AND TRD_ESTADO <> 3
                 AND (TRD_MTO_DEPOSITO) > 0
                 AND (TRD_MTO_DEPOSITO) < MONTO1
                 GROUP BY 'DPF', coop_codigo
          UNION ALL
            SELECT 'CRED' AS "Producto",
                   coop_codigo,
                   isnull (
                      SUM (
                         (  TRC_MTO_CAPITAL
                          + TRC_MTO_INTERES
                          + TRC_MTO_MORA
                          + TRC_MTO_COBRADO)),
                      0)
                      AS "Monto"
              FROM dba.cooperativistas, dba.Creditos, dba.Trans_Credito
             WHERE     COOP_COMPANIA = 1
                   AND CRE_COMPANIA = COOP_COMPANIA
                   AND cre_codigo_coop = coop_codigo
                   AND CRE_MONEDA = MONEDA
                   AND TRC_COMPANIA = CRE_COMPANIA
                   AND TRC_CODIGO_CTA = CRE_CODIGO_CTA
                   AND TRC_FECHA_TRANS >= PFECHA1
                   AND TRC_FECHA_TRANS <= PFECHA2
                   AND TRC_TIPO_PAGO IN (0, 6)
                   AND TRC_ESTADO <> 3
                   AND (  TRC_MTO_CAPITAL
                        + TRC_MTO_INTERES
                        + TRC_MTO_MORA
                        + TRC_MTO_COBRADO) > 0
                   AND (  TRC_MTO_CAPITAL
                        + TRC_MTO_INTERES
                        + TRC_MTO_MORA
                        + TRC_MTO_COBRADO) < MONTO1
          GROUP BY 'CRED', coop_codigo) a
GROUP BY a.coop_codigo
  HAVING SUM (monto) >= MONTO2;
--do
-- insert into dba.tmp_trans_multiples (CODIGO)VALUES
                         --   (cod)
 
--end for;
end;

END;





CREATE PROCEDURE "DBA"."SP_Copy_Permisos" hidden '(($(())(()(&$$$$())(((())$()(()(b5!x$!@@5=b!$!5!@=*@0=5Sx$$!$@=($%%%$%)$%**$$%%%%%%%%$%%%%$%$%%$@5$=b=5@5b@xx*x@*$b@Wx@!@0!(5!0(()(**))(&***$&&&!$$$$%%%%%$%%%%%xb550(b!!x@%@*=*$5x(b@=b=@%=@!5S*$$!$$%%$)((()()$&*&&*****$$)()(%b=bW@!b!=@x$5!@0x5bWx5Wx@%m*@@!&&*&&&&&&$$!$$%%$)((()()$&&&&***b!=W%*=@0x5bWx5Wx@%m*@@0%m%xm=W%&&$()((((($$!(((((!$$$)((()(($&&*=@%($!#!5@%@*5!#%(*@@$!bmx5!@b=*&&*&&&&&$()((((($$!%)((()(($&*&($x@%($!#!5.*@@$!bmx5!@0!bWx=W=%()$&&&*&**&****$()((((($$!%()(($@$x$!.*@@$!bmx5!@@0=5!b!m$x$=@bS)((()()$&*&***$()((((($$!%)(((((xmm%($.*@@$!bmx5!@@0=Sb#@0x5bWx5&&*&***&*$$(((()$()(()($$!%$%%%$W!@@%.*@@b5!x$!@$x5m!@b$S@=@!5S%($$%%$)((($&&*&****&&**$$$$!$*&*b=bW*@@@@$@S!=!b!x5%=@bWx5Wx@%@(()($$%%%$)((($*&&&*&&**$$$$!$(()!mmm*@@@@$@S!=S!(!@bWx5Wx@@%@(!m)($$%%%$)((($&*&&*&&*&&**$$$$!$(mm*@@@@$@S!=0=5Sx$=@bWx5Wx@@%@(!(()($)(()(()$&*&&*&*&&**$$$$!$((mmm*@@@@$@S!=(!S!5=@$%(%%($@(!mm$(()($$%%$)((($&&&*&&*&&**$$$$!$m*@@@@$@S!=x#5!#=@bWx5Wx@%@(!mmm$!$(()($()(($*&&*&&&&&*&&**$$$$!*@@@@$@S!=0!bWx=x#5@$x$!@(!mmm*@!$(()($$%%$)((($&&&&&&&&*&&**$$$@@@$@S!=S=$%0%b=@bWx5Wx@%@(!mmm*$$!$(()($()(($&&&*&&&&&*&&**$$$$@@@@$@S!=0!bWx=S=$@$x$!@(!mmm*@@$!$(()($)((()(($&&&&&*&&**&&**$$@@$@S!=b!b!!(b%x@%($!#!5@(!mmm*@$$$!$(()($)((()(($&&&&&&*&&**$$$@@@$@S!=0%m%xm@%($!#!5@(!mmm*@@@$$$!$(()($)(()(()$&&&&*&&&*&&**$@$@S!=b=S@x(%x@$%(%%($@(!mmm*@@@!*&*&&*&***&*$$()(($))()(($$!%$$@%.*@@%(b!5$@%($=@b$S@=@!5S%b=b*&*&*$&&&$(()($$$$$$!$$)(((()$$$$@@@@b!m!b$@**@@@@@@05=S@$5x(@!5S***&&*$*&*&&*&*$()(()$$$$$$!*&*&%b=b*@@@@@@#W!5!@@!5S%b=b(@S!=!b&&&*$)(((()$$!%&*&&*****$%$&&*&*!x5%=@S@!b!=@x$5!.*@@b!m!b$@$=$x$!%*&&*&$(()($*&&*&&&&&$()(($$$*%W%@%($=@0!bWx=W=%@05=S@$!SS%.*@)$$$$!*&*&&*&***&*$$()(())$$!$$$@SS*@@!@$x$!@b$S@=@!5S%b=b*@@@@b$$$$!$&&&&****$%$&&*&****&&**$)(!$@$@S!=!b!x5%=@S@!b!=W%*=m*@@@@$$$$!$*&&*&&&&&$%$*&&*&&&&&*&&**$@S!=0!bWx=x#5@S@0!bWx=W=%m*@@@@!$$$$!%&&&&*&&&&&&$%$&&&&&&*&&**$@S!=0%m%xm@S@0%m%xm=W%*=.*@@SS*)$$$$!*&*&&*&*$&&&$(()($()(((($$@@$!m!$!@05=S@$5x(@!5S%b=b*@@@@#$$$!%&&&&****$%$&&*&****&&*$()((W!5!@@S!=!b!x5%=@S@!b!=W%*=.*@@S$$!*&*&&*&*$&&&$()(($))()(($$!$$SS*@@%(b!5$@%($=@$5x(@!5S%b=b*@@$!%*&*&&*&***&*$$(()($$$)(((()$$@@b!m!b$@*@05=S@b$S@=@!5S%b=b.*@&&*$)()$$$$!*&*&&*&*$&&&$()(())$@!@$x$!@$5x(@!5S%b=b*@@@@b!$@@S!$()(()$$$$!&&&&*&&&&&&$%$&&&&&&*=0%m%xm@S@0%m%xm=W%*=*@@@@#W!5!@)$$!$$$$!%&&&&****$%$&&*&****&&*@S!=!b!x5%=@S@!b!=W%*=.*@@SS*@@b()($&*&&&$()(($$$$!$$*&*&&$)((((!m!b$@b=!($W%*@@@@%($=@b=($x@05=**&&**$()(()$$$$!*&*&&*&***&*$$(S@b$S@=@!5S%b=b*@@@@#W!5!@$@S!=!&&&$(($$!$$$$!%&&&&****$%$&&*&**b!x5%=@S@!b!=W%*=.*@@SS*@@%0@b=(((()())(****$)()$$$$!((()$%$%$&*$x@S@@@$W!(*@@@@b!$@@0=5!b!m$x$=()(()(*$$%$&*&***$)()$$$$!%%$$%$@S@Sx.*@@@@b!$@@0=Sb#@S@#@!5S%b=**$)()$$$$!()(($$!$)(((()(&$&&$)b@(=@b=@%x$=b#*@@!mb!*@@@@b!$@@0%$&*&***$)()$$$$!%%$%$((()())(**=5!b!m$x$=@S@x.*@@@@b!$@@0=Sb#@S)()((()()()$)((()(((($)()(()(*$$@#@!5S%b=b@#!(!5x$=b@bx$%b0xb$=5)(((()$$!$$$$!%(($((($$!$()(((((%xS!($!#*@@!($@%0.*@@SS*@@b!m!b$(((!&*&***$&&&*&**&****$@@0=5!b!m$x$=m@0=Sb#*!($';
CREATE PROCEDURE "DBA"."Sp_crea_user" hidden '(($(())(()(&$$$$())(((())$()(()(b5!x$!@@5=b!$!5!@=*@0=5Sx$$!$@=($%%%$%)$%**$$%%%%%%%%$%%%%$%$%%$@x0=b=5@5b@x!*b!*5%@Wx@!@0!(5!0()())*(()(*)*$&&&!$$$$%%%%%$%%%%%xb550(b!!x@%@*=*$5x(b@=b5!x=!b!5*$(($$%%$)((()()$&&*&******$(($$W@%(@@0=!b!x5%=@0x5bWx5Wx@%m%(@@($$!(((((!$$$$%%$)((()()$&*&&&**0=bmx0!@0x5bWx5W5@%@%@*5!#%(*@@$((($$!%)((()(($())()(*)))$()((((!bmx5!@!b!=!W%b$!@%($!#!5.*@@$!b(($$!%)(((((()$&&&*&**&****$()((mx5!@@0=5!b!m$x$=@bSxmm%($.*@@$!$(($$!%$%%%$)((()()$&*&***$()(((bmx5!@@0=Sb#@0x5bWx5W!@@%.*@@%0@$)()$$$$!((()$(()($)($&&*&******@0=!b!x5%=@%b@(!mm@$W!(*@@@@b!$@)&***$)()$$$$!%%$$%$((()())(****@0=5!b!m$x$=@S@Sx.*@@@@b!$@@0=Sb())$(($(()()))$(($(((((($(&$$%$(#@S@#!m@b=$%#=@$!@!b!x5%=@(=@@!!($((($$!()))()$$$$!%$(()($)()$(($!@b!5@(!m=#.*@@@@5!$!5(*@@!($@%$$!((()$(()($)($&*&&&***$(($$!%(0.*@@%0@@0=bmx0!@%b@(!mm@$W!(*@@)()$$$$!%%$$%$((()())(****$)()$$@@b!$@@0=5!b!m$x$=@S@Sx.*@@@@b!$)((($(($)()()((($(((&$$%$()&***$@@0=Sb#@S@#$!5!@%(#5!bx5@mx@bmx0$((($$!()))()$$$$!%$(()())$((($(!@$!m@!bx5%=#.*@@@@5!$!5(*@@!($@($$$)()(($)(((()$$$$!((((($$!%((%0.*@@5!#%(*@@@@b!m!b$@b=!($W%@%(()$**&*****$(()($())()(*)))$()(($=@!b!=!W%b$!@05=S@b%b!b!5b@#W!((())(()($$!&&*&******$%$&&&&$()5!@(xS!@S@@0=!b!x5%=*@@!Wb!@$%=($)()$$$$$$!((()$))(()($((()$$$$!*@@@@#W!(@=$W!5b@$W!(*@@@@@@b!$@&****$(($$!%((($$!%$%$())()(*)))!b!=!W%b$!@S@@*@@!($.*@@%0@!b!=!($$$$$$!((((($$$$!((()$%$%$&**&*W%b$!@S@@@$W!(*@@@@5!#%(*@@@@@@!&*&&*&$$$$$$$$$!()((((((($())(()W!b!$!@%SS!$%x$!*@@@@@@@@#b5!x$!!&&*&******$))$$$$$$$$$!$$$*&**$@!b!5@5#*@@@@@@@@@mm@@0=!b!x5%=*!$$$*&$&&&&&*&&&&$$$$))$$$$$$$$$@@@@@@@@@mm@#5@%$!($%0%!$@5%@5#*))$$$$$$$$$!&*&&&***$))$$$$$$$$$@@@@@@@@@mm@@0=bmx0!*@@@@@@@@@mm$$$&%)*&%)**&&*$*&&&&*$&&&&&$$$$@#5@m=#%(@@=m%b%@5==$mW@$mW@x@@@$$$!%$%&&&$&&&&&&$&*&***&*$&&*&&0=5b!@@xbb#=5$@bWx(#!@=00.#.*@@@*$*&*$)(()())*$&&&$&*&&**$$$$$$$@@@SS@@!@$x$!@$5x(!b!x5%=b@b!$@!$&*&&$*&&***&$%$&***&**&&&&&****b!=0!(b%S=@xbb#$@S@b!55!($@$x$!@!%(()())**)*&$%$&&&&&&****$&*&&*#W!5!@!b!=b=$%#=@S@@@0=!b!x5%=.*$$$$!%%$%$((()())(****$)()$$$$$$@@@@@@b!$@@0=5!b!m$x$=@S@x.*@@@@($(((()($(()())*$$%$()&***$)()$$@@b!$@@0=Sb#@S@#!b!x5%=@b5!x$=@!$$$$$!((())(()($$$$!$()(((()()()W%$=bxS!($!#*@@@@!Wb!@$%=(*@@@@@**$)()$$$$$$$$!((()$))(()($((()$@#W!(@=$W!5b@$W!(*@@@@@@@@b!$@@0***$)()$$$$$$$$!%%$$%$((()())(**=5!b!m$x$=@S@Sx.*@@@@@@@@b!$@@0=()()))$)(()($(($)(((((()*$$%$()&Sb#@S@#@5=5m!Sxb@xm@b5!x5@!b!x5%())()$)()(()()$)(($(((()$(($($$(=m@=@(=@$%!(!@m=b@@!5S%b=b@5!x!!$(.(((($())($)()(((()$()()$)((()5%$=b@@x5x@5!xm%*x5@!b$x@xbb%b(()(()($$$$$$!((((($$$$!%((($$$$!$#*@@@@!($.*@@@@5!#%(*@@@@@@!W!b!&&&&$*&&*&$$$$$$$$$!()((((((($()$!@%SS!$%x$!*@@@@@@@@##5x($@S!S5$&*$$&*&&*&&&*&$$**&*&$&&$*&&**&!5bW%@@%(@#5=!@@5#=x$S=b=5!5@$=@$$!((())(()($$$$!&&*&******$))$$#@mm@@0=!b!x5%=*@@@@!Wb!@$%=(*@@)()$$$$$$$$!((()$))(()($((()$$$$@@@@#W!(@=$W!5b@$W!(*@@@@@@@@b!$*$)()$$$$$$$$!%%$%$((()())(****$@@0=5!b!m$x$=@S@x.*@@@@@@@@b!$@@$(((()($((()$(($(()())*$$%$()&**0=Sb#@S@#!b!x5%=@Wx@b%$=@b5!x$=m($$$$!$())()($(($(((((()($()))($@#5!@=@xb%#(x(=@(=@!W%b$!#*@@@@!%$((()())(****$)()$$$$!()(($$!((($*@@!mb!*@@@@b!$@@0=5!b!m$x$=@S)$(()())*$$%$()&***$)()$$$$!%%$$@Sx.*@@@@b!$@@0=Sb#@S@#!b!x5%=@%((())$$)()(($(($()(($(($())()($(x@!W%b$!@!(@5xb!@$!@$x$=bm@@5=b!(((()$$!%(($((($$!$$((((((((($()b=@bx(b!mx$=(#*@@!($@%0.*@@b!m!b(((!&*&***$&&&*&**&****$)$@@0=5!b!m$x$=m@0=Sb#*!($';
CREATE PROCEDURE "DBA"."Sp_Reseteo_Clave" hidden '*(()()(**)*$&&&$())(((())$()(()(b5!x$!@@5=b!$!5!@$5x(b@=5!b!$!==%%$)((()()$&&*&******&$(($$()((&bmx0!W@%(@@@0=!b!x5%=@0x5bWx5W!@*&$(($$%%$)((()()$&*&&&***&$(($$%m%(@@@0=bmx0!@0x5bWx5W5@%m%(@@@$!(((((!$$$$%%$)((()()$*&*******0=!b!=5!b@0x5bWx5W!@%@%@*5!#%(*@($$!%)((()(($())()(*)))$()((((($@$!bmx5!@!b!=!W%b$!@%($!#!5.*@@$(((($$!%)((()(($((()())()$()((((!bmx5!@5!b!m$x$=@%($!#!5.*@@$!bm$()((((($$!%$%%%$)((()()$()($()(x5!@Sb#@0x5bWx5Wx@@%.*@@$!bmx5!@((((($$!%)((()(($(((((()))()*)))!b!=5!b$5%(#%$=@%($!#!5.*@@$!bmx(((($$!%)((()(($((((((*((())($()5!@!b$x$==bxS5%=@%($!#!5.*@@5!#%()*)))$()(($$$)()(($)(((()$$$$!((*@@@@b!m!b$@b=!($W%@%($=@!b!=5!(()$***&*****$&&&$(()($(((((()))b$5%(#%$=@05=S@$5x(!b!=5!b$5@#W!)(()($$!&&*&******&$%$(()()))$()5!@!b!x5%=@S@@@0=!b!x5%=*@@!Wb!@$$$$$$!((()$))(()($((()$$$$!((()$%=(*@@@@#W!(@=$W!5b@$W!(*@@@@@@))$)()$$$$$$!%%$$%$((()())()$)()b!$@5!b!m$x$=@S@Sx.*@@@@@@b!$@!b)($)()$$$$$$!%%$$%$(((((()))()*)!=5!b$5%(#%$=@S@Sx.*@@@@@@b!$@Sb()))$)()())((($(($)(((((()*$$%$(#@S@#@5=5m!Sxb@xm@b=(b!m$x5@!b!x((((($()((())$$)(((((()))()$)(()5%=b@5!b$5%(#%$=bm@@5=b!b=@bx(b!($((()())()$)(((()$$$$$$!%$$((((mx$=(#.*@@@@@@b!m!b$@5!b!m$x$=mS%$(((((()))()*)))$(($$!%((($$!()b#*@@!($.*@@%0@!b!=5!b$5%(#%$=@S($)(((()$$$$$$!((((($$$$!((()$%$@@@$W!(*@@@@5!#%(*@@@@@@b!m!b$@b****$(()($())()(*)))$()(($$$)()(=!($W%@%($=@!b!=!W%b$!@05=S@b%b!$$!&&*&******&$%$&&&&$()(()$**&*b!5b@#W!5!@(xS!@S@@@0=!b!x5%=*@@()$))(()($((()$$$$$$!((())(()($$@@!Wb!@$%=(*@@@@@@#W!(@=$W!5b@$W$$!%$%$())()(*)))$)()$$$$$$$$!((!(*@@@@@@@@b!$@!b!=!W%b$!@S@@*@@(()$%$%$())()(*)))$(($$$$!%((($$@@!($.*@@@@%0@!b!=!W%b$!@(@@@$W!(($())(()($$$$$$$$!((((($$$$$$!((*@@@@@@5!#%(*@@@@@@@@!W!b!$!@%S)**)*&$))$$$$*&**$*&*&&$$()(((((S!$%x$!@#xm$!5@!b!5@5#@mm@@@0=!b$))$$$$*&$&&&&&*&&&&$$$$))$(()()!x5%=@mm@#5@%$!($%0%!$@5%@5#@mm@&&&&&$$$$))$$$$$$$$$$$!()((&*)*&@@0=bmx0!*@@@@@@@@@@@mm@#5@m=#%(*&*$&&*&&$$$&%)*&%)**&&*$*&&&&*$@@=m%b%@5==$mW@$mW@x@@@0=5b!@@xb(())$$$$$$$$!%$%&&&$&&&&&&$&*&**b#=5$@bWx(#!@=00.#.*@@@@@@@@!@$x**&&&&&*****$)()$)(()())*$&&&$()$!@$5x(!b!x5%=b@b!$@!b!=0!(b%S=@&****$()(()$()(($)(()))($%$&***&xbb#$@S@b!55!($@$x$!@#W!5!@!b!=b)()$$$$$$$$!%(()())**)*&$%$&&&&&=$%#=@S@@@0=!b!x5%=.*@@@@@@@@b!$$()($)()$$$$$$$$!%%$%$((()())()$@5!b!m$x$=@S@x.*@@@@@@@@b!$@Sb#@$$()(((()()()($(((((((($()((&$$%S@#bmx0!@bxS5%x$x@!W%$=bxS!($!(#)($((()$$$$$$$$!((())(()($$$$$$!*@@@@@@!Wb!@$%=(*@@@@@@@@#W!(@=$(()())()$)()$$$$$$$$$$!((()$))((W!5b@$W!(*@@@@@@@@@@b!$@5!b!m$x$()*$$%$()($)()$$$$$$$$$$!%%$$%$(=@S@Sx.*@@@@@@@@@@b!$@Sb#@S@#@5=)()))$(($()((($)(((((($(($)(((((5m!Sxb@xm@bxS5%x5@bmx0!@$!@!b!x5))()$)()(()()$)(($(((()$(($($$((%=m@=@(=@$%!(!@m=b@@!5S%b=b@5!x!(.(((($())($)()(((()$()()$)((()(!5%$=b@@x5x@5!xm%*x5@!b$x@xbb%b($)()$$$$$$!()(($$$$!((($$$$$$!$$(#*@@@@@@!($*@@@@!mb!*@@@@@@b!$@$%$()($)()$$$$$$!%%$$%$((()())()5!b!m$x$=@S@Sx.*@@@@@@b!$@Sb#@S@(($(($()(($(($())()($(($(()())*$#!b!x5%=@(=@!W%b$!@!(@5xb!@$!@$x((($$$$!$$((((((((($()((())$$)()$=bm@@5=b!b=@bx(b!mx$=(#*@@@@!($$$%$((()())()$)()$$$$!()(($$!(($@%0*@@!mb!*@@@@b!$@5!b!m$x$=@S@S()))()$(()())*$$%$()($)()$$$$!%%x.*@@@@b!$@Sb#@S@#!b!x5%=@5!b$5%((($$!$$((((((((($()((())$$((((((#%$=m@@5=b!b=@bx(b!mx$=(#*@@!($$$$!((()$%$%$((()())()$(($$!%(($@%0.*@@%0@5!b!m$x$=@S@x@$W!(*@@@$$!()(($$!%$%$((((((*((())($)()$@b!$@!b$x$==bxS5%=@S@x*@@!mb!*@@(($((($$!%$%$((((((*((())($)()$$@@b!$@!b$x$==bxS5%=@S@@*@@!($@%0((&*()((()(&$&&&$()(($))()(($$!%.*@@%(b!5$@%($=@$5x(5%$xb=5x=bxS(((&*((((&$&&&&&&****$$()((&*(((5%==bmx0!W@!b!=b=$%#=m0!bWx=bxS5((()())&*((((&$()()()&*(((((&$((%=mbxS5%==!W%$=b=mWx5%x=!W@%5x$=)((($(((((($)()())&*)(**((()((&$m0xm$x5x=@=5=!W@%5x5m0%m%xmmb=S@$&&*&******&$$$$$$!)()(()$$$((((x(%x@%@0xm!!b*@@@@W@@@0=!b!x5%=.))((()$)(()))($*&********&$$$$$$#@S@#.@@0=!b!=5!bmb!55!($@$%S!b$$$!%$$$%$%$%$%$((((((*((())($)((xS@m!b$x$==bxS5%=m@m@mxmx@%@.*@@$((()())()$)(((()$$!%()()$)(((((b=SS%$@#=5..*@@b!m!b$@5!b!m$x$=m(((!()(Sb#*!($';

