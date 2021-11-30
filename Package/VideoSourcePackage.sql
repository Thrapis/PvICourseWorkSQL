CREATE OR REPLACE PACKAGE VideoSourcePackage IS
    -- Создание источника видео
	PROCEDURE CreateVideoSource(par_video_page_id in nvarchar2, par_data in blob, par_size in int, par_quality in int, par_format in nvarchar2, created out int);
    -- Получение информации об источнике по идентификатору страницы
    PROCEDURE GetByVideoPageIdAndQuality(par_video_page_id in nvarchar2, par_quality in int, source_cur out sys_refcursor);
END VideoSourcePackage;

CREATE OR REPLACE PACKAGE BODY VideoSourcePackage IS                -----Start of package body

    PROCEDURE CreateVideoSource(par_video_page_id in nvarchar2, par_data in blob, par_size in int, par_quality in int, par_format in nvarchar2, created out int) IS
    BEGIN
        INSERT INTO VideoSource(VideoPageId, Data, "Size", Quality, Format)
                VALUES (par_video_page_id, par_data, par_size, par_quality, par_format);
            created := sql%rowcount;
        COMMIT;
    END;

    PROCEDURE GetByVideoPageIdAndQuality(par_video_page_id in nvarchar2, par_quality in int, source_cur out sys_refcursor) IS
    BEGIN
        OPEN source_cur FOR SELECT * FROM VideoSource
            WHERE VideoPageId = par_video_page_id AND Quality = par_quality;
    END;

END VideoSourcePackage;