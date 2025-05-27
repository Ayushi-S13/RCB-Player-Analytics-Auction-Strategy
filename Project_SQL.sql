use ipl;
-- ----------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------OBJECTIVE QUESTIONS---------------------------------------------

-- Q.1
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'ball_by_ball';

-- select * from ball_by_ball;   
-- select * from extra_runs;
-- select * from season;

-- select * from matches
-- where Season_Id = 1;

-- select * from team;
-- select * from player;
-- select * from player_match;

-- Q.2
select 
	m.Season_Id,
    sum(b.Runs_Scored)+sum(coalesce(e.Extra_Runs,0)) as Total_Runs_Scored
from Ball_by_Ball b 
join Team t on t.Team_Id=b.Team_Batting
join Matches m on m.Match_Id=b.Match_Id
left join Extra_Runs e on e.Match_Id=b.Match_Id and
	e.Over_Id=b.Over_Id and e.Ball_Id=b.Ball_Id and	
    e.Innings_No=b.Innings_No
where t.Team_Name  = "Royal Challengers Bangalore" and 
Season_Id = (select min(Season_Id) from matches where Match_Id = m.Match_Id)
group by Season_Id
order by Season_Id
limit 1;

-- Q.3
SELECT COUNT(DISTINCT p.Player_Id) AS Players_Count
FROM player p
JOIN player_match pm ON p.Player_Id = pm.Player_Id
JOIN matches m ON pm.Match_Id = m.Match_Id 
where year(m.Match_Date) = 2014
AND TIMESTAMPDIFF(YEAR, p.DOB, '2014-01-01') > 25;

select * from win_by;
select * from team;

-- Q.4
select count(*) Matches_Win
from team t
join matches m on t.Team_Id = m.Team_1 or t.Team_Id = m.Team_2 
where Match_Winner = 2 and Team_Name = 'Royal Challengers Bangalore'
and year(Match_Date) = 2013;

-- Q.5
WITH last_seasons AS (
    SELECT distinct Season_Year, Season_ID
    FROM season
    ORDER BY Season_Year DESC 
    LIMIT 4
)
SELECT 
    distinct p.Player_Name, 
    (SUM(b.Runs_Scored) * 100.0 / COUNT(b.Ball_Id)) AS Strike_Rate
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_Id
JOIN matches m ON b.Match_Id = m.Match_Id
JOIN last_seasons l ON m.Season_Id = l.Season_ID
GROUP BY b.Striker
ORDER BY Strike_Rate DESC
LIMIT 10;

select * from batting_style;

-- Q.6
SELECT 
    distinct b.Striker AS Player_ID, 
    p.Player_Name, 
    SUM(b.Runs_Scored) AS Total_Runs, 
    COUNT(DISTINCT b.Match_Id) AS Innings_Played, 
    round((SUM(b.Runs_Scored) / COUNT(DISTINCT b.Match_Id)),2) AS Avg_Runs
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_Id
-- JOIN matches m ON b.Match_Id = m.Match_Id
GROUP BY b.Striker, p.Player_Name
ORDER BY Avg_Runs DESC;

select * from wicket_taken;

-- Q.7 
select
	distinct b.Bowler as Bowler_Id,
    p.Player_Name, 
    COUNT(w.Player_Out) AS Total_Wickets, 
    COUNT(DISTINCT b.Match_Id) AS Innings_Played, 
    round((COUNT(w.Player_Out) / COUNT(b.Match_Id)),2) AS Avg_Wickets_Taken
FROM ball_by_ball b
JOIN player p ON b.Bowler = p.Player_Id
JOIN wicket_taken w on (b.Match_Id = w.Match_Id and b.Over_Id = w.Over_Id 
	and b.Ball_Id = w.Ball_Id and b.Innings_No = w.Innings_No)
-- JOIN matches m ON b.Match_Id = m.Match_Id
GROUP BY b.Bowler, p.Player_Name
ORDER BY Total_Wickets desc;

-- Q.8
-- CTE to get batting stats
WITH batting_stats AS (
    SELECT 
        b.Striker AS Player_ID,
        SUM(b.Runs_Scored) AS Total_Runs,
        COUNT(DISTINCT b.Match_Id) AS Innings_Played,
        (SUM(b.Runs_Scored) * 1.0 / COUNT(DISTINCT b.Match_Id)) AS Avg_Runs
    FROM ball_by_ball b
    GROUP BY b.Striker
    
),
-- CTE to get bowling stats
bowling_stats AS (
    SELECT 
        b.Bowler AS Player_ID,
        COUNT(w.Player_Out) AS Total_Wickets,
        COUNT(DISTINCT b.Match_Id) AS Innings_Played, 
		COUNT(w.Player_Out) / COUNT(DISTINCT b.Match_Id) AS Avg_Wickets_Taken
    FROM ball_by_ball b
    JOIN wicket_taken w 
        ON b.Match_Id = w.Match_Id 
        AND b.Over_Id = w.Over_Id 
        AND b.Ball_Id = w.Ball_Id 
        AND b.Innings_No = w.Innings_No
    GROUP BY b.Bowler
),
-- CTEs to get global averages
overall_batting_avg AS (
    SELECT 
        (SUM(Runs_Scored) * 1.0 / COUNT(DISTINCT Match_Id)) AS Overall_Bat_Avg
    FROM ball_by_ball
),
overall_bowling_avg AS (
    SELECT 
        (COUNT(*) * 1.0 / COUNT(DISTINCT Bowler)) AS Overall_Wicket_Avg
    FROM (
        SELECT 
            b.Bowler,
            w.Player_Out
        FROM ball_by_ball b
        JOIN wicket_taken w 
            ON b.Match_Id = w.Match_Id 
            AND b.Over_Id = w.Over_Id 
            AND b.Ball_Id = w.Ball_Id 
            AND b.Innings_No = w.Innings_No
    ) AS temp
)
-- Final selection of all-rounders
SELECT 
    p.Player_Id,
    p.Player_Name,
    bat.Avg_Runs,
    bowl.Avg_Wickets_Taken
FROM player p
JOIN batting_stats bat ON p.Player_Id = bat.Player_ID
JOIN bowling_stats bowl ON p.Player_Id = bowl.Player_ID
JOIN overall_batting_avg oba ON 1=1
JOIN overall_bowling_avg obo ON 1=1
WHERE 
    bat.Avg_Runs > oba.Overall_Bat_Avg
    AND bowl.Avg_Wickets_Taken > obo.Overall_Wicket_Avg
ORDER BY bat.Avg_Runs DESC, bowl.Avg_Wickets_Taken DESC;

-- select * from venue;

-- Q.9
CREATE TABLE rcb_record AS
SELECT 
    v.Venue_Name,
    SUM(CASE 
            WHEN (m.Team_1 = 2 OR m.Team_2 = 2) AND m.Match_Winner = 2 
            THEN 1 ELSE 0 
        END) AS Wins,
    SUM(CASE 
            WHEN (m.Team_1 = 2 OR m.Team_2 = 2) AND m.Match_Winner <> 2 
                 AND m.Match_Winner IS NOT NULL
            THEN 1 ELSE 0 
        END) AS Losses
FROM matches m
JOIN venue v ON m.Venue_Id = v.Venue_Id
GROUP BY v.Venue_Name;

select * from rcb_record;

select * from bowling_style;
select * from wicket_taken;
-- select * from out_type; 
select * from player;
select * from ball_by_ball;


-- Q.10  use ipl
select 
	bs.Bowling_skill,
    coalesce(count(w.Player_Out),0) as Total_Wickets
from bowling_style bs 
join player p on bs.Bowling_Id = p.Bowling_skill
join ball_by_ball b on p.Player_Id = b.Bowler
join wicket_taken w on 
	b.Match_Id = w.Match_Id and
    b.Over_Id = w.Over_Id and 
    b.Ball_Id = w.Ball_Id and
    b.Innings_No = w.Innings_No
where bs.Bowling_skill is not null
group by bs.Bowling_skill
order by total_wickets desc;

-- Q.11
-- select * from season;
-- select * from team;
-- select * from ball_by_ball;   

-- Runs per team per season
WITH team_runs AS (
    SELECT 
        t.Team_Name,
        s.Season_Year,
        SUM(b.Runs_Scored) AS Total_Runs
    FROM team t 
    JOIN matches m ON t.Team_Id = m.Team_1 OR t.Team_Id = m.Team_2
    JOIN season s ON m.Season_Id = s.Season_Id
    JOIN ball_by_ball b ON m.Match_Id = b.Match_Id
    WHERE b.Team_Batting = t.Team_Id  -- only include runs scored BY the team
    GROUP BY t.Team_Name, s.Season_Year
),
-- Wickets taken per team per season
team_wickets AS (
    SELECT 
        t.Team_Name,
        s.Season_Year,
        COUNT(w.Player_Out) AS Total_Wickets
    FROM team t 
    JOIN matches m ON t.Team_Id = m.Team_1 OR t.Team_Id = m.Team_2
    JOIN season s ON m.Season_Id = s.Season_Id
    JOIN ball_by_ball b ON m.Match_Id = b.Match_Id
    JOIN wicket_taken w ON b.Match_Id = w.Match_Id 
        AND b.Over_Id = w.Over_Id 
        AND b.Ball_Id = w.Ball_Id 
        AND b.Innings_No = w.Innings_No
    WHERE b.Team_Bowling = t.Team_Id  -- only count wickets taken BY the team
    GROUP BY t.Team_Name, s.Season_Year
), Wickets_Runs as(

-- Combine both
SELECT 
    r.Team_Name,
    r.Season_Year,
    r.Total_Runs,
	LAG(r.Total_Runs) OVER (PARTITION BY r.Team_Name ORDER BY r.Season_Year) AS Prev_Runs,
    COALESCE(w.Total_Wickets, 0) AS Total_Wickets,
	LAG(w.Total_Wickets) OVER (PARTITION BY w.Team_Name ORDER BY w.Season_Year) AS Prev_Wickets

FROM team_runs r
LEFT JOIN team_wickets w 
    ON r.Team_Name = w.Team_Name AND r.Season_Year = w.Season_Year
)
select
	Team_Name,
    Season_Year,
    Total_Runs,
    Prev_Runs,
    Total_Wickets,
    Prev_Wickets,
    case
		when Prev_Runs is null or Prev_Wickets is null then "No Previous Data"
        when Total_Runs > Prev_Runs and Total_Wickets > Prev_Wickets then "Increased"
		when Total_Runs < Prev_Runs and Total_Wickets < Prev_Wickets then "Decreased"
        else "Mixed"
	end as Performance_Status
from Wickets_Runs
ORDER BY Team_Name, Season_Year;

-- OR 

WITH team_stats AS (
  SELECT 
    t.Team_Name,
    s.Season_Year,
    SUM(CASE WHEN b.Team_Batting = t.Team_Id THEN b.Runs_Scored ELSE 0 END) AS Total_Runs,
    COUNT(CASE WHEN b.Team_Bowling = t.Team_Id AND w.Player_Out IS NOT NULL THEN 1 END) AS Total_Wickets
  FROM team t
  JOIN matches m ON t.Team_Id IN (m.Team_1, m.Team_2)
  JOIN season s ON m.Season_Id = s.Season_Id
  JOIN ball_by_ball b ON m.Match_Id = b.Match_Id
  LEFT JOIN wicket_taken w ON b.Match_Id = w.Match_Id 
      AND b.Over_Id = w.Over_Id 
      AND b.Ball_Id = w.Ball_Id 
      AND b.Innings_No = w.Innings_No
  GROUP BY t.Team_Name, s.Season_Year
),
performance AS (
  SELECT *,
    coalesce(LAG(Total_Runs) OVER (PARTITION BY Team_Name ORDER BY Season_Year), 0) AS Prev_Runs,
    coalesce(LAG(Total_Wickets) OVER (PARTITION BY Team_Name ORDER BY Season_Year), 0) AS Prev_Wickets
  FROM team_stats
)
SELECT 
  Team_Name, Season_Year, Total_Runs, Prev_Runs, Total_Wickets, Prev_Wickets,
  CASE 
    WHEN Prev_Runs IS NULL OR Prev_Wickets IS NULL THEN 'No Previous Data'
    WHEN Total_Runs > Prev_Runs AND Total_Wickets > Prev_Wickets THEN 'Increased'
    WHEN Total_Runs < Prev_Runs AND Total_Wickets < Prev_Wickets THEN 'Decreased'
    ELSE 'Mixed'
  END AS Performance_Status
FROM performance
ORDER BY Team_Name, Season_Year;

-- select * from season;
-- select * from matches;
-- select * from team;

-- Q. 12 Advanced KPIs for Team Strategy
-- (1) (a) Dot Ball Percentage (Batting)
SELECT
  p.Player_Name,
  ROUND(SUM(CASE WHEN b.Runs_Scored = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Dot_Ball_Percentage
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_ID
WHERE b.Team_Batting = (SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore')
GROUP BY p.Player_Name;
-- ORDER BY Dot_Ball_Percentage desc;

-- (b) Dot Ball Percentage (Bowling)
SELECT
  p.Player_Name,
  ROUND(SUM(CASE WHEN b.Runs_Scored = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Dot_Ball_Percentage
FROM ball_by_ball b
JOIN player p ON b.Bowler = p.Player_ID
WHERE b.Team_Bowling = (SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore')
GROUP BY p.Player_Name;

-- (2) Boundary Percentage
SELECT
  p.Player_Name,
  ROUND(SUM(CASE WHEN b.Runs_Scored IN (4,6) THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Boundary_Percentage
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_ID
WHERE b.Team_Batting = (SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore')
GROUP BY p.Player_Name;

-- (3) Phase-Wise Performance
SELECT
  p.Player_Name,
  CASE 
    WHEN b.Over_Id BETWEEN 1 AND 6 THEN 'Powerplay'
    WHEN b.Over_Id BETWEEN 7 AND 15 THEN 'Middle Overs'
    ELSE 'Death Overs'
  END AS Phase,
  COUNT(*) AS Balls_Faced,
  SUM(b.Runs_Scored) AS Runs,
  ROUND(SUM(b.Runs_Scored * 1.0) / COUNT(*), 2) AS Runs_Per_Ball
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_ID
WHERE b.Team_Batting = (SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore')
GROUP BY p.Player_Name, Phase;

-- (4)  Bowling Style Effectiveness
SELECT
  bs.Bowling_skill,
  COUNT(*) AS Deliveries,
  SUM(CASE WHEN w.Player_Out IS NOT NULL THEN 1 ELSE 0 END) AS Wickets,
  ROUND(SUM(b.Runs_Scored * 1.0) / COUNT(*), 2) AS Economy_Rate
FROM ball_by_ball b
JOIN player p ON b.Bowler = p.Player_ID
JOIN bowling_style bs on p.Bowling_skill = bs.Bowling_Id
LEFT JOIN wicket_taken w on (b.Match_Id = w.Match_Id and b.Over_Id = w.Over_Id 
	and b.Ball_Id = w.Ball_Id and b.Innings_No = w.Innings_No)
WHERE b.Team_Bowling = (SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore')
GROUP BY bs.Bowling_skill
ORDER BY Economy_Rate;

-- (5) Home vs. Away Performance
SELECT 
    CASE 
        WHEN v.Venue_Name = 'M Chinnaswamy Stadium' THEN 'Home'
        ELSE 'Away'
    END AS Location,
    COUNT(*) AS Matches_Played,
    SUM(CASE WHEN Match_Winner = t.Team_ID THEN 1 ELSE 0 END) AS Matches_Won,
    ROUND(SUM(CASE WHEN Match_Winner = t.Team_ID THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Win_Percentage
FROM matches m
JOIN venue v ON m.Venue_Id = v.Venue_Id
JOIN team t ON t.Team_Name = 'Royal Challengers Bangalore'
WHERE t.Team_ID IN (m.Team_1, m.Team_2)
GROUP BY Location;

-- Q.13 Average wickets taken by each bowler in each venue also rank them based on their average values.
with cte as (select
    Venue_Name as Venue,
    p.Player_Name, 
    round((COUNT(w.Player_Out)*1.0 / COUNT(DISTINCT b.Match_Id)),2) AS Avg_Wickets_Taken
FROM ball_by_ball b
JOIN player p ON b.Bowler = p.Player_Id
JOIN wicket_taken w on (b.Match_Id = w.Match_Id and b.Over_Id = w.Over_Id 
	and b.Ball_Id = w.Ball_Id and b.Innings_No = w.Innings_No)
JOIN matches m ON b.Match_Id = m.Match_Id
JOIN venue v on m.Venue_Id = v.Venue_Id
GROUP BY Venue, p.Player_Name
), ranked as (select 
				Venue, Player_Name, Avg_Wickets_Taken,
				dense_rank() over (order by Avg_Wickets_Taken desc) Ranks
			 from cte
             )select * from ranked
ORDER BY Venue, Ranks;

-- select * from ball_by_ball;

-- Q.14 (1) Consistent Performance of the batsman by Innings Played and Total Runs Scored in the seasons.
with cte as(
SELECT 
    distinct b.Striker AS Player_ID, 
    p.Player_Name, 
    SUM(b.Runs_Scored) AS Total_Runs, 
    COUNT(DISTINCT b.Match_Id) AS Innings_Played, 
    round((SUM(b.Runs_Scored) / COUNT(DISTINCT b.Match_Id)),2) AS Avg_Runs
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_Id
JOIN matches m ON b.Match_Id = m.Match_Id
GROUP BY b.Striker, p.Player_Name
)
select * from cte
where Total_Runs > 1500
and Innings_Played > 40
-- and Avg_Runs >= 30
ORDER BY Total_Runs DESC, Innings_Played DESC;

-- (2) Consistent Performance of the bowlers by Innings Played and Total Wickets Taken in the seasons.
with cte as(
select
	distinct b.Bowler as Bowler_Id,
    p.Player_Name, 
    COUNT(w.Player_Out) AS Total_Wickets, 
    COUNT(DISTINCT b.Match_Id) AS Innings_Played, 
    round((COUNT(w.Player_Out) / COUNT(DISTINCT b.Match_Id)),2) AS Avg_Wickets_Taken
FROM ball_by_ball b
JOIN player p ON b.Bowler = p.Player_Id
JOIN wicket_taken w on (b.Match_Id = w.Match_Id and b.Over_Id = w.Over_Id 
	and b.Ball_Id = w.Ball_Id and b.Innings_No = w.Innings_No)
JOIN matches m ON b.Match_Id = m.Match_Id
GROUP BY b.Bowler, p.Player_Name
)
select * from cte
where Total_Wickets > 55
and Innings_Played > 30
ORDER BY Total_Wickets desc, Innings_Played desc;


-- Q.15 (1) Batsman whose performance are more suited to specific Venues:
WITH player_venue_stats AS (
    SELECT
        p.Player_Id,
        p.Player_Name,
        v.Venue_Id,
        v.Venue_Name,
        SUM(b.Runs_Scored) AS Total_Runs,
        COUNT(DISTINCT b.Match_Id) AS Innings_Played,
        SUM(b.Runs_Scored) * 1.0 / COUNT(DISTINCT b.Match_Id) AS Avg_Runs_Venue
    FROM ball_by_ball b
    JOIN player p ON b.Striker = p.Player_Id
    JOIN matches m ON b.Match_Id = m.Match_Id
    JOIN venue v ON m.Venue_Id = v.Venue_Id
    GROUP BY p.Player_Id, p.Player_Name, v.Venue_Id, v.Venue_Name
),
player_overall_stats AS (
    SELECT
        p.Player_Id,
        p.Player_Name,
        SUM(b.Runs_Scored) AS Total_Runs,
        COUNT(DISTINCT b.Match_Id) AS Innings_Played,
        SUM(b.Runs_Scored) * 1.0 / COUNT(DISTINCT b.Match_Id) AS Avg_Runs_Overall
    FROM ball_by_ball b
    JOIN player p ON b.Striker = p.Player_Id
    GROUP BY p.Player_Id, p.Player_Name
)
SELECT
    pvs.Player_Id,
    pvs.Player_Name,
    pvs.Venue_Name,
    pvs.Avg_Runs_Venue,
    pos.Avg_Runs_Overall,
    (pvs.Avg_Runs_Venue - pos.Avg_Runs_Overall) AS Avg_Difference
FROM player_venue_stats pvs
JOIN player_overall_stats pos ON pvs.Player_Id = pos.Player_Id
WHERE pvs.Innings_Played >= 5 -- Consider venues where the player has played at least 5 innings
ORDER BY pvs.Player_Name, Avg_Difference DESC;

-- (2) Bowlers whose performance are more suited to specific Venues:
WITH player_venue_stats AS (
    SELECT
        p.Player_Id,
        p.Player_Name,
        v.Venue_Id,
        v.Venue_Name,
		COUNT(w.Player_Out) AS Total_Wickets, 
		COUNT(DISTINCT b.Match_Id) AS Innings_Played, 
		COUNT(w.Player_Out) / COUNT(DISTINCT b.Match_Id) AS Avg_Wickets_Venue
    FROM ball_by_ball b
    JOIN player p ON b.Bowler = p.Player_Id
	JOIN wicket_taken w on (b.Match_Id = w.Match_Id and b.Over_Id = w.Over_Id 
			and b.Ball_Id = w.Ball_Id and b.Innings_No = w.Innings_No)
    JOIN matches m ON b.Match_Id = m.Match_Id
    JOIN venue v ON m.Venue_Id = v.Venue_Id
    GROUP BY p.Player_Id, p.Player_Name, v.Venue_Id, v.Venue_Name
),
player_overall_stats AS (
    SELECT
        p.Player_Id,
        p.Player_Name,
        COUNT(w.Player_Out) AS Total_Wickets, 
		COUNT(DISTINCT b.Match_Id) AS Innings_Played, 
		COUNT(w.Player_Out) / COUNT(DISTINCT b.Match_Id) AS Avg_Wickets_Overall
    FROM ball_by_ball b
    JOIN player p ON b.Bowler = p.Player_Id
	JOIN wicket_taken w on (b.Match_Id = w.Match_Id and b.Over_Id = w.Over_Id 
			and b.Ball_Id = w.Ball_Id and b.Innings_No = w.Innings_No)
    GROUP BY p.Player_Id, p.Player_Name
)
SELECT
    pvs.Player_Id,
    pvs.Player_Name,
    pvs.Venue_Name,
    pvs.Avg_Wickets_Venue,
    pos.Avg_Wickets_Overall,
    (pvs.Avg_Wickets_Venue - pos.Avg_Wickets_Overall) AS Avg_Difference
FROM player_venue_stats pvs
JOIN player_overall_stats pos ON pvs.Player_Id = pos.Player_Id
WHERE pvs.Innings_Played >= 5 -- Consider venues where the player has played at least 5 innings
ORDER BY pvs.Player_Name, Avg_Difference DESC;

-- -----------------------------------------------------------------------------------------------------------------
-- RCB Batsmen:

SELECT 
    b.Striker AS Player_ID, 
    p.Player_Name, 
    SUM(b.Runs_Scored) AS Total_Runs, 
    COUNT(DISTINCT b.Match_Id) AS Innings_Played, 
    ROUND(SUM(b.Runs_Scored) * 100.0 / COUNT(b.Ball_Id), 2) AS Strike_Rate,
    ROUND(SUM(b.Runs_Scored) * 1.0 / COUNT(DISTINCT b.Match_Id), 2) AS Avg_Runs
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_Id
JOIN matches m ON b.Match_Id = m.Match_Id
WHERE b.Team_Batting = 2  -- RCB's Team_Id
GROUP BY b.Striker, p.Player_Name
ORDER BY Avg_Runs DESC;

-- RCB's Bowlers-
SELECT
    b.Bowler AS Bowler_Id,
    p.Player_Name, 
    COUNT(w.Player_Out) AS Total_Wickets, 
    COUNT(DISTINCT b.Match_Id) AS Innings_Played, 
    ROUND(COUNT(w.Player_Out) * 1.0 / COUNT(DISTINCT b.Match_Id), 2) AS Avg_Wickets_Taken,
    ROUND(SUM(b.Runs_Scored) * 6.0 / COUNT(*), 2) AS Economy_Rate
FROM ball_by_ball b
JOIN player p ON b.Bowler = p.Player_Id
JOIN wicket_taken w ON 
    b.Match_Id = w.Match_Id AND 
    b.Over_Id = w.Over_Id AND 
    b.Ball_Id = w.Ball_Id AND 
    b.Innings_No = w.Innings_No AND 
    w.Player_Out IS NOT NULL  -- Ensures only actual dismissals are counted
JOIN matches m ON b.Match_Id = m.Match_Id
WHERE b.Team_Bowling = 2  -- RCB's Team_Id
GROUP BY b.Bowler, p.Player_Name
ORDER BY Total_Wickets DESC;


-- -----------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------SUBJECTIVE QUESTIONS---------------------------------------------

-- Q.1

use ipl;
-- select * from toss_decision;
-- select * from matches;
-- select * from venue;
-- select * from team;
-- select * from outcome;
-- select * from win_by;

WITH MatchTeamVenue AS (
    SELECT 
        m.Match_Id,
        v.Venue_Name,
        m.Toss_Winner,
        m.Match_Winner,
        td.Toss_Name AS Toss_Decision,
        t1.Team_Id AS Team1_Id,
        t1.Team_Name AS Team1_Name,
        t2.Team_Id AS Team2_Id,
        t2.Team_Name AS Team2_Name
    FROM matches m
    JOIN venue v ON m.Venue_Id = v.Venue_Id
    JOIN toss_decision td ON m.Toss_Decide = td.Toss_Id
    JOIN team t1 ON m.Team_1 = t1.Team_Id
    JOIN team t2 ON m.Team_2 = t2.Team_Id
)
SELECT 
    Team_Name,
    Venue_Name,
    COUNT(DISTINCT Match_Id) AS Matches_Played,
    COUNT(DISTINCT CASE WHEN Team_Id = Toss_Winner THEN Match_Id END) AS Toss_Wins,
	Toss_Decision,
    COUNT(DISTINCT CASE WHEN Team_Id = Match_Winner THEN Match_Id END) AS Match_Wins,
    ROUND(
        (COUNT(DISTINCT CASE WHEN Team_Id = Match_Winner THEN Match_Id END) * 100.0) / COUNT(DISTINCT Match_Id),
        2
    ) AS Win_Percentage
FROM (
    SELECT Match_Id, Venue_Name, Toss_Decision, Toss_Winner, Match_Winner, Team1_Id AS Team_Id, Team1_Name AS Team_Name FROM MatchTeamVenue
    UNION ALL
    SELECT Match_Id, Venue_Name, Toss_Decision, Toss_Winner, Match_Winner, Team2_Id AS Team_Id, Team2_Name AS Team_Name FROM MatchTeamVenue
) AS AllTeams
GROUP BY Team_Name, Venue_Name, Toss_Decision
ORDER BY Team_Name, Venue_Name;

-- select * from rolee;
-- select * from ball_by_ball;
-- select * from player;

-- Q.2 (1) Top Batsmen:
SELECT 
    distinct p.Player_Name, 
    SUM(b.Runs_Scored) AS Total_Runs, 
    COUNT(DISTINCT b.Match_Id) AS Matches_Played, 
    round((SUM(b.Runs_Scored) *100 / COUNT(b.Ball_Id)),2) AS Strike_Rate
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_Id
JOIN matches m ON b.Match_Id = m.Match_Id
GROUP BY p.Player_Name
ORDER BY Total_Runs DESC
limit 10;

-- select * from wicket_taken;

-- (2) Top Bowlers:
select
	distinct p.Player_Name, 
    COUNT(w.Player_Out) AS Total_Wickets, 
    COUNT(DISTINCT b.Match_Id) AS Matches_Played, 
	round(SUM(b.Runs_Scored) / NULLIF(COUNT(w.Player_Out),0),2) AS Bowling_Avg,
	round(SUM(b.Runs_Scored) / (COUNT(*)/6.0), 2) AS Economy_Rate
--     round((COUNT(w.Player_Out) / COUNT(b.Match_Id)),2) AS Avg_Wickets_Taken
FROM ball_by_ball b
JOIN player p ON b.Bowler = p.Player_Id
LEFT JOIN wicket_taken w on (b.Match_Id = w.Match_Id and b.Over_Id = w.Over_Id 
	and b.Ball_Id = w.Ball_Id and b.Innings_No = w.Innings_No)
JOIN matches m ON b.Match_Id = m.Match_Id
GROUP BY p.Player_Name
HAVING COUNT(*) >= 60  -- Equivalent to at least 10 overs
ORDER BY Total_Wickets desc
limit 10;

-- (3) Top All-Rounders:
SELECT
    p.Player_Name,
    -- Batting Metrics
    SUM(CASE WHEN b.Striker = p.Player_Id THEN b.Runs_Scored ELSE 0 END) AS Total_Runs,
    COUNT(DISTINCT CASE WHEN b.Striker = p.Player_Id THEN b.Match_Id END) AS Matches_Played,
    ROUND(
        SUM(CASE WHEN b.Striker = p.Player_Id THEN b.Runs_Scored ELSE 0 END) /
        NULLIF(COUNT(DISTINCT CASE WHEN b.Striker = p.Player_Id THEN b.Match_Id END), 0),
        2
    ) AS Batting_Avg,
    -- Bowling Metrics
    COUNT(DISTINCT CASE WHEN b.Bowler = p.Player_Id AND w.Player_Out IS NOT NULL THEN CONCAT(b.Match_Id, '-', b.Over_Id, '-', b.Ball_Id) END) AS Total_Wickets,
    ROUND(
        SUM(CASE WHEN b.Bowler = p.Player_Id THEN b.Runs_Scored ELSE 0 END) /
        NULLIF(COUNT(DISTINCT CASE WHEN b.Bowler = p.Player_Id AND w.Player_Out IS NOT NULL THEN CONCAT(b.Match_Id, '-', b.Over_Id, '-', b.Ball_Id) END), 0),
        2
    ) AS Bowling_Avg
FROM ball_by_ball b
JOIN player p ON p.Player_Id IN (b.Striker, b.Bowler)
LEFT JOIN wicket_taken w ON b.Match_Id = w.Match_Id
    AND b.Over_Id = w.Over_Id
    AND b.Ball_Id = w.Ball_Id
    AND b.Innings_No = w.Innings_No
GROUP BY p.Player_Name
ORDER BY (SUM(CASE WHEN b.Striker = p.Player_Id THEN b.Runs_Scored ELSE 0 END) + 
     COUNT(DISTINCT CASE WHEN b.Bowler = p.Player_Id AND w.Player_Out IS NOT NULL THEN CONCAT(b.Match_Id, '-', b.Over_Id, '-', b.Ball_Id) END) * 20) DESC
LIMIT 10;


-- Q.3 (1) Batting Performance:

SELECT 
    p.Player_Name,
    SUM(b.Runs_Scored) AS Total_Runs,
    COUNT(CASE WHEN w.Player_Out IS NOT NULL THEN 1 END) AS Times_Out,
    ROUND(SUM(b.Runs_Scored) / NULLIF(COUNT(CASE WHEN w.Player_Out IS NOT NULL THEN 1 END), 0), 2) AS Batting_Average
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_Id
LEFT JOIN wicket_taken w ON b.Match_Id = w.Match_Id 
                   AND b.Over_Id = w.Over_Id 
                   AND b.Ball_Id = w.Ball_Id 
                   AND b.Innings_No = w.Innings_No
GROUP BY p.Player_Name
ORDER BY Total_Runs DESC
LIMIT 10;

-- (2) Bowling Performance:

SELECT 
    p.Player_Name,
    COUNT(w.Player_Out) AS Total_Wickets,
    ROUND(SUM(b.Runs_Scored) / NULLIF(COUNT(w.Player_Out), 0), 2) AS Bowling_Average,
    ROUND(SUM(b.Runs_Scored) / NULLIF(COUNT(DISTINCT CONCAT(b.Match_Id, '-', b.Over_Id)), 0), 2) AS Economy_Rate
FROM ball_by_ball b
JOIN player p ON b.Bowler = p.Player_Id
LEFT JOIN wicket_taken w ON b.Match_Id = w.Match_Id 
                   AND b.Over_Id = w.Over_Id 
                   AND b.Ball_Id = w.Ball_Id 
                   AND b.Innings_No = w.Innings_No
GROUP BY p.Player_Name
ORDER BY Total_Wickets DESC
LIMIT 10;

-- (3) All-Rounder Performance:

select * from out_type;
select * from wicket_taken;

SELECT 
    p.Player_Name,
    SUM(CASE WHEN b.Striker = p.Player_Id THEN b.Runs_Scored ELSE 0 END) AS Total_Runs,
    COUNT(CASE WHEN b.Bowler = p.Player_Id AND w.Player_Out IS NOT NULL THEN 1 END) AS Total_Wickets,
    ROUND(SUM(CASE WHEN b.Striker = p.Player_Id THEN b.Runs_Scored ELSE 0 END) + 
          20 * COUNT(CASE WHEN b.Bowler = p.Player_Id AND w.Player_Out IS NOT NULL THEN 1 END), 2) AS All_Rounder_Score
FROM ball_by_ball b
JOIN player p ON p.Player_Id IN (b.Striker, b.Bowler)
LEFT JOIN wicket_taken w ON b.Match_Id = w.Match_Id 
                   AND b.Over_Id = w.Over_Id 
                   AND b.Ball_Id = w.Ball_Id 
                   AND b.Innings_No = w.Innings_No
GROUP BY p.Player_Name
ORDER BY All_Rounder_Score DESC
LIMIT 10;

-- Q.4 -- use ipl;

SELECT 
    p.Player_Name,
    SUM(CASE WHEN b.Striker = p.Player_Id THEN b.Runs_Scored ELSE 0 END) AS Total_Runs,
    COUNT(DISTINCT CASE WHEN b.Bowler = p.Player_Id AND w.Player_Out IS NOT NULL 
		THEN CONCAT(b.Match_Id, '-', b.Over_Id, '-', b.Ball_Id) END) AS Total_Wickets,
    ROUND(SUM(CASE WHEN b.Striker = p.Player_Id THEN b.Runs_Scored ELSE 0 END) / 
		NULLIF(COUNT(CASE WHEN b.Striker = p.Player_Id AND w.Player_Out IS NOT NULL THEN 1 END), 0), 2) AS Batting_Average,
    ROUND(SUM(CASE WHEN b.Bowler = p.Player_Id THEN b.Runs_Scored ELSE 0 END) / 
		NULLIF(COUNT(CASE WHEN b.Bowler = p.Player_Id AND w.Player_Out IS NOT NULL THEN 1 END), 0), 2) AS Bowling_Average
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_Id OR b.Bowler = p.Player_Id
LEFT JOIN wicket_taken w ON b.Match_Id = w.Match_Id 
                   AND b.Over_Id = w.Over_Id 
                   AND b.Ball_Id = w.Ball_Id 
                   AND b.Innings_No = w.Innings_No
GROUP BY p.Player_Name
HAVING Total_Runs > 500 AND Total_Wickets > 20
ORDER BY (Total_Runs + (Total_Wickets * 20)) DESC;
-- LIMIT 10;

-- Q.5 (1) Choose a player

SELECT 
    pm.Player_ID, 
    p.Player_Name, 
    COUNT(*) AS Matches_Played
FROM player_match pm
JOIN player p ON pm.Player_ID = p.Player_ID
GROUP BY pm.Player_ID, p.Player_Name
ORDER BY Matches_Played DESC
LIMIT 20;  -- Chosen Player_Id = 35 (For Eg.)

-- (2) Team Win Rate When the Player Played

-- SELECT 
--     COUNT(*) AS Total_Matches,
--     SUM(CASE WHEN m.Match_Winner = pm.Team_ID THEN 1 ELSE 0 END) AS Wins,
--     ROUND(100.0 * SUM(CASE WHEN m.Match_Winner = pm.Team_ID THEN 1 ELSE 0 END) / COUNT(*), 2) AS Win_Percentage
-- FROM player_match pm
-- JOIN matches m ON m.Match_ID = pm.Match_ID
-- WHERE pm.Player_ID = 35; -- 20, 8, 208

-- (3) Team Win Rate When the Player Did NOT Play

-- select * from player_match
-- where Player_Id =35;

-- WITH player_matches AS (
--     SELECT Match_ID
--     FROM player_match
--     WHERE Player_ID = 35
-- ),
-- team_matches AS (
--     SELECT Match_ID
--     FROM matches
--     WHERE Team_1 = 3 OR Team_2 = 3
-- ),
-- matches_without_player AS (
--     SELECT Match_ID
--     FROM team_matches
--     WHERE Match_ID NOT IN (SELECT Match_ID FROM player_matches)
-- )
-- SELECT 
--     COUNT(*) AS Total_Matches,
--     SUM(CASE WHEN Match_Winner = 3 THEN 1 ELSE 0 END) AS Wins,
--     ROUND(100.0 * SUM(CASE WHEN Match_Winner = 3 THEN 1 ELSE 0 END) / COUNT(*), 2) AS Win_Percentage
-- FROM matches
-- WHERE Match_ID IN (SELECT Match_ID FROM matches_without_player);

-- ----------------------------------------[OR]---------------------------------------------

-- (2) & (3) Team Win Rate When the Player Played and When the Player Did NOT Play
-- Get all matches for player and his team                      (Better Approach)

WITH player_matches AS (
    SELECT Match_ID, Team_ID
    FROM player_match
    WHERE Player_ID = 208
    -- in (
-- 		SELECT 
-- 			Player_ID from (
-- 				SELECT 
-- 				pm.Player_ID,
-- -- 			--     p.Player_Name, 
-- 				COUNT(*) AS Matches_Played
-- 			FROM player_match pm
-- 			JOIN player p ON pm.Player_ID = p.Player_ID
-- 			GROUP BY pm.Player_ID, p.Player_Name
-- 			ORDER BY Matches_Played DESC
-- 			LIMIT 20) t) 
),
player_teams AS (
    SELECT DISTINCT Team_ID
    FROM player_matches
),
team_matches AS (
    SELECT Match_ID,
           CASE 
               WHEN Team_1 IN (SELECT Team_ID FROM player_teams) THEN Team_1
               ELSE Team_2
           END AS Team_ID
    FROM matches
    WHERE Team_1 IN (SELECT Team_ID FROM player_teams)
       OR Team_2 IN (SELECT Team_ID FROM player_teams)
),
-- Matches where the player DID NOT play
matches_without_player AS (
    SELECT tm.Match_ID, tm.Team_ID
    FROM team_matches tm
    WHERE NOT EXISTS (
        SELECT 1
        FROM player_matches pm
        WHERE pm.Match_ID = tm.Match_ID
    )
),
-- Matches where the player DID play
matches_with_player AS (
    SELECT pm.Match_ID, pm.Team_ID
    FROM player_matches pm
)
-- Final SELECT: Compare both scenarios
SELECT 
    'With Player' AS Scenario,
    COUNT(*) AS Total_Matches,
    SUM(CASE WHEN m.Match_Winner = mwp.Team_ID THEN 1 ELSE 0 END) AS Wins,
    ROUND(100.0 * SUM(CASE WHEN m.Match_Winner = mwp.Team_ID THEN 1 ELSE 0 END) / COUNT(*), 2) AS Win_Percentage
FROM matches m
JOIN matches_with_player mwp ON m.Match_ID = mwp.Match_ID
	UNION ALL
SELECT 
    'Without Player' AS Scenario,
    COUNT(*) AS Total_Matches,
    SUM(CASE WHEN m.Match_Winner = mwp.Team_ID THEN 1 ELSE 0 END) AS Wins,
    ROUND(100.0 * SUM(CASE WHEN m.Match_Winner = mwp.Team_ID THEN 1 ELSE 0 END) / COUNT(*), 2) AS Win_Percentage
FROM matches m
JOIN matches_without_player mwp ON m.Match_ID = mwp.Match_ID;


-- Q.6 Suggestion to RCB before going to mega auction:

-- (1) Which Players Have the Highest Match Impact for RCB?
SELECT 
    p.Player_Name,
    COUNT(*) AS Matches_Played,
    SUM(CASE WHEN m.Match_Winner = pm.Team_ID THEN 1 ELSE 0 END) AS Wins_With_Player,
    ROUND(100.0 * SUM(CASE WHEN m.Match_Winner = pm.Team_ID THEN 1 ELSE 0 END) / COUNT(*), 2) AS Win_Percentage
FROM player_match pm
JOIN matches m ON m.Match_ID = pm.Match_ID
JOIN player p ON p.Player_ID = pm.Player_ID
WHERE pm.Team_ID = (SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore')
GROUP BY p.Player_Name
HAVING COUNT(*) > 20
ORDER BY Win_Percentage DESC;

-- (2) Death Over Bowling Problems? Check Economy in Overs 16–20:
SELECT 
    p.Player_Name,
    COUNT(DISTINCT m.Match_ID) AS Matches_Played,
    COUNT(DISTINCT b.Over_Id) AS Overs_Bowled,
--     ROUND(SUM(b.Runs_Scored) * 1.0 / COUNT(*), 2) AS Economy_Rate
	ROUND(SUM(b.Runs_Scored) * 6.0 / COUNT(*), 2) AS Economy_Rate
FROM ball_by_ball b
JOIN player p ON b.Bowler = p.Player_ID
JOIN matches m ON b.Match_ID = m.Match_ID
WHERE b.Team_Bowling = (SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore')
  AND b.Over_Id BETWEEN 16 AND 20
GROUP BY p.Player_Name
HAVING COUNT(*) > 20
ORDER BY Economy_Rate ASC;

-- select * from ball_by_ball; use ipl;

-- (3) RCB Batting Collapses? Find Out by Over Segment
SELECT
  CASE 
    WHEN Over_Id BETWEEN 1 AND 6 THEN 'Powerplay'
    WHEN Over_Id BETWEEN 7 AND 15 THEN 'Middle Overs'
    ELSE 'Death Overs'
  END AS Phase,
  count(DISTINCT Over_Id) Total_Overs,
  ROUND(SUM(Runs_Scored * 1.0) / COUNT(*), 2) AS Runs_Per_Ball
FROM ball_by_ball b
JOIN matches m ON b.Match_ID = m.Match_ID
WHERE b.Team_Batting = (SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore')
GROUP BY Phase;
 
-- Further analysis
-- SELECT
--   p.Player_Name,
--   CASE 
--     WHEN b.Over_Id BETWEEN 1 AND 6 THEN 'Powerplay'
--     WHEN b.Over_Id BETWEEN 7 AND 15 THEN 'Middle Overs'
--     ELSE 'Death Overs'
--   END AS Phase,
--   COUNT(*) AS Balls_Faced,
--   SUM(b.Runs_Scored) AS Runs,
--   ROUND(SUM(b.Runs_Scored * 1.0) / COUNT(*), 2) AS Runs_Per_Ball
-- FROM ball_by_ball b
-- JOIN player p ON b.Striker = p.Player_ID
-- WHERE b.Team_Batting = (SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore')
-- GROUP BY p.Player_Name, Phase
-- HAVING COUNT(*) > 20 -- Optional: filter to players with enough balls faced
-- ORDER BY p.Player_Name, Phase;

-- (4) Which Players Perform Best Against RCB?
SELECT p.Player_Name AS Player_Name, SUM(b.Runs_Scored) AS Runs_Against_RCB
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_Id
JOIN matches m ON b.Match_ID = m.Match_ID
WHERE b.Team_Bowling = (SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore')
GROUP BY b.Striker
HAVING SUM(b.Runs_Scored) > 150
ORDER BY Runs_Against_RCB DESC;

-- select * from venue;
-- select * from team;
-- select * from matches;

-- Q.7 
-- (1) Factors Behind High-Scoring Matches
-- Good partnerships
SELECT 
    p1.Player_Name AS Striker, 
    p2.Player_Name AS Non_Striker, 
    COUNT(*) AS Balls_Faced, 
    SUM(b.runs_scored) AS Total_Partnership_Runs
FROM ball_by_ball b
JOIN player p1 ON b.Striker = p1.Player_Id
JOIN player p2 ON b.Non_Striker = p2.Player_Id
GROUP BY p1.Player_Name, p2.Player_Name
HAVING SUM(b.runs_scored) > 30
ORDER BY Total_Partnership_Runs DESC;


-- select * from win_by;

-- (2) Impact on Viewership (via match excitement)
-- Close matches
SELECT 
    Match_Id, 
    w.Win_Type, 
    Win_Margin
FROM matches m 
JOIN win_by w ON m.Win_Type = w.Win_Id
WHERE (w.Win_Type = 'runs' AND Win_Margin <= 10)
   OR (w.Win_Type = 'wickets' AND Win_Margin <= 2);


-- Chasing team win
SELECT 
	match_id, 
    Team_Name AS Team_Won, 
    Toss_Name
FROM matches m 
LEFT JOIN team t ON m.Match_Winner = t.Team_Id 
LEFT JOIN toss_decision td ON m.Toss_Decide = td.Toss_Id
WHERE td.Toss_Name = 'field' AND t.Team_Id = m.Toss_Winner;

-- Death overs: high drama
SELECT 
  b.Match_Id, 
  b.Over_Id,
  SUM(runs_scored) AS Death_over_runs,
  COUNT(CASE WHEN Player_Out IS NOT NULL THEN 1 END) AS Death_Over_Wickets
FROM ball_by_ball b
LEFT JOIN wicket_taken w ON b.Match_Id = w.Match_Id
 AND b.Over_Id = w.Over_Id 
 AND b.Ball_Id = w.Ball_Id
 AND b.Innings_No = w.Innings_No
WHERE b.Over_Id BETWEEN 16 AND 20
GROUP BY b.Match_Id, b.Over_Id;

-- (3) Team Strategy Recommendations
-- Batsmen with high Strike Rate and Avg
SELECT 
	   Player_Name as Striker, 
       SUM(runs_scored) / COUNT(DISTINCT match_id) AS Batting_Avg,
       (SUM(runs_scored) * 100.0) / COUNT(*) AS Strike_Rate,
       SUM(CASE WHEN runs_scored IN (4, 6) THEN 1 ELSE 0 END) AS Boundary_Count
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_Id
GROUP BY Striker
HAVING COUNT(DISTINCT match_id) > 10
ORDER BY Strike_Rate DESC;

-- Players who perform best vs RCB 
SELECT  
	p.Player_Name AS Player_Name, 
    SUM(b.Runs_Scored) AS Runs_Against_RCB
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_Id
JOIN matches m ON b.Match_ID = m.Match_ID
WHERE b.Team_Bowling = (
	SELECT Team_ID FROM team 
    WHERE Team_Name = 'Royal Challengers Bangalore')
GROUP BY b.Striker
HAVING SUM(b.Runs_Scored) > 150
ORDER BY Runs_Against_RCB DESC;

-- select * from rolee;

-- Q.8
SELECT 
    CASE 
        WHEN v.Venue_Name = 'M Chinnaswamy Stadium' THEN 'Home'
        ELSE 'Away'
    END AS Location,
    COUNT(*) AS Matches,
    SUM(CASE WHEN Match_Winner = t.Team_ID THEN 1 ELSE 0 END) AS Wins,
    ROUND(SUM(CASE WHEN Match_Winner = t.Team_ID THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Win_Percentage
FROM matches m
JOIN venue v ON m.Venue_Id = v.Venue_Id
JOIN team t ON t.Team_Name = 'Royal Challengers Bangalore'
WHERE t.Team_ID IN (m.Team_1, m.Team_2)
GROUP BY Location;

-- Q.9
SELECT
    m.Match_Id,
    m.Season_Id,
    v.Venue_Name,
    CASE 
        WHEN m.Team_1 = t.Team_ID THEN t1.Team_Name
        ELSE t2.Team_Name
    END AS Opponent,
    CASE 
        WHEN m.Match_Winner = t.Team_ID THEN 1          -- Here, 1 = Win & 0 = Loss
        ELSE 0
    END AS Result,
    m.Match_Date
FROM matches m
JOIN venue v ON m.Venue_Id = v.Venue_Id
JOIN team t ON t.Team_Name = 'Royal Challengers Bangalore'
JOIN team t1 ON m.Team_1 = t1.Team_ID
JOIN team t2 ON m.Team_2 = t2.Team_ID
WHERE m.Team_1 = t.Team_ID OR m.Team_2 = t.Team_ID;

-- Q.11
update matches
set Opponent_Team = "Delhi_Daredevils"
where Opponent_Team = "Delhi_Capitals";
