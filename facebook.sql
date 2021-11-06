#Table: Friending(date|time|action|actor_id|target_id)
#action = {'send_request', 'accept_request'}

Q(1) Find friend request acceptance rate.

SELECT sum(if(action = 'accept_request',1,0))*1.0/sum(if(action='send_request',1,0)) as acpt_rate
FROM Friending

Q(2) Generate the friend request acceptance rate for people who accept within 24 hours.

SELECT SUM(if (b.target_id is null, 0,1))*1.0/COUNT(*) as acpt_rate
FROM Friending as a LEFT JOIN Friending as b ON a.target_id = b.actor_id
AND a.actor_id = b.target_id
AND a.action = 'send_request'
AND b.action = 'accept_request'
AND TIMESTAMPDIFF(hour,timestamp(a.date)),timestamp(b.date))<=24

Q(3)  Generate the acceptance for each user.

WITH acpt as (
SELECT actor_id, COUNT(*) as acpt_num
FROM Friending 
WHERE action = 'accept_request'
GROUP BY actor_id)

SELECT a.target_id,  SUM(IFNULL(acpt.acpt_num,0))*1.0/COUNT(*) as acpt_rate
FROM Friending as a LEFT JOIN acpt ON a.target = acpt.actor_id
AND a.action = 'send_request'
GROUP BY 1

Q(4) Given timestamps of logins, figure out how many people on Facebook were active all seven days of a week on a mobile phone.

SLEECT COUNT(*) FROM(
SELECT user_id FROM
(SELECT DISTINCT user_id, date 
FROM table 
WHERE DAYOFWEEL(date)>0 AND DAYOFWEEK(date)<=7
）as t1
GROUP BY user_id
HAVING COUNT(*)=7
) as t2

2. table_name: friending
+-----------------+-------------+------------------------------------------+
| column         | data_type | description |
+-----------------+-------------+------------------------------------------+
| sender_id      | BIGINT    | Facebook Id for user sending request |
| receiver_id    | BIGINT    | Facebook Id for user receiving request |
| sent_date      | STRING    | Date when request was sent |
| accepted_date  | STRING    | Date when request was accepted, NULL if not accepted |
| sender_country | STRING    | Facebook Identifier
+---------------+---------------+------------------------------------------+
sender_id  | receiver_id | sent_date  | accepted_date | sender_country
1          | 2           | 2019-09-15 | 2019-09-18    | US
1          | 3           | 2019-10-15 | 2019-10-15    | US
2          | 3           | 2019-10-15 | NULL          | CA

table_name: age
+---------------+---------------+---------------------------+
| column    | data_type | description |
+---------------+---------------+---------------------------+
| userid    | BIGINT    | Facebook Id for user |
| age_group | STRING    | 'under20', '20-40', '40-60', 'over60' |
+---------------+---------------+---------------------------+
SAMPLE ROWS:
userid | age_group
1234   | '20-40'
5678   | '40-60'
9010   | 'under20'

Q1 Same-day acceptance rate in the last 7 days.

SELECT SUM(if(sent_date=accepted_date,1,0))*1.0 / COUNT(*) as acpt_rate
FROM Friending
WHERE CAST(send_date AS DATE) BETWEEN ... AND ...
GROUP BY send_date

Q2 Average number of friendship requests sent per user over the past week by age groups.

WITH T AS (
SELECT a.send_id,
SUM(IF(b.age_group = 'under20',1,0)) as under20,
SUM(IF(b.age_group = '20-40',1,0)) as age20_40,
SUM(IF(b.age_group = '40-60',1,0)) as age40_60,
SUM(IF(b.age_group = 'over60',1,0)) as over60,
FROM Friending as a JOIN ON Age as b ON a.sender_id = b.user_id
GROUP BY send_id) 
SELECT AVG(under20),AVG(age20_40),AVG(age40_60),AVG(over60) 
  FROM T

Product round:
---------
You are a DS on the friending team. The overall number of friend accepts on the platform has gone down by 5% in June. How would you look into this?
---------
We have a suggestion to add more relatives in the friend algorithm. How would you test if this is a good or a bad idea?-


