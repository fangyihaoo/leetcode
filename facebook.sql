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
  
table_name: fraud, columns: user_id, fraud_tyoe


Q1 Same-day acceptance rate in the last 7 days.
  SELECT sender_id, SUM(IF(accepted_date = sent_date, 1,0))/COUNT(*) as percentage
  FROM friending
  WHERE send_date >= CURDATE() - INTERVAL 7 DAY
  GROUP BY sender_id

or 
  
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

Q3.What is percentage of sender without fraud in all senders?
  SELECT 
  (SELECT COUNT(DISTINCT sender_id)
  FROM friending as a JOIN fraud as b ON a.sender_id = b.user_id
  WHERE b.fraud_type = 1)
  /
  (SELECT COUNT(DISTINCT sender_id)
   FROM friending
  )
  as fraud_rate
  
Product sense:
  https://medium.com/airbnb-engineering/at-airbnb-data-science-belongs-everywhere-917250c6beba
---------
You are a DS on the friending team. The overall number of friend accepts on the platform has gone down by 5% in June. How would you look into this?
  idea: break down the problem.
  1. Check the data collection firstly, how did we collect the data? Any seasonal pattern? Special events?
  2. Check the overall number of friend request to see if the it drops or not. If drops, the issue may comes from the friend request side, then we can check the 
  add friend button to see if there is any changes around it before June. If yes, we can check it CTR for add friends button and if there is a deline then it might 
  be the reason.
  3. New feature launched, primacy effect.
  4. also cohort users based on platform they are using and also the region (geography information), to see if it is platform specific or region specific decline.
---------
We have a suggestion to add more relatives in the friend algorithm. How would you test if this is a good or a bad idea?
  1. What is the goal of this new feature? Find metrics like friends requests/accept rate, Monthly active users, user engagement(posts,comments,shares,likes) meaningful connection.
  2. The metircs we propose are to check two things. 1. if the new features work or not (A/B testing). 2. bring positive effects in long term(user engagament, revenue)
  3. For the first one, we can propose the A/B test on those metrics (CTR of friend require/accept button, or CTP of users) Bern(p), design experiment. 
For the second one, before A/B testing, we need to identify opportunit, what is the opportunity sizing? For specific user or all user? 
  4. Tradeoff between metrics, like month active users increase but engagement decrease in a short time, but user engagement could increase in a long period since we have more MAU.
  If both of them increase, we can consider the revenue it can bring to us by the opportunity sizing of target group.


