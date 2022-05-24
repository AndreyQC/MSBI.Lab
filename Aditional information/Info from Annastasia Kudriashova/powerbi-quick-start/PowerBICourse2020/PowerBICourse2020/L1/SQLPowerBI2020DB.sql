create table Country(country_name varchar(255), country_code varchar(5));

insert into Country
select 'Canada', 'CA'
union all
select'USA', 'US'
union all
select 'Mexico', 'MX'
union all
select 'Great Britain', 'GB';

create table Product_Category (category_name varchar(255));

insert into Product_Category
select 'food'
union all
select'sport'
union all
select 'home'
union all
select 'garden';

create table Product(product_name varchar(255), product_category varchar(255));

insert into Product
select 'bread', 'food'
union all
select'butter', 'food'
union all
select'small pizza', 'food'
union all
select 'medium pizza', 'food'
union all
select 'large pizza', 'food'
union all
select'Cola', 'food'
union all
select 'Pepsi', 'food'
union all
select 'Dr.Pepper', 'food'
union all
select'butter', 'home'
union all
select'table', 'home'
union all
select 'chair', 'home'
union all
select 'plate', 'home'
union all
select'glass', 'home'
union all
select 'spoon', 'home'
union all
select 'fork', 'home'
union all
select'butter', 'home'
union all
select'table', 'garden'
union all
select 'chair', 'garden'
union all
select 'plate', 'garden'
union all
select'glass', 'garden'
union all
select 'spoon', 'garden'
union all
select 'fork', 'garden'
union all
select 'ball', 'sport'
union all
select 'tennis table', 'garden';

create table Sales (country_code varchar(5), product  varchar(255), end_of_period datetime, value decimal(10,4));
truncate table sales;
insert into Sales
select c.country_code, p.product_name + ' ' + p.product_category, '2019-03-31 23:59:00',
case
  when  c.country_code = 'US' then (len(p.product_name) + 3)*9999.1
  when  c.country_code = 'GB' then (len(p.product_name) + 2)*9999.1
  when  c.country_code = 'CA' then (len(p.product_name) + 1)*9999.1
  when  c.country_code = 'MX' then (len(p.product_name) )*9999.1
end
from country c
  cross join product p
union all
select c.country_code, p.product_name + ' ' + p.product_category, '2019-06-30 23:59:00',
case
  when  c.country_code = 'US' then (len(p.product_name) + 3)*19998.1
  when  c.country_code = 'GB' then (len(p.product_name) + 2)*19999.1
  when  c.country_code = 'CA' then (len(p.product_name) + 1)*19999.1
  when  c.country_code = 'MX' then (len(p.product_name) )*19999.1
end
from country c
  cross join product p
union all
select c.country_code, p.product_name + ' ' + p.product_category, '2019-09-30 23:59:00',
case
  when  c.country_code = 'US' then (len(p.product_name) + 3)*29998.1
  when  c.country_code = 'GB' then (len(p.product_name) + 2)*29999.1
  when  c.country_code = 'CA' then (len(p.product_name) + 1)*29999.1
  when  c.country_code = 'MX' then (len(p.product_name) )*29999.1
end
from country c
  cross join product p

create table Total_Sales(country_code varchar(5), product_category  varchar(255), period varchar(10), total_revenue decimal(10,4));
insert into Total_Sales
select c.country_code, p.category_name, '2019',
case
  when  c.country_code = 'US' then (len(p.category_name) + 30)*3998.0
  when  c.country_code = 'GB' then (len(p.category_name) + 20)*3999.0
  when  c.country_code = 'CA' then (len(p.category_name) + 10)*3999.0
  when  c.country_code = 'MX' then (len(p.category_name) )*3999.0
end
from country c
  cross join product_category p
