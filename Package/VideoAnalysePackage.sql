CREATE OR REPLACE PACKAGE VideoAnalysePackage IS

    PROCEDURE GetRateData(par_page_id in nvarchar2, rate_data_cur out sys_refcursor);

    PROCEDURE GetViewData(par_page_id in nvarchar2, view_data_cur out sys_refcursor);

END VideoAnalysePackage;

CREATE OR REPLACE PACKAGE BODY VideoAnalysePackage IS                -----Start of package body

    PROCEDURE GetRateData(par_page_id in nvarchar2, rate_data_cur out sys_refcursor) IS
        creation_date timestamp;
        difference_in_hours int;
        difference_in_days int;
    BEGIN
        SELECT CreationDate INTO creation_date FROM VideoPage WHERE Id = par_page_id;

        SELECT ROUND((cast(SYSDATE as date) - cast(creation_date as date)) * 24 + 1),
               ROUND(cast(SYSDATE as date) - cast(creation_date as date) + 1)
        INTO difference_in_hours, difference_in_days
        FROM VideoPage vp WHERE Id = par_page_id;

        IF (difference_in_days > 5 * 7) THEN
            ----------------------------------------------------------
            OPEN rate_data_cur FOR SELECT
                par_page_id "VideoPageId",
                h.week||' week of '||TO_CHAR(h.c_time,'IYYY')||' year' "Label",
                (SELECT COUNT(*)
                    FROM VideoPage vp INNER JOIN AuthVideoView avv ON vp.Id = avv.VideoPageId
                    WHERE vp.Id = par_page_id AND avv.Rate > 0 AND h.week = TO_CHAR(avv.RateDate,'IW')) "PositiveCount",
                (SELECT COUNT(*)
                    FROM VideoPage vp INNER JOIN AuthVideoView avv ON vp.Id = avv.VideoPageId
                    WHERE vp.Id = par_page_id AND avv.Rate < 0 AND h.week = TO_CHAR(avv.RateDate, 'IW')) "NegativeCount"
            FROM (select TO_CHAR(creation_date + (ROWNUM - 1) * 7,'IW') week,
                    creation_date + (ROWNUM - 1) * 7 c_time
                    FROM Dual
                    connect by LEVEL <= ROUND((cast(SYSDATE as date) - cast(creation_date as date)) / 7 + 1)) h;
            ----------------------------------------------------------
        ELSIF (difference_in_hours > 5 * 24) THEN
            ----------------------------------------------------------
            OPEN rate_data_cur FOR SELECT
                par_page_id "VideoPageId",
                TO_CHAR(TRUNC(h.c_time), 'MM.YYYY, DD')||' day' "Label",
                (SELECT COUNT(*)
                    FROM VideoPage vp INNER JOIN AuthVideoView avv ON vp.Id = avv.VideoPageId
                    WHERE vp.Id = par_page_id AND avv.Rate > 0 AND h.c_time = TRUNC(avv.RateDate,'DD')) "PositiveCount",
                (SELECT COUNT(*)
                    FROM VideoPage vp INNER JOIN AuthVideoView avv ON vp.Id = avv.VideoPageId
                    WHERE vp.Id = par_page_id AND avv.Rate < 0 AND h.c_time = TRUNC(avv.RateDate, 'DD')) "NegativeCount"
            FROM (select TRUNC(creation_date + (ROWNUM - 1),'DD') c_time FROM Dual
                    connect by LEVEL <= ROUND(cast(SYSDATE as date) - cast(creation_date as date) + 1)) h;
            ----------------------------------------------------------
        ELSE
            ----------------------------------------------------------
            OPEN rate_data_cur FOR SELECT
                par_page_id "VideoPageId",
                TO_CHAR(TRUNC(h.c_time,'HH'), 'DD.MM.YYYY, HH24')||' hour' "Label",
                (SELECT COUNT(*)
                    FROM VideoPage vp INNER JOIN AuthVideoView avv ON vp.Id = avv.VideoPageId
                    WHERE vp.Id = par_page_id AND avv.Rate > 0 AND h.c_time = TRUNC(avv.RateDate,'HH')) "PositiveCount",
                (SELECT COUNT(*)
                    FROM VideoPage vp INNER JOIN AuthVideoView avv ON vp.Id = avv.VideoPageId
                    WHERE vp.Id = par_page_id AND avv.Rate < 0 AND h.c_time = TRUNC(avv.RateDate,'HH')) "NegativeCount"
            FROM (select TRUNC(creation_date + (ROWNUM - 1)/24,'HH') c_time FROM Dual
                    connect by LEVEL <= ROUND((cast(SYSDATE as date) - cast(creation_date as date)) * 24 + 1)) h;
            ----------------------------------------------------------
        END IF;
    END;


    PROCEDURE GetViewData(par_page_id in nvarchar2, view_data_cur out sys_refcursor) IS
        creation_date timestamp;
        difference_in_hours int;
        difference_in_days int;
    BEGIN
        SELECT CreationDate INTO creation_date FROM VideoPage WHERE Id = par_page_id;

        SELECT ROUND((cast(SYSDATE as date) - cast(creation_date as date)) * 24 + 1),
               ROUND(cast(SYSDATE as date) - cast(creation_date as date) + 1)
        INTO difference_in_hours, difference_in_days
        FROM VideoPage vp WHERE Id = par_page_id;

        IF (difference_in_days > 5 * 7) THEN
            ----------------------------------------------------------
            OPEN view_data_cur FOR SELECT
                par_page_id "VideoPageId",
                h.week||' week of '||TO_CHAR(h.c_time,'IYYY')||' year' "Label",
                (SELECT COUNT(*)
                    FROM VideoPage vp INNER JOIN AuthVideoView avv ON vp.Id = avv.VideoPageId
                    WHERE vp.Id = par_page_id AND h.week = TO_CHAR(avv.ViewDate,'IW')) + (SELECT COUNT(*)
                    FROM VideoPage vp INNER JOIN NonAuthVideoView navv ON vp.Id = navv.VideoPageId
                    WHERE vp.Id = par_page_id AND h.week = TO_CHAR(navv.ViewDate,'IW')) "ViewCount"

            FROM (select TO_CHAR(creation_date + (ROWNUM - 1) * 7,'IW') week,
                    creation_date + (ROWNUM - 1) * 7 c_time
                    FROM Dual
                    connect by LEVEL <= ROUND((cast(SYSDATE as date) - cast(creation_date as date)) / 7 + 1)) h;
            ----------------------------------------------------------
        ELSIF (difference_in_hours > 5 * 24) THEN
            ----------------------------------------------------------
            OPEN view_data_cur FOR SELECT
                par_page_id "VideoPageId",
                TO_CHAR(TRUNC(h.c_time), 'MM.YYYY, DD')||' day' "Label",
                (SELECT COUNT(*)
                    FROM VideoPage vp INNER JOIN AuthVideoView avv ON vp.Id = avv.VideoPageId
                    WHERE vp.Id = par_page_id AND h.c_time = TRUNC(avv.ViewDate,'DD')) + (SELECT COUNT(*)
                    FROM VideoPage vp INNER JOIN NonAuthVideoView navv ON vp.Id = navv.VideoPageId
                    WHERE vp.Id = par_page_id AND h.c_time = TRUNC(navv.ViewDate,'DD')) "ViewCount"

            FROM (select TRUNC(creation_date + (ROWNUM - 1),'DD') c_time FROM Dual
                    connect by LEVEL <= ROUND(cast(SYSDATE as date) - cast(creation_date as date) + 1)) h;
            ----------------------------------------------------------
        ELSE
            ----------------------------------------------------------
            OPEN view_data_cur FOR SELECT
                par_page_id "VideoPageId",
                TO_CHAR(TRUNC(h.c_time,'HH'), 'DD.MM.YYYY, HH24')||' hour' "Label",
                (SELECT COUNT(*)
                    FROM VideoPage vp INNER JOIN AuthVideoView avv ON vp.Id = avv.VideoPageId
                    WHERE vp.Id = par_page_id AND h.c_time = TRUNC(avv.ViewDate,'HH')) + (SELECT COUNT(*)
                    FROM VideoPage vp INNER JOIN NonAuthVideoView navv ON vp.Id = navv.VideoPageId
                    WHERE vp.Id = par_page_id AND h.c_time = TRUNC(navv.ViewDate,'HH')) "ViewCount"

            FROM (select TRUNC(creation_date + (ROWNUM - 1)/24,'HH') c_time FROM Dual
                    connect by LEVEL <= ROUND((cast(SYSDATE as date) - cast(creation_date as date)) * 24 + 1)) h;
            ----------------------------------------------------------
        END IF;
    END;

END VideoAnalysePackage;










