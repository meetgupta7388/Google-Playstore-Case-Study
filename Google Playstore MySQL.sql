select * from playstore
truncate table playstore

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/mysql-files/playstore.csv'
INTO TABLE playstore
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from playstore
/*
You're working as a market analyst for a mobile app development company. 
Your task is to identify the most promising categories (TOP 5) for launching new free apps based on their average ratings.
*/

select Category , round(avg(Rating),2) as "Average_Rating" from playstore where Type = "Free" group by category 
order by Average_Rating desc limit 5

/*
As a business strategist for a mobile app company, your objective is to pinpoint the three categories that generate the most
 revenue from paid apps. This calculation is based on the product of the app price and its number of installations.
*/

select * from playstore

select category , round(avg(Rev),2) as "Revenue" from(
select * , (price*installs) as Rev from playstore where type ="Paid" ) as t group by category
order by Revenue desc limit 3

/*
As a data analyst for a gaming company, you're tasked with calculating the percentage of app within each category. 
This information will help the company understand the distribution of gaming apps across different categories.
*/

set @total = (select count(*) from playstore);

select category , round((cnt/@total)*100,2) as "percentage" from (
select category , count(*) as "cnt" from playstore group by category) as t;

/*
As a data analyst at a mobile app-focused market research firm you’ll recommend whether the company should develop 
paid or free apps for each category based on the ratings of that category.*/

select * from playstore

select category, 
(Case when avg_rat_paid>avg_rat_free then "Paid"
when avg_rat_paid<avg_rat_free then "Free"
ELSE 'Equal'
end) as "Make" from (
select a.category, b.avg_rat_free, a.avg_rat_paid from 
(
select category, avg(rating) as "avg_rat_paid" from playstore where type ="Paid" group by category
) as a inner join
(
select category, avg(rating) as "avg_rat_free" from playstore where type ="Free" group by category
) as b on a.category=b.category
)as t

/*Suppose you're a database administrator your databases have been hacked and hackers are changing price of certain apps on the database,
 it is taking long for IT team to neutralize the hack, however you as a responsible manager don’t want your data to be changed,
 do some measure where the changes in price can be recorded as you can’t stop hackers from making changes.
*/

-- creating table.
CREATE TABLE PriceChangeLog (
    App VARCHAR(255),
    Old_Price DECIMAL(10, 2),
    New_Price DECIMAL(10, 2),
    Operation_Type VARCHAR(10),
    Operation_Date TIMESTAMP
);

-- create copy of original table
create table play as
SELECT * FROM PLAYSTORE

-- for update
DELIMITER //   
CREATE TRIGGER price_change_update
AFTER UPDATE ON play
FOR EACH ROW
BEGIN
    INSERT INTO pricechangelog (app, old_price, new_price, operation_type, operation_date)
    VALUES (NEW.app, OLD.price, NEW.price, 'update', CURRENT_TIMESTAMP);
END;
//
DELIMITER ;

SET SQL_SAFE_UPDATES = 0;
UPDATE play
SET price = 4
WHERE app = 'Infinite Painter';


-- can check in pricechangelog table
select * from pricechangelog
 
/*Your IT team have neutralized the threat; however, hackers have made some changes in the prices,
 but because of your measure you have noted the changes,now you want correct data to be inserted into the database again.
*/

drop trigger price_change_update
update play as a inner join pricechangelog as b on a.app=b.app set a.price = b.old_price

/*As a data person you are assigned the task of investigating the correlation between two
 numeric factors: app ratings and the quantity of reviews.
*/
select * from playstore

set @x = (select round(avg(rating),2) from playstore);
set @y = (select round(avg(reviews),2) from playstore);

set @num = (select sum(((rating - @x)*(reviews - @y))) from playstore);


set @den1 = (select sqrt(sum((round((rating - @x),2)*round((rating - @x),2)))) from playstore);
set @den2 = (select sqrt(sum((round((reviews - @y),2)*round((reviews - @y),2)))) from playstore);

 select round((@num/(@den1 * @den2)),2) as 'correlation'
 
-- ya to ye

SET @x = (SELECT ROUND(AVG(rating), 2) FROM playstore);
SET @y = (SELECT ROUND(AVG(reviews), 2) FROM playstore);
with t as 
(
	select  *, round((rat*rat),2) as 'sqrt_x' , round((rev*rev),2) as 'sqrt_y' from
	(
		select  rating , @x, round((rating- @x),2) as 'rat' , reviews , @y, round((reviews-@y),2) as 'rev'from playstore
	)a                                                                                                                        
)
-- select * from  t
select  @numerator := round(sum(rat*rev),2) , @deno_1 := round(sum(sqrt_x),2) , @deno_2:= round(sum(sqrt_y),2) from t ; -- setp 4 

select round((@numerator)/(sqrt(@deno_1*@deno_2)),2) as corr_coeff

/*
Your boss noticed  that some rows in genres columns have multiple genres in them, which was creating issue when developing the
  recommender system from the data he/she assigned you the task to clean the genres column and make two genres out of it, rows
  that have only one genre will have other column as blank.
*/

DELIMITER //
CREATE FUNCTION f_name(a VARCHAR(100))
RETURNS VARCHAR(100)
DETERMINISTIC -- keyword used in MySQL when function returns output
BEGIN
    SET @l = LOCATE(';', a);

    SET @s = IF(@l > 0, LEFT(a, @l - 1), a);

    RETURN @s;
END//
DELIMITER ;

select f_name('Art & Design;Pretend Play')


-- function for second genre
DELIMITER //
create function l_name(a varchar(100))
returns varchar(100)
deterministic -- keyword used in MySQL when function returns output
begin
   set @l = locate(';',a);
   set @s = if(@l = 0 ,' ',substring(a,@l+1, length(a)));
   
   return @s;
end //
DELIMITER ;

select app, genres, f_name(genres) as 'gene 1', l_name(genres) as 'gene 2' from playstore

/*Your senior manager wants to know which apps are not performing as par in their particular category, however he is not interested
 in handling too many files or list for every  category and he/she assigned  you with a task of creating a dynamic tool where he/she
 can input a category of apps he/she  interested in  and your tool then provides real-time feedback by displaying apps within that 
 category that have ratings lower than the average rating for that specific category.
*/

DELIMITER //
CREATE PROCEDURE GetLowPerformingAppsByCategory(IN input_category VARCHAR(255))
BEGIN
    DECLARE avg_rating FLOAT;
    
    -- Calculate the average rating for the specified category
    SELECT AVG(rating) INTO avg_rating
    FROM playstore
    WHERE category = input_category;

    -- Select apps with ratings lower than the average rating for the specified category
    SELECT app, rating
    FROM playstore
    WHERE category = input_category
      AND rating < avg_rating;
END
//
DELIMITER ;

select * from playstore

CALL GetLowPerformingAppsByCategory('COMICS');

/*What is Duration Time and Fetch Time*/


/* Duration Time :- Duration time is how long  it takes system to completely understand the instructions given  from start to end 
 in proper order  and way.
 Fetch Time :- Once the instructions are completed , fetch ttime is like the time it takes for  the system to hand back the results,
 it depend on how quickly  ths system can find  and bring back what you asked for.
 
 If query is simple  and have  to show large valume of data, fetch time will be large, If query is complex duration time will be large.
*/