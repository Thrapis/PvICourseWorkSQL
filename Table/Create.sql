CREATE SEQUENCE account_seq INCREMENT BY 1;

CREATE TABLE Account(
  Id int DEFAULT account_seq.NEXTVAL PRIMARY KEY,
  Email nvarchar2(256) NOT NULL UNIQUE,
  Login nvarchar2(64) NOT NULL,
  HashPassword nvarchar2(32) NOT NULL,
  CreationDate timestamp NOT NULL
);

-----------------------------------------------------

ALTER TABLE VideoPage MODIFY VideoName NVARCHAR2(128);

CREATE TABLE VideoPage(
  Id nvarchar2(32) PRIMARY KEY,
  AccountId int NOT NULL,
  VideoName nvarchar2(128) NOT NULL,
  CreationDate timestamp NOT NULL,
  FOREIGN KEY (AccountId) REFERENCES Account(Id) ON DELETE CASCADE
);

CREATE SEQUENCE video_thumbnail_seq INCREMENT BY 1;

CREATE TABLE VideoThumbnail(
  Id int DEFAULT video_thumbnail_seq.NEXTVAL PRIMARY KEY,
  VideoPageId nvarchar2(32) NOT NULL,
  Data blob NOT NULL,
  "Size" int NOT NULL,
  Format nvarchar2(5) NOT NULL,
  FOREIGN KEY (VideoPageId) REFERENCES VideoPage(Id) ON DELETE CASCADE
);

CREATE SEQUENCE video_source_seq INCREMENT BY 1;

CREATE TABLE VideoSource(
  Id int DEFAULT video_source_seq.NEXTVAL PRIMARY KEY,
  VideoPageId nvarchar2(32) NOT NULL,
  Data blob NOT NULL,
  "Size" int NOT NULL,
  Quality smallint NOT NULL,
  Format nvarchar2(5) NOT NULL,
  FOREIGN KEY (VideoPageId) REFERENCES VideoPage(Id) ON DELETE CASCADE
);
------------------------------------------------------

CREATE SEQUENCE tag_seq INCREMENT BY 1;

CREATE TABLE Tag(
  Id int DEFAULT tag_seq.NEXTVAL PRIMARY KEY,
  Name nvarchar2(22) NOT NULL
);

CREATE SEQUENCE tag_link_seq INCREMENT BY 1;

CREATE TABLE TagLink(
  Id int DEFAULT tag_link_seq.NEXTVAL PRIMARY KEY,
  VideoPageId nvarchar2(32) NOT NULL,
  TagId int NOT NULL,
  FOREIGN KEY (VideoPageId) REFERENCES VideoPage(Id) ON DELETE CASCADE,
  FOREIGN KEY (TagId) REFERENCES Tag(Id) ON DELETE CASCADE
);

----------------------------------------------------

CREATE SEQUENCE comment_seq INCREMENT BY 1;

CREATE TABLE "Comment"(
  Id int DEFAULT comment_seq.NEXTVAL PRIMARY KEY,
  VideoPageId nvarchar2(32) NOT NULL,
  /*ParentCommentId int NULL,*/
  AccountId int NOT NULL,
  Text nvarchar2(256) NOT NULL,
  CommentDate timestamp NOT NULL,
  FOREIGN KEY (VideoPageId) REFERENCES VideoPage(Id) ON DELETE CASCADE,
  /*FOREIGN KEY (ParentCommentId) REFERENCES "Comment"(Id) ON DELETE CASCADE,*/
  FOREIGN KEY (AccountId) REFERENCES Account(Id) ON DELETE CASCADE
);

CREATE SEQUENCE auth_video_view_seq INCREMENT BY 1;

CREATE TABLE AuthVideoView(
  Id int DEFAULT auth_video_view_seq.NEXTVAL PRIMARY KEY,
  VideoPageId nvarchar2(32) NOT NULL,
  AccountId int NOT NULL,
  ViewDate timestamp NOT NULL,
  Rate smallint DEFAULT 0,
  RateDate timestamp NULL,
  FOREIGN KEY (VideoPageId) REFERENCES VideoPage(Id) ON DELETE CASCADE,
  FOREIGN KEY (AccountId) REFERENCES Account(Id) ON DELETE CASCADE
);

CREATE SEQUENCE non_auth_video_view_seq INCREMENT BY 1;

CREATE TABLE NonAuthVideoView(
  Id int DEFAULT non_auth_video_view_seq.NEXTVAL PRIMARY KEY,
  VideoPageId nvarchar2(32) NOT NULL,
  IPAddress nvarchar2(15) NOT NULL,
  ViewDate timestamp NOT NULL,
  FOREIGN KEY (VideoPageId) REFERENCES VideoPage(Id) ON DELETE CASCADE
);


