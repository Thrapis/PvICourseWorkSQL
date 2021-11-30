CREATE OR REPLACE PACKAGE VideoPagePackage IS
    -- Создание страницы видео
	PROCEDURE CreateVideoPage(par_id in nvarchar2, par_account_id in int, par_video_name in nvarchar2, created out int);

    PROCEDURE RemoveVideoPage(par_id in nvarchar2, removed out int);

    PROCEDURE InHisPossession(par_id in nvarchar2, par_account_id in int, possess out int);

    PROCEDURE UpdateName(par_id in nvarchar2, par_new_name in nvarchar2);
    -- Получение информации о странице по его идентификатору
    PROCEDURE GetById(par_id in nvarchar2, page_cur out sys_refcursor);
    -- Получение всех страниц по идентификатору аккаунта
    PROCEDURE GetAllByAccountId(par_account_id in int, pages_cur out sys_refcursor);
    -- Получение первых n страниц
    PROCEDURE GetNFirst(par_count in int, pages_cur out sys_refcursor);
    -- Получить количество просмотров видео
    PROCEDURE GetViewsCountOfVideoById(par_id in nvarchar2, ret_views out int);
    -- Добавить авторизированный просмотр на видео под идентификатором
    PROCEDURE AddAuthViewToVideoById(par_id in nvarchar2, par_account_id in int);
    -- Добавить не авторизированный просмотр на видео под идентификатором
    PROCEDURE AddNonAuthViewToVideoById(par_id in nvarchar2, par_ip_address in nvarchar2);
    -- Поставить оценку на видео под идентификатором
    PROCEDURE SetRateToVideoById(par_id in nvarchar2, par_account_id in int, par_rate in int);

    PROCEDURE AddComment(par_video_page_id in nvarchar2, par_account_id in int, par_text in nvarchar2, created out int);
END VideoPagePackage;

CREATE OR REPLACE PACKAGE BODY VideoPagePackage IS                -----Start of package body

    PROCEDURE CreateVideoPage(par_id in nvarchar2, par_account_id in int, par_video_name in nvarchar2, created out int) IS
        busy_page_name int;
    BEGIN
        SELECT COUNT(*) INTO busy_page_name FROM VideoPage WHERE Id = par_id;
        IF busy_page_name = 0 THEN
            INSERT INTO VideoPage(Id, AccountId, VideoName, CreationDate)
                VALUES (par_id, par_account_id, par_video_name, SYSDATE);
            created := sql%rowcount;
            COMMIT;
        END IF;
    END;

    PROCEDURE RemoveVideoPage(par_id in nvarchar2, removed out int) IS
    BEGIN
        DELETE VideoPage WHERE Id = par_id;
        removed := sql%rowcount;
        COMMIT;
    END;

    PROCEDURE InHisPossession(par_id in nvarchar2, par_account_id in int, possess out int) IS
        selected_video int;
    BEGIN
        SELECT COUNT(*) INTO selected_video FROM VideoPage WHERE Id = par_id AND AccountId = par_account_id;
        IF (selected_video > 0) THEN
            possess := 1;
        ELSE
            possess := 0;
        END IF;
    END;

    PROCEDURE UpdateName(par_id in nvarchar2, par_new_name in nvarchar2) IS
        busy_page_name int;
    BEGIN
        SELECT COUNT(*) INTO busy_page_name FROM VideoPage WHERE Id = par_id;
        IF busy_page_name > 0 THEN
            UPDATE VideoPage SET VideoName = par_new_name WHERE Id = par_id;
            COMMIT;
        END IF;
    END;

    PROCEDURE GetById(par_id in nvarchar2, page_cur out sys_refcursor) IS
    BEGIN
        OPEN page_cur FOR SELECT * FROM VideoPage WHERE Id = par_id;
    END;

    PROCEDURE GetAllByAccountId(par_account_id in int, pages_cur out sys_refcursor) IS
    BEGIN
        OPEN pages_cur FOR SELECT * FROM VideoPage WHERE AccountId = par_account_id;
    END;

    PROCEDURE GetNFirst(par_count in int, pages_cur out sys_refcursor) IS
    BEGIN
        OPEN pages_cur FOR SELECT * FROM VideoPage WHERE ROWNUM <= par_count;
    END;

    PROCEDURE GetViewsCountOfVideoById(par_id in nvarchar2, ret_views out int) IS
    BEGIN
        SELECT
            (SELECT COUNT(*) FROM AuthVideoView WHERE VideoPageId = par_id) +
            (SELECT COUNT(*) FROM NonAuthVideoView WHERE VideoPageId = par_id)
                INTO ret_views FROM dual;
    END;

    PROCEDURE AddAuthViewToVideoById(par_id in nvarchar2, par_account_id in int) IS
        been_viewed int;
    BEGIN
        SELECT COUNT(*) INTO been_viewed FROM AuthVideoView
            WHERE VideoPageId = par_id AND AccountId = par_account_id;
        IF been_viewed = 0 THEN
            INSERT INTO AuthVideoView(VideoPageId, AccountId, ViewDate)
                VALUES (par_id, par_account_id, SYSDATE);
        ELSE
            UPDATE AuthVideoView SET ViewDate = SYSDATE
                WHERE VideoPageId = par_id AND AccountId = par_account_id;
        END IF;
        COMMIT;
    END;

    PROCEDURE AddNonAuthViewToVideoById(par_id in nvarchar2, par_ip_address in nvarchar2) IS
        been_viewed_last_10_days int;
    BEGIN
        SELECT COUNT(*) INTO been_viewed_last_10_days FROM NonAuthVideoView navv
            WHERE VideoPageId = par_id AND IPAddress = par_ip_address AND
            (SELECT cast(SYSDATE as date) - cast(navv.ViewDate as date) FROM dual) <= 10;
        IF been_viewed_last_10_days = 0 THEN
            INSERT INTO NonAuthVideoView(VideoPageId, IPAddress, ViewDate)
                VALUES (par_id, par_ip_address, SYSDATE);
            COMMIT;
        END IF;
    END;

    PROCEDURE SetRateToVideoById(par_id in nvarchar2, par_account_id in int, par_rate in int) IS
        been_viewed int;
        current_rate int;
    BEGIN
        SELECT COUNT(*) INTO been_viewed FROM AuthVideoView
            WHERE VideoPageId = par_id AND AccountId = par_account_id;
        IF been_viewed = 1 THEN
            SELECT Rate INTO current_rate FROM AuthVideoView
                WHERE VideoPageId = par_id AND AccountId = par_account_id;
            IF current_rate = par_rate THEN
                UPDATE AuthVideoView SET Rate = 0, RateDate = NULL
                    WHERE VideoPAgeId = par_id AND AccountId = par_account_id;
            ELSE
                UPDATE AuthVideoView SET Rate = par_rate, RateDate = SYSDATE
                    WHERE VideoPAgeId = par_id AND AccountId = par_account_id;
            END IF;
            COMMIT;
        END IF;
    END;

    PROCEDURE AddComment(par_video_page_id in nvarchar2, par_account_id in int, par_text in nvarchar2, created out int) IS
    BEGIN
        INSERT INTO "Comment" (VideoPageId, AccountId, Text, CommentDate)
            VALUES (par_video_page_id, par_account_id, par_text, SYSDATE);
        created := sql%rowcount;
        COMMIT;
    END;

END VideoPagePackage;