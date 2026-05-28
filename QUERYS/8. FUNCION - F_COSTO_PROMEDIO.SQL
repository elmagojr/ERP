CREATE FUNCTION "DBA"."f_costo_promedio"( in p_codigo varchar(50), in p_fecha date, in p_filial int, in p_cia  int/* [IN] parameter_name parameter_type [DEFAULT default_value], ... */ )
RETURNS DECIMAL(50,2)
DETERMINISTIC
BEGIN
	
	declare v_codigo varchar(20);
    declare v_fecha date;
    declare v_tipo varchar(20);
    declare v_cant decimal(19,2);
    declare v_unidades decimal(19,2);

    declare v_costo decimal(19,2);
    declare v_prom decimal(19,4);
    declare v_valor decimal(19,2);
    
  
    set v_codigo = 0;
    set v_cant = 0;
    set v_costo = 0;
    
    set v_prom = 0;
    set v_valor =0;
    set v_unidades =0;
    BEGIN
            DECLARE GG CURSOR FOR
        select codigo, fecha, tipo, cant, costo
        from (    
            SELECT BDE_COD_PROD AS codigo,
                   BDE_FECHA_agrego AS fecha,
                   'E' AS tipo,
                   BDE_CANT AS cant,
                   BDE_COSTO AS costo
            FROM dba.F_BOD_DET_E
            WHERE BDE_FECHA_agrego <= p_fecha and BDE_FILIAL = p_filial and BDE_COMPANIA = p_cia

            UNION ALL

            SELECT BDS_COD_PROD,
                   BDS_FECHA_agrego,
                   'S',
                   BDS_CANT,
                   0
            FROM dba.F_BOD_DET_S
            WHERE BDS_FECHA_agrego <= p_fecha and BDS_FILIAL = p_filial and BDS_COMPANIA = p_cia    
        ) dd
        WHERE codigo = p_codigo
        ORDER BY fecha;
        
        OPEN GG;
         lp: LOOP
           FETCH NEXT GG INTO v_codigo,v_fecha,v_tipo,v_cant,v_costo;
           IF SQLCODE <> 0 THEN LEAVE lp END IF;
           
            
                    IF v_tipo = 'E' THEN
                        set v_valor = v_valor + (v_cant * v_costo);--costo
                        set v_unidades = v_unidades + v_cant; --cantidades acumuladas
            
                    ELSEIF v_tipo = 'S' THEN
                        set v_valor = v_valor - (v_cant * v_prom);
                        set v_unidades = v_unidades - v_cant;
                    END IF;
            
                    IF v_unidades > 0 THEN
                        set v_prom = v_valor / v_unidades;
                    END IF; 
        END LOOP;
        CLOSE GG;
    END;
	RETURN v_prom;
END;
