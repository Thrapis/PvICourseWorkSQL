CREATE OR REPLACE PACKAGE TagPackage IS

    TYPE TagArray is table of NVARCHAR2(64) index by BINARY_INTEGER;

    -- Создание
	PROCEDURE AttachTag(par_video_page_id in nvarchar2, par_tag_name in nvarchar2, created out int);

    PROCEDURE AttachTags(par_video_page_id in nvarchar2, par_tag_names in TagPackage.TagArray, created out int);
    -- Удаление
    PROCEDURE DetachTag(par_video_page_id in nvarchar2, par_tag_name in nvarchar2, deleted out int);

    PROCEDURE UpdateTags(par_video_page_id in nvarchar2, par_tag_names in TagPackage.TagArray);
    -- Получение
    PROCEDURE GetTagsByVideoPageId(par_video_page_id in nvarchar2, tags_cur out sys_refcursor);
END TagPackage;

CREATE OR REPLACE PACKAGE BODY TagPackage IS                -----Start of package body

    PROCEDURE AttachTag(par_video_page_id in nvarchar2, par_tag_name in nvarchar2, created out int) IS
        tag_exists int;
        tag_attached int;
        tag_id int;
    BEGIN
        SELECT COUNT(*) INTO tag_exists FROM TAG t WHERE Name = par_tag_name;
        IF tag_exists = 0 THEN
            INSERT INTO Tag(Name) VALUES (par_tag_name);
        END IF;

        SELECT COUNT(*) INTO tag_attached FROM TagLink tl
            INNER JOIN Tag t ON tl.TagId = t.Id
            WHERE VideoPageId = par_video_page_id AND t.Name = par_tag_name;

        SELECT t.Id INTO tag_id FROM Tag t WHERE t.Name = par_tag_name;

        IF tag_attached = 0 THEN
            INSERT INTO TagLink(VideoPageId, TagId)
                VALUES (par_video_page_id, tag_id);
            created := sql%rowcount;
            COMMIT;
        END IF;
    END;

    PROCEDURE AttachTags(par_video_page_id in nvarchar2, par_tag_names in TagPackage.TagArray, created out int) IS
        tag_exists int;
        tag_attached int;
        tag_id int;
    BEGIN
        FOR i IN par_tag_names.FIRST .. par_tag_names.LAST
        LOOP
            SELECT COUNT(*) INTO tag_exists FROM TAG t WHERE Name = par_tag_names(i);
            IF tag_exists = 0 THEN
                INSERT INTO Tag(Name) VALUES (par_tag_names(i));
            END IF;

            SELECT COUNT(*) INTO tag_attached FROM TagLink tl
                INNER JOIN Tag t ON tl.TagId = t.Id
                WHERE VideoPageId = par_video_page_id AND t.Name = par_tag_names(i);

            SELECT t.Id INTO tag_id FROM Tag t WHERE t.Name = par_tag_names(i);

            IF tag_attached = 0 THEN
                INSERT INTO TagLink(VideoPageId, TagId) VALUES (par_video_page_id, tag_id);
            END IF;
        END LOOP;
        created := sql%rowcount;
        COMMIT;
    END;

    PROCEDURE DetachTag(par_video_page_id in nvarchar2, par_tag_name in nvarchar2, deleted out int) IS
        tag_attached int;
        tag_id int;
    BEGIN
        SELECT COUNT(*) INTO tag_attached FROM TagLink tl
            INNER JOIN Tag t ON tl.TagId = t.Id
            WHERE VideoPageId = par_video_page_id AND t.Name = par_tag_name;

        SELECT t.Id INTO tag_id FROM Tag t WHERE t.Name = par_tag_name;

        IF tag_attached > 0 THEN
            DELETE TagLink WHERE VideoPageId = par_video_page_id AND TagId = tag_id;
            deleted := sql%rowcount;
            COMMIT;
        END IF;
    END;

    PROCEDURE UpdateTags(par_video_page_id in nvarchar2, par_tag_names in TagPackage.TagArray) IS
        tag_exists int;
        tag_attached int;
        tag_id int;
    BEGIN
        DELETE TagLink WHERE VideoPageId = par_video_page_id;
        FOR i IN par_tag_names.FIRST .. par_tag_names.LAST
        LOOP
            SELECT COUNT(*) INTO tag_exists FROM TAG t WHERE Name = par_tag_names(i);
            IF tag_exists = 0 THEN
                INSERT INTO Tag(Name) VALUES (par_tag_names(i));
            END IF;

            SELECT COUNT(*) INTO tag_attached FROM TagLink tl
                INNER JOIN Tag t ON tl.TagId = t.Id
                WHERE VideoPageId = par_video_page_id AND t.Name = par_tag_names(i);

            SELECT t.Id INTO tag_id FROM Tag t WHERE t.Name = par_tag_names(i);

            IF tag_attached = 0 THEN
                INSERT INTO TagLink(VideoPageId, TagId) VALUES (par_video_page_id, tag_id);
            END IF;
        END LOOP;
        COMMIT;
    END;

    PROCEDURE GetTagsByVideoPageId(par_video_page_id in nvarchar2, tags_cur out sys_refcursor) IS
    BEGIN
        OPEN tags_cur FOR SELECT tl.Id, tl.VideoPageId, t.Name FROM TagLink tl
        INNER JOIN Tag t ON tl.TagId = t.Id
        WHERE VideoPageId = par_video_page_id;
    END;

END TagPackage;