CREATE OR REPLACE PACKAGE AccountPackage IS
    -- Создание аккаунта
	PROCEDURE CreateAccount(par_email in nvarchar2, par_login in nvarchar2, par_password in nvarchar2, created out int);
    -- Получение информации об аккаунте, если емайл и пароль верны
    PROCEDURE SignIn(par_email in nvarchar2, par_password in nvarchar2, account_cur out sys_refcursor);
    -- Поменять пароль аккаунта
    PROCEDURE ChangeAccountPassword(par_email in nvarchar2, par_old_password in nvarchar2, par_new_password in nvarchar2, changed out int);
    -- Получение идентификатора по почте
    PROCEDURE GetIdByEmail(par_email in nvarchar2, ret_id out int);
    -- Получение логина по почте
    PROCEDURE GetLoginByEmail(par_email in nvarchar2, ret_login out nvarchar2);
    -- Получение логина по идентификатору
    PROCEDURE GetLoginById(par_id in int, ret_login out nvarchar2);
END AccountPackage;

CREATE OR REPLACE PACKAGE BODY AccountPackage IS                -----Start of package body

    PROCEDURE CreateAccount(par_email in nvarchar2, par_login in nvarchar2, par_password in nvarchar2, created out int) IS
        hash_pass nvarchar2(32);
        busy_email int;
    BEGIN
        SELECT COUNT(*) INTO busy_email FROM Account WHERE Email = par_email;
        IF busy_email = 0 THEN
            hash_pass := sys.DBMS_CRYPTO.hash(utl_i18n.string_to_raw(par_password, 'AL32UTF8'), 2);
            INSERT INTO Account(Email, Login, HashPassword, CreationDate)
                VALUES (par_email, par_login, hash_pass, SYSDATE);
            created := sql%rowcount;
            COMMIT;
        END IF;
    END;

    PROCEDURE SignIn(par_email in nvarchar2, par_password in nvarchar2, account_cur out sys_refcursor) IS
        hash_pass nvarchar2(32);
    BEGIN
        hash_pass := sys.dbms_crypto.hash(utl_i18n.string_to_raw(par_password, 'AL32UTF8'), 2);
        OPEN account_cur FOR SELECT Id, Email, Login, CreationDate
                FROM Account WHERE Email = par_email AND HashPassword = hash_pass;
    END;

    PROCEDURE ChangeAccountPassword(par_email in nvarchar2, par_old_password in nvarchar2, par_new_password in nvarchar2, changed out int) IS
        old_hash_pass nvarchar2(32);
        new_hash_pass nvarchar2(32);
    BEGIN
        old_hash_pass := sys.dbms_crypto.hash(utl_i18n.string_to_raw(par_old_password, 'AL32UTF8'), 2);
        new_hash_pass := sys.dbms_crypto.hash(utl_i18n.string_to_raw(par_new_password, 'AL32UTF8'), 2);
        UPDATE ACCOUNT SET HashPassword = new_hash_pass WHERE Email = par_email AND HashPassword = old_hash_pass;
        changed := sql%rowcount;
        COMMIT;
    END;

    PROCEDURE GetIdByEmail(par_email in nvarchar2, ret_id out int) IS
    BEGIN
        SELECT Id INTO ret_id FROM Account WHERE Email = par_email;
    END;

    PROCEDURE GetLoginByEmail(par_email in nvarchar2, ret_login out nvarchar2) IS
    BEGIN
        SELECT Login INTO ret_login FROM Account WHERE Email = par_email;
    END;

    PROCEDURE GetLoginById(par_id in int, ret_login out nvarchar2) IS
    BEGIN
        SELECT Login INTO ret_login FROM Account WHERE Id = par_id;
    END;

END AccountPackage;
