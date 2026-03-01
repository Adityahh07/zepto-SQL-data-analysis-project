create database zepto_storeroom;
use zepto_storeroom;

create table zepto(
sku_id INT AUTO_INCREMENT PRIMARY KEY,
category varchar(120),
name varchar(150) not null,
mrp numeric(8,2),
discountPercent numeric(5,2),
availableQuantity integer,
discountedSellingPrice numeric(8,2),
weightInGms integer,
outOfStock varchar(20),
quantity integer
);

-- Check allowed directory for LOAD DATA
SHOW VARIABLES LIKE 'secure_file_priv';

-- Load CSV data into zepto table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/zepto_v2.csv'
INTO TABLE zepto
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(category, name, mrp, discountPercent, availableQuantity,
 discountedSellingPrice, weightInGms, outOfStock, quantity);

DESC zepto;

-- Data Exploration

-- Count of Rows
select count(*) from zepto;

-- Sample Data
select * from zepto
limit 10;

-- Null Values
select * from zepto
where name is null
or
category is null
or
mrp is null
or
discountPercent is null
or
discountedSellingPrice is null
or
weightInGms is null
or
availableQuantity is null
or
outOfStock is null
or
quantity is null;


-- different product categories
select distinct category
from zepto
order by category;

-- products in stock vs out of stock
select outOfStock, count(sku_id)
from zepto
group by outOfStock;

-- Product names present multiple times
select name,count(sku_id) as number_of_SKUs
from zepto
group by name
having count(sku_id)>1
order by count(sku_id) desc;

-- Data Cleaning

-- Products with price = 0
select sku_id, mrp 
from zepto 
where mrp = 0;

start transaction;

delete from zepto 
where sku_id in (
    select sku_id from (
        select sku_id from zepto where mrp = 0
    ) as temp
);

select * from zepto where mrp = 0;

commit;

-- Convert Paise to Rupees
select sku_id, mrp, discountedSellingPrice
from zepto
limit 10;

start transaction;

update zepto
set mrp = mrp / 100.0,
    discountedSellingPrice = discountedSellingPrice / 100.0
where mrp > 100;

select sku_id, mrp, discountedSellingPrice
from zepto
limit 10;

commit;

-- Data Analysis

-- Q1. Find the top 10 best-value products based on the discount percentage.
select distinct name, mrp,discountPercent,discountedSellingPrice
from zepto
order by discountPercent desc
limit 10;

-- Q2.What are the Products with High MRP but Out of Stock
select distinct name, mrp
from zepto
where outOfStock = 'TRUE' and mrp > 300
order by mrp desc;

-- Q3.Calculate Estimated Revenue for each category
select distinct category, sum(discountedSellingPrice*availableQuantity) as total_revenue
from zepto
group by category
order by total_revenue;

-- Q4. Find all products where MRP is greater than ₹500 and discount is less than 10%.
select distinct name, mrp,discountPercent
from zepto
where mrp > 500 and discountPercent < 10
order by mrp desc,discountPercent asc;

-- Q5. Identify the top 5 categories offering the highest average discount percentage.
select category, round(avg(discountPercent),2) as average_discount
from zepto
group by category
order by average_discount desc
limit 5;

-- Q6. Find the price per gram for products above 100g and sort by best value.
select distinct name, weightInGms, discountedSellingPrice,
round((discountedSellingPrice/weightInGms),2) as price_per_gram
from zepto
where weightInGms > 100
order by price_per_gram asc;

-- Q7.Group the products into categories like Low, Medium, Bulk.
select distinct name, weightInGms,
case when weightInGms < 1000 then 'Low'
when weightInGms < 5000 then 'Medium'
else 'Bulk'
end as weight_category
from zepto;

-- Q8.What is the Total Inventory Weight Per Category 
select category, sum(weightInGms*availableQuantity) as total_weight
from zepto
group by category
order by total_weight;



