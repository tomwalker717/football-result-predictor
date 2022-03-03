USE DATABASE CUSTOMER_ANALYTICS;
USE SCHEMA SANDBOX;

--create or replace table customer_analytics.sandbox.TW_Innovation_Day_2122(date string, HomeTeam string, AwayTeam string, FTHG int, FTAG int, FTR string, HTHG int, HTAG int, HTR string, Referee string, 
                                              --HomeShots int, AwayShots int, HST int, AST int, HF int, AF int, HC int, AC int, HY int, AY int, HR int , AR int);
                                              
select * from TW_innovation_day_1819;

select * from TW_innovation_day_1819 where hometeam='Man United' or awayteam='Man United';

select to_date(date,'DD/MM/YYYY') from TW_innovation_day_1819;

create or replace temp table season_2122 as
select to_date(date,'DD/MM/YYYY') as date,
HomeTeam , AwayTeam, FTHG , FTAG , FTR , HTHG , HTAG , HTR , Referee , 
                                              HomeShots , AwayShots , HST , AST , HF , AF , HC , AC , HY , AY , HR  , AR
from TW_innovation_day_2122;

create or replace temp table season_1819 as
select to_date(date,'DD/MM/YYYY') as date,
HomeTeam , AwayTeam, FTHG , FTAG , FTR , HTHG , HTAG , HTR , Referee , 
                                              HomeShots , AwayShots , HST , AST , HF , AF , HC , AC , HY , AY , HR  , AR
from TW_innovation_day_1819;

create or replace temp table season_1718 as
select to_date(date,'DD/MM/YYYY') as date,
HomeTeam , AwayTeam, FTHG , FTAG , FTR , HTHG , HTAG , HTR , Referee , 
                                              HomeShots , AwayShots , HST , AST , HF , AF , HC , AC , HY , AY , HR  , AR
from TW_innovation_day_1718;

create or replace temp table season_1617 as
select to_date(date,'DD/MM/YYYY') as date,
HomeTeam , AwayTeam, FTHG , FTAG , FTR , HTHG , HTAG , HTR , Referee , 
                                              HomeShots , AwayShots , HST , AST , HF , AF , HC , AC , HY , AY , HR  , AR
from TW_innovation_day_1617;

create or replace temp table season_1516 as
select to_date(date,'DD/MM/YYYY') as date,
HomeTeam , AwayTeam, FTHG , FTAG , FTR , HTHG , HTAG , HTR , Referee , 
                                              HomeShots , AwayShots , HST , AST , HF , AF , HC , AC , HY , AY , HR  , AR
from TW_innovation_day_1516;

create or replace temp table season_1415 as
select to_date(date,'DD/MM/YYYY') as date,
HomeTeam , AwayTeam, FTHG , FTAG , FTR , HTHG , HTAG , HTR , Referee , 
                                              HomeShots , AwayShots , HST , AST , HF , AF , HC , AC , HY , AY , HR  , AR
from TW_innovation_day_1415;


create or replace temp table summary_table as
select *,
row_number() over (order by date) as match_id 
from (
select *, '21-22' as season
from season_2122
union all
select *, '18-19' as season
from season_1819
union all
select *, '17-18' as season
from season_1718
union all
select *, '16-17' as season
from season_1617
union all
select *, '15-16' as season
from season_1516
union all
select *, '14-15' as season
from season_1415);


--All the home team results
create or replace temp table home_teams as
select date, 
hometeam as team, 
fthg as ftg,
ftag as ftga,
case when ftr='H' then 1 else 0 end as ftw,
case when ftr='D' then 1 else 0 end as ftd,
hthg as htg,
htag as htga,
case when htr='H' then 1 else 0 end as htw,
case when htr='D' then 1 else 0 end as htd,
referee,
homeshots as shots,
awayshots as shotsA,
hst as st,
ast as sta,
hf as f,
af as fa,
hc as c,
ac as ca,
hy as y,
ay as ya,
hr as r,
ar as ra,
1 as home_team,
match_id,
season
from summary_table;

select * from summary_table where hometeam='Southampton';

--All the away team results
create or replace temp table away_teams as
select date, 
awayteam as team, 
ftag as ftg,
fthg as ftga,
case when ftr='A' then 1 else 0 end as ftw,
case when ftr='D' then 1 else 0 end as ftd,
htag as htg,
hthg as htga,
case when htr='A' then 1 else 0 end as htw,
case when htr='D' then 1 else 0 end as htd,
referee,
awayshots as shots,
homeshots as shotsA,
ast as st,
hst as sta,
af as f,
hf as fa,
ac as c,
hc as ca,
ay as y,
hy as ya,
ar as r,
hr as ra,
0 as home_team,
match_id,
season
from summary_table;

create or replace temp table all_matches as
select * from home_teams 
union all
select * from away_teams;

create or replace temp table all_matches2 as
select *, 
row_number() over (partition by team, season order by date) as match_number
from all_matches;

--Tracking the league table over the season
create or replace temp table points_by_game as
select date,
season,
team,
match_id,
match_number,
case when ftw=1 then 3
when ftd=1 then 1 else 0 end as points_earned,
sum(points_earned) over (partition by team, season order by date) as total_points,
sum(ftg-ftga) over (partition by team, season order by date) as GD
from all_matches2;

create or replace temp table position_by_game as
select a.*,
count(distinct b.team) as position
from points_by_game a 
left join points_by_game b 
on a.season=b.season
and b.total_points>=a.total_points
and b.gd>=a.gd
and b.date<=a.date
group by 1,2,3,4,5,6,7,8
order by 3,1;


--Summarise the recent results for each team
create or replace temp table team_form_by_match as
select a.season,
a.match_id,
a.match_number, 
a.team, 
ftg, 
ftga, 
home_team,
referee,
position,
sum(ftg) over (partition by a.team, a.season order by a.match_number rows between 5 preceding and 1 preceding) as prev_ftg,
sum(ftga) over (partition by a.team, a.season order by a.match_number rows between 5 preceding and 1 preceding) as prev_ftga,
sum(htg) over (partition by a.team, a.season order by a.match_number rows between 5 preceding and 1 preceding) as prev_htg,
sum(htga) over (partition by a.team, a.season order by a.match_number rows between 5 preceding and 1 preceding) as prev_htga,
sum(shots) over (partition by a.team, a.season order by a.match_number rows between 5 preceding and 1 preceding) as prev_shots,
sum(shotsa) over (partition by a.team, a.season order by a.match_number rows between 5 preceding and 1 preceding) as prev_shotsa,
sum(st) over (partition by a.team, a.season order by a.match_number rows between 5 preceding and 1 preceding) as prev_st,
sum(sta) over (partition by a.team, a.season order by a.match_number rows between 5 preceding and 1 preceding) as prev_sta,
sum(c) over (partition by a.team, a.season order by a.match_number rows between 5 preceding and 1 preceding) as prev_c,
sum(ca) over (partition by a.team, a.season order by a.match_number rows between 5 preceding and 1 preceding) as prev_ca
from all_matches2 a 
inner join position_by_game b 
on a.match_id=b.match_id
and a.team=b.team
order by 2,1;



--Only use matches after match 6
create or replace temp table home_summarised_results as
select match_id,
team as home_team,
ftg as HG,
ftga as AG,
referee,
position as position_h,
prev_ftg as prev_ftg_h,
prev_ftga as prev_ftga_h,
prev_htg as prev_htg_h,
prev_htga as prev_htga_h,
prev_shots as prev_shots_h,
prev_shotsa as prev_shotsa_h,
prev_st as prev_st_h,
prev_sta as prev_sta_h,
prev_c as prev_c_h,
prev_ca as prev_ca_h
from team_form_by_match
where home_team=1
and match_number>=6;

create or replace temp table away_summarised_results as
select match_id,
team as away_team,
position as position_a,
prev_ftg as prev_ftg_a,
prev_ftga as prev_ftga_a,
prev_htg as prev_htg_a,
prev_htga as prev_htga_a,
prev_shots as prev_shots_a,
prev_shotsa as prev_shotsa_a,
prev_st as prev_st_a,
prev_sta as prev_sta_a,
prev_c as prev_c_a,
prev_ca as prev_ca_a
from team_form_by_match
where home_team=0
and match_number>=6;

--Combine home and away results together

create or replace table tw_innovation_day_summarised_results as
select a.*,
b.away_team,
b.position_a,
b.prev_ftg_a,
prev_ftga_a,
prev_htg_a,
prev_htga_a,
prev_shots_a,
prev_shotsa_a,
prev_st_a,
prev_sta_a,
prev_c_a,
prev_ca_a
from home_summarised_results a 
inner join away_summarised_results b 
on a.match_id=b.match_id;