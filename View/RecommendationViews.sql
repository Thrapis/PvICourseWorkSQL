CREATE OR REPLACE VIEW ViewedBeforeToCurrent AS
SELECT preLastFiveTags.TagId FromTagId, lastOneTags.TagId ToTagId FROM
    (SELECT DISTINCT t1.TagId TagId, AccountId FROM
        TagLink t1 INNER JOIN (SELECT AccountId, min(VideoPageId) keep ( dense_rank first order by ViewDate desc) VideoPageId
            FROM AuthVideoView group by AccountId) lastOne
        ON lastOne.VideoPageId = t1.VideoPageId) lastOneTags
    FULL OUTER JOIN
    (SELECT DISTINCT t2.TagId TagId, AccountId FROM
        TagLink t2 INNER JOIN (SELECT AccountId, VideoPageId FROM
            (SELECT AccountId, VideoPageId, row_number() over (
                partition by AccountId
                order by ViewDate desc) rn
                FROM AuthVideoView) WHERE rn > 1 and rn < 7) preLastFive
        ON preLastFive.VideoPageId = t2.VideoPageId) preLastFiveTags
    ON lastOneTags.ACCOUNTID = preLastFiveTags.ACCOUNTID;

CREATE OR REPLACE VIEW LastFiveViewed AS
    SELECT DISTINCT t2.TagId, ACCOUNTID FROM
        TagLink t2 INNER JOIN (SELECT AccountId, VideoPageId FROM
            (SELECT AccountId, VideoPageId, row_number() over (
                partition by AccountId
                order by ViewDate desc) rn
                FROM AuthVideoView)
        WHERE  rn < 6) lastFive
    ON lastFive.VideoPageId = t2.VideoPageId ORDER BY ACCOUNTID;



SELECT A2.LOGIN,Tag.NAME FROM Tag INNER JOIN TAGLINK ON TAG.ID = TAGLINK.TAGID
    INNER JOIN AUTHVIDEOVIEW avv ON avv.VIDEOPAGEID = TAGLINK.VIDEOPAGEID
    INNER JOIN ACCOUNT A2 on avv.ACCOUNTID = A2.ID;


SELECT * FROM
 (
     WITH rules AS ( SELECT AR.rule_id AS "ID",
      ant_pred.attribute_subname antecedent,
      cons_pred.attribute_subname consequent,
      AR.rule_support support,
      AR.rule_confidence confidence
    FROM TABLE(dbms_data_mining.get_association_rules('ASSOCIATION_VIDEO_TAGS')) AR,
      TABLE(AR.antecedent) ant_pred,TABLE(AR.consequent) cons_pred),

    lastTags as (SELECT DISTINCT t2.TagId FROM
        TagLink t2 INNER JOIN (SELECT AccountId, VideoPageId FROM
            (SELECT AccountId, VideoPageId, row_number() over ( partition by AccountId order by ViewDate desc) rn
                FROM AuthVideoView WHERE AccountId = 1) WHERE  rn < 6) lastFive ON lastFive.VideoPageId = t2.VideoPageId)
     SELECT * from lastTags
);
