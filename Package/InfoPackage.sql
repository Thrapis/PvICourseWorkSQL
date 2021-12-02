CREATE OR REPLACE PACKAGE InfoPackage IS

    PROCEDURE GetNFirstVideoPreview(par_count in int, video_preview_cur out sys_refcursor);

    PROCEDURE GetNFirstFeaturedVideoPreview(par_account_id in int, par_recommendations_count in int, featured_video_preview_cur out sys_refcursor);

    PROCEDURE SearchNFirstVideoPreviewLike(par_like_pattern in nvarchar2, par_count in int, video_preview_cur out sys_refcursor);

    PROCEDURE GetVideoPageInfo(par_page_id in nvarchar2, par_account_id in int, page_info_cur out sys_refcursor);

    PROCEDURE GetVideoEditInfo(par_account_id in int, page_info_cur out sys_refcursor);

    PROCEDURE GetCommentsOfVideoPage(par_page_id in nvarchar2, comment_cur out sys_refcursor);

    PROCEDURE GetCommentsOfVideoPageAfter(par_page_id in nvarchar2, par_after_comment_id in int, comment_cur out sys_refcursor);

    PROCEDURE GetLastViews(par_account_id in int, views_cur out sys_refcursor);

    PROCEDURE GetShortVideoList(par_account_id in int, videos_cur out sys_refcursor);

END InfoPackage;

CREATE OR REPLACE PACKAGE BODY InfoPackage IS                -----Start of package body

    PROCEDURE GetNFirstVideoPreview(par_count in int, video_preview_cur out sys_refcursor) IS
    BEGIN
        OPEN video_preview_cur FOR SELECT
            vp.Id "VideoPageId",
            vp.VideoName,
            a.Login "Author",
            (SELECT (SELECT COUNT(*) FROM AuthVideoView WHERE VideoPageId = vp.Id) +
                (SELECT COUNT(*) FROM NonAuthVideoView WHERE VideoPageId = vp.Id) FROM dual) "Views"
        FROM
            (SELECT * FROM VideoPage ORDER BY DBMS_RANDOM.RANDOM) vp INNER JOIN
            Account a ON vp.AccountId = a.Id WHERE ROWNUM <= par_count;
    END;

    PROCEDURE GetNFirstFeaturedVideoPreview(par_account_id in int, par_recommendations_count in int, featured_video_preview_cur out sys_refcursor) IS
    BEGIN
        OPEN featured_video_preview_cur FOR
        SELECT DISTINCT
            vp.Id "VideoPageId",
            vp.VideoName,
            (SELECT a.Login FROM Account a WHERE a.Id = vp.AccountId) "Author",
            (SELECT (SELECT COUNT(*) FROM AuthVideoView WHERE VideoPageId = vp.Id) +
                (SELECT COUNT(*) FROM NonAuthVideoView WHERE VideoPageId = vp.Id) FROM dual) "Views"
        FROM
            VideoPage vp INNER JOIN TagLink tl ON vp.Id = tl.VideoPageId
                INNER JOIN Tag t ON tl.Tagid = t.Id
        WHERE t.Id IN (SELECT consequent  AS recommendation FROM
            ( WITH rules AS ( SELECT AR.rule_id AS "ID",
                    ant_pred.attribute_subname antecedent, cons_pred.attribute_subname consequent,
                    AR.rule_support support, AR.rule_confidence confidence
                    FROM TABLE(dbms_data_mining.get_association_rules('ASSOCIATION_VIDEO_TAGS')) AR,
                    TABLE(AR.antecedent) ant_pred, TABLE(AR.consequent) cons_pred),
                cust_data AS (SELECT lfv.TagId prod_name FROM LastFiveViewed lfv WHERE AccountId = par_account_id)
              SELECT rules.consequent, MAX(rules.confidence) max_confidence, MAX(rules.support) max_support
              FROM rules, cust_data
              WHERE cust_data.prod_name = rules.antecedent
              AND rules.consequent NOT IN (SELECT prod_name FROM cust_data)
              GROUP BY rules.consequent
              ORDER BY max_confidence DESC, max_support DESC
            ) WHERE rownum <= 3 )
          AND ROWNUM <= par_recommendations_count;
    END;

    PROCEDURE SearchNFirstVideoPreviewLike(par_like_pattern in nvarchar2, par_count in int, video_preview_cur out sys_refcursor) IS
    BEGIN
        OPEN video_preview_cur FOR
        SELECT
            DISTINCT
            vp.Id "VideoPageId",
            vp.VideoName,
            (SELECT a.Login FROM Account a WHERE a.Id = vp.AccountId) "Author",
            (SELECT (SELECT COUNT(*) FROM AuthVideoView WHERE VideoPageId = vp.Id) +
                (SELECT COUNT(*) FROM NonAuthVideoView WHERE VideoPageId = vp.Id) FROM dual) "Views"
        FROM VideoPage vp INNER JOIN Account a ON vp.AccountId = a.Id
            INNER JOIN TagLink tl ON vp.Id = tl.VideoPageId
            INNER JOIN Tag t ON tl.TagId = t.Id
        WHERE (LOWER(vp.VideoName) LIKE '%'||LOWER(par_like_pattern)||'%'
            OR LOWER(a.Login) LIKE '%'||LOWER(par_like_pattern)||'%'
            OR LOWER('#'||t.Name) LIKE '%'||LOWER(par_like_pattern)||'%')
            AND ROWNUM <= par_count;
    END;

    PROCEDURE GetVideoPageInfo(par_page_id in nvarchar2, par_account_id in int, page_info_cur out sys_refcursor) IS
    BEGIN
         OPEN page_info_cur FOR SELECT
            vp.Id "VideoPageId",
            vp.VideoName,
            a.Login "Author",
            (SELECT (SELECT COUNT(*) FROM AuthVideoView avv WHERE avv.VideoPageId = vp.Id) +
                (SELECT COUNT(*) FROM NonAuthVideoView navv WHERE navv.VideoPageId = vp.Id) FROM dual) "Views",
            (SELECT Rate FROM AuthVideoView avv WHERE avv.VideoPageId = vp.Id AND avv.AccountId = par_account_id) "Rate",
            (SELECT COUNT(*) FROM AuthVideoView avv WHERE avv.VideoPageId = vp.Id AND Rate = 1) "PositiveRates",
            (SELECT COUNT(*) FROM AuthVideoView avv WHERE avv.VideoPageId = vp.Id AND Rate = -1) "NegativeRates",
            (SELECT MAX(Quality) FROM VideoSource vs WHERE vs.VideoPageId = vp.Id) "MaxQuality"
        FROM (SELECT * FROM VideoPage WHERE Id = par_page_id) vp
            INNER JOIN Account a ON vp.AccountId = a.Id ORDER BY vp.CreationDate;
    END;

    PROCEDURE GetVideoEditInfo(par_account_id in int, page_info_cur out sys_refcursor) IS
    BEGIN
        OPEN page_info_cur FOR SELECT
            vp.Id "VideoPageId",
            vp.VideoName,
            (SELECT (SELECT COUNT(*) FROM AuthVideoView avv WHERE avv.VideoPageId = vp.Id) +
                (SELECT COUNT(*) FROM NonAuthVideoView navv WHERE navv.VideoPageId = vp.Id) FROM dual) "Views",
            (SELECT COUNT(*) FROM AuthVideoView avv WHERE avv.VideoPageId = vp.Id AND Rate = 1) "PositiveRates",
            (SELECT COUNT(*) FROM AuthVideoView avv WHERE avv.VideoPageId = vp.Id AND Rate = -1) "NegativeRates",
            (SELECT MAX(Quality) FROM VideoSource vs WHERE vs.VideoPageId = vp.Id) "MaxQuality",
            vp.CreationDate "PageCreationDate"
        FROM (SELECT vpi.* FROM VideoPage vpi RIGHT JOIN VideoSource vsi ON vpi.Id = vsi.VideoPageId WHERE vsi.Quality = 1080) vp
            INNER JOIN (SELECT * FROM Account WHERE Id = par_account_id) a ON vp.AccountId = a.Id ORDER BY vp.CreationDate;
    END;

    PROCEDURE GetCommentsOfVideoPage(par_page_id in nvarchar2, comment_cur out sys_refcursor) IS
    BEGIN
        OPEN comment_cur FOR SELECT
            c.Id "CommentId",
            a.Id "AuthorId",
            a.Login "AuthorName",
            c.Text,
            c.CommentDate
        FROM "Comment" c INNER JOIN Account a ON c.AccountId = a.Id
        WHERE c.VideoPageId = par_page_id
        ORDER BY c.CommentDate DESC;
    END;

    PROCEDURE GetCommentsOfVideoPageAfter(par_page_id in nvarchar2, par_after_comment_id in int, comment_cur out sys_refcursor) IS
    BEGIN
        OPEN comment_cur FOR SELECT
            c.Id "CommentId",
            a.Id "AuthorId",
            a.Login "AuthorName",
            c.Text,
            c.CommentDate
        FROM "Comment" c INNER JOIN Account a ON c.AccountId = a.Id
        WHERE c.VideoPageId = par_page_id AND c.Id > par_after_comment_id
        ORDER BY c.CommentDate DESC;
    END;

    PROCEDURE GetLastViews(par_account_id in int, views_cur out sys_refcursor) IS
    BEGIN
        OPEN views_cur FOR SELECT
               avv.VideoPageId,
               v.VideoName
        FROM Account a INNER JOIN AuthVideoView avv ON a.Id = avv.AccountId
            INNER JOIN VideoPage v ON avv.VideoPageId = v.Id
        WHERE a.Id = par_account_id AND ROWNUM <= 10 ORDER BY avv.ViewDate DESC;
    END;

    PROCEDURE GetShortVideoList(par_account_id in int, videos_cur out sys_refcursor) IS
    BEGIN
        OPEN videos_cur FOR SELECT
               v.Id "VideoPageId",
               v.VideoName
        FROM Account a INNER JOIN VideoPage v ON a.Id = v.AccountId
        WHERE a.Id = par_account_id ORDER BY v.CreationDate;
    END;

END InfoPackage;