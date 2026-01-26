ALTER FUNCTION "DBA"."func_Llaves"
(
  IN var_campo   VARCHAR(100),
  IN var_filial  SMALLINT
)
RETURNS DECIMAL(15)
BEGIN
  DECLARE ultimo DECIMAL(15);
  DECLARE var_COMPANIA SMALLINT;

  SELECT USU_COMPANIA
    INTO var_COMPANIA
    FROM DBA.Usuarios
   WHERE USU_CODIGO = CURRENT USER;

  /* bloquear el uso por varios usuarios */
  SELECT CODIGO
    INTO ultimo
    FROM DBA.LLAVES
   WHERE CAMPO = var_campo
     AND FILIAL = var_filial
     AND COMPANIA = var_COMPANIA
   FOR UPDATE;

  IF ultimo IS NULL THEN
    SET ultimo = (var_COMPANIA * 10 + var_filial) * 10000000 + 1;

    INSERT INTO DBA.LLAVES (CAMPO, CODIGO, FILIAL, COMPANIA)
    VALUES (var_campo, ultimo, var_filial, var_COMPANIA);
  ELSE
    SET ultimo = ultimo + 1;

    UPDATE DBA.LLAVES
       SET CODIGO = ultimo
     WHERE CAMPO = var_campo
       AND FILIAL = var_filial
       AND COMPANIA = var_COMPANIA;
  END IF;

  RETURN ultimo;
END
