/****** Object:   Used Shakila Movies Database  to find out customer interest based on their last wathed movies
and recomanndation for Top 5 MOVIES for a customer which they had not previously seen ******/

USE [sakila]
GO

/****** Object:  StoredProcedure [dbo].[getCustomerMovieRecommend]    Script Date: 3/28/2021 10:25:34 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
/****User Can Pass the Customer Name Parameter to find out individiual customer preference****/

Alter procedure [dbo].[getCustomerMovieRecommend]
    @Customer_name   varchar(255)  
as
   
set nocount on
declare @Customer_id  int ,
@active int


select @Customer_id=customer_id , @active=active from [customer] where CONCAT(first_name,' ',last_name)=@Customer_name


if (@Customer_id is null)
begin
select 'Invalid Customer Name'
end
ELSE BEGIN if (@active is null) begin
select 'Inactive Customer'
end
    ELSE BEGIN

/***** Find Out The Movies whcih already see by Customer *****/

CREATE TABLE #AlreadyWatchedList (
    id  int IDENTITY(1,1) PRIMARY KEY,
    FilmId varchar(255) NOT NULL,
    );
insert into #AlreadyWatchedList
select film_id from [dbo].[inventory] a join [dbo].[rental] b on a.inventory_id=b.inventory_id where customer_id=@Customer_id

/***Watch Count of the movies***/

declare @WatchedCnt  int
select @WatchedCnt=count(1) from #AlreadyWatchedList


/***** Find Out The Preferredlanguage from Movies whcih already seen by Customer *****/

CREATE TABLE #Preferredlanguage (
    id  int IDENTITY(1,1) PRIMARY KEY,
    language_id int NOT NULL,
NymberOutOf100 decimal(6,2)
    );
INSERT INTO #Preferredlanguage
select language_id , count(1)*100.00/@WatchedCnt from [dbo].film a join #AlreadyWatchedList b on a.film_id =b.FilmId
group by language_id

/***** Find Out The PreferredActor from Movies whcih already seen by Customer *****/

CREATE TABLE #PreferredActor (
    id  int IDENTITY(1,1) PRIMARY KEY,
    Actor_id  int NOT NULL,
NymberOutOf100 decimal(6,2)
    );
INSERT INTO #PreferredActor
select Actor_id , count(1)*100.00/@WatchedCnt from [dbo].film_actor a join #AlreadyWatchedList b on a.film_id =b.FilmId
group by Actor_id

/***** Find Out The PreferredCategory from Movies whcih already seen by Customer *****/

CREATE TABLE #PreferredCategory (
    id  int IDENTITY(1,1) PRIMARY KEY,
    Category_id  int NOT NULL,
NymberOutOf100 decimal(6,2)
    );
INSERT INTO #PreferredCategory
select category_id , count(1)*100.00/@WatchedCnt from [dbo].film_category a join #AlreadyWatchedList b on a.film_id =b.FilmId
group by category_id

/***** Find Out The Movies whcih customer did not see yet *****/

CREATE TABLE #UnWatchedList (
    id  int IDENTITY(1,1) PRIMARY KEY,
    FilmId varchar(255) NOT NULL,
Title  varchar(255) NOT NULL
    );
insert into #UnWatchedList
select film_id,Title from film where film_id not in (select filmid from #AlreadyWatchedList);




select a.film_id,c.NymberOutOf100 into #UnWatchedList_categoryScore from  [dbo].film_category a join #UnWatchedList b on a.film_id =b.FilmId  left join #PreferredCategory c  on a.category_id=c.Category_id

select a.film_id,c.NymberOutOf100 into #UnWatchedList_languageScore from  [dbo].film a join #UnWatchedList b on a.film_id =b.FilmId  left join #Preferredlanguage c  on a.language_id=c.language_id

select a.film_id,sum(c.NymberOutOf100) NymberOutOf100 into #UnWatchedList_ActorScore from  [dbo].film_actor a join #UnWatchedList b on a.film_id =b.FilmId  left join #PreferredActor c  on a.actor_id=c.actor_id
group by a.film_id


select top 5 Title,b.NymberOutOf100 categoryScore ,
 c.NymberOutOf100 languageScore,
 d.NymberOutOf100 ActorScore,
 b.NymberOutOf100+c.NymberOutOf100+d.NymberOutOf100 FinalScore  from  #UnWatchedList a join #UnWatchedList_categoryScore b on a.FilmId=b.film_id
                                join #UnWatchedList_languageScore c on a.FilmId=c.film_id
join #UnWatchedList_ActorScore d on a.FilmId=d.film_id
     order by b.NymberOutOf100+c.NymberOutOf100+d.NymberOutOf100 desc



    END
END
GO

/***User can pass any customer name to get the top 5 movies suggestion***/

Execute  [dbo].[getCustomerMovieRecommend] "MARY SMITH"
