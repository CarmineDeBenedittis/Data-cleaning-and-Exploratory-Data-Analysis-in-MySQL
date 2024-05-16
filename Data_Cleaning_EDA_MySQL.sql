-- reading the dataset
select * from titanic_dataset;

-- DATA CLEANING

-- create a copy of the table named ds_titanic
create table ds_titanic
like titanic_dataset;
insert ds_titanic select * from titanic_dataset;

select * from ds_titanic;

-- check if there is any Primary Key
desc ds_titanic;
-- there is no primary key

-- check for duplicates
with duplicate_CTE as (
	select *, row_number() over(partition by PassengerID) as row_num
	from ds_titanic
)
select *
from duplicate_CTE
where row_num > 1;
-- there are no duplicates

-- set 'PassengerId' as Primary Key
alter table ds_titanic add primary key(PassengerId);
desc ds_titanic;
-- now PassengerId is set as a Primary Key

-- splitting Name column
-- we first create a temporary table to store the new columns in
create temporary table temp_table as
select *, 
replace(left(Name,locate('.',Name)-1),left(Name,locate(',',Name)+1),'') as Title, 
replace(Name,left(Name,locate('.',Name)+1),'') as FirstName, 
left(Name,locate(',',Name)-1) as Surname
from ds_titanic;

-- then we create a new table where to save the data and drop the temporary table
create table ds_titanic2
like temp_table;
insert ds_titanic2 select * from temp_table;
drop table temp_table;

-- cleaning strings
-- remove unwanted characters from FirstName and Surname
update ds_titanic2
set FirstName = replace(replace(replace(FirstName,'(',''),')',''),'"',''),
	Surname = replace(Surname,'-',' ');

-- rounding the values in the Age column
update ds_titanic2
set Age = round(Age);

-- checking for null values
select * from ds_titanic2
where null;
-- there is no null value

-- removing unwanted and unnecessary columns 
-- checking the percentage of empty values in Cabin
select cabin, concat(round((count(cabin)/(select count(cabin) from ds_titanic))*100), '%') as cb 
from ds_titanic
where cabin = '';
-- since 75% of the values are empty this column doesn't give enough information to be consideredd useful, therefore it must be removed
-- remove the columns
alter table ds_titanic2
drop column Name,
drop column Cabin;

select * from ds_titanic2;

-- EXPLORATORY DATA ANALYSIS

-- checking the number of families on board using the column Surname
select count(NumMemb) as `number of families on board` 
from (
	select Surname, count(Surname)NumMemb from ds_titanic2
	group by Surname
	having NumMemb > 1
    ) Family_Size;

-- then checking the number of people who survived but lost at least one family members 
with Percentage_Survived as (
	select FirstName, Surname, NumMemb, Survived, sum(Survived/NumMemb) over (partition by Surname) as PercSurv_PerFam 
	from (
		select FirstName, Surname, count(Surname) over (partition by Surname) as NumMemb, Survived
		from ds_titanic2
		order by Surname desc, Survived
        ) Family_Size_Survived
	where NumMemb > 1
    )
select sum(Survived) as `people who survived but lost at least one family members` 
from Percentage_Survived
where PercSurv_PerFam > 0 and PercSurv_PerFam < 1;

-- checking the number of married women on board
select count(Title) `number of married women on board`
from ds_titanic2
where Title = 'Mrs';

-- checking the number of underage that died
select count(Age) `number of underage that died`
from ds_titanic2
where Age < 18 and Survived = 0;

-- checking the number of women that died
select count(Sex) `number of women that died`
from ds_titanic2
where Sex = 'female' and Survived = 0;

-- checking deaths by passenger's class
select Pclass, count(Survived)Deaths 
from ds_titanic2 
where Survived = 0 
group by Pclass
order by Pclass asc;

-- check the average fare per class
select Pclass, round(avg(Fare),2)AvgFare
from ds_titanic2
group by Pclass
order by Pclass asc;

select * from ds_titanic2;