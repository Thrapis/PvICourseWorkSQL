CREATE OR REPLACE PACKAGE VideoThumbnailPackage IS
    -- Создание превью видео
	PROCEDURE CreateVideoThumbnail(par_video_page_id in nvarchar2, par_data in blob, par_size in int, par_format in nvarchar2, created out int);

    PROCEDURE UpdateThumbnail(par_video_page_id in nvarchar2, par_data in blob, par_size in int, par_format in nvarchar2);
    -- Получение информации о превью по идентификатору страницы
    PROCEDURE GetByVideoPageId(par_video_page_id in nvarchar2, thumbnail_cur out sys_refcursor);
END VideoThumbnailPackage;

CREATE OR REPLACE PACKAGE BODY VideoThumbnailPackage IS                -----Start of package body

    PROCEDURE CreateVideoThumbnail(par_video_page_id in nvarchar2, par_data in blob, par_size in int, par_format in nvarchar2, created out int) IS
        busy_thumbnail int;
    BEGIN
        SELECT COUNT(*) INTO busy_thumbnail FROM VideoThumbnail WHERE VideoPageId = par_video_page_id;
        IF busy_thumbnail > 0 THEN
            DELETE FROM VideoThumbnail WHERE VideoPageId = par_video_page_id;
        END IF;
        INSERT INTO VideoThumbnail(VideoPageId, Data, "Size", Format)
                VALUES (par_video_page_id, par_data, par_size, par_format);
            created := sql%rowcount;
        COMMIT;
    END;

    PROCEDURE GetByVideoPageId(par_video_page_id in nvarchar2, thumbnail_cur out sys_refcursor) IS
    BEGIN
        OPEN thumbnail_cur FOR SELECT * FROM VideoThumbnail WHERE VideoPageId = par_video_page_id;
    END;

END VideoThumbnailPackage;