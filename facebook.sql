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

2. Table:
Friending: send_id || receive_id || send_time || accept_time || country
Age: user_id || age_group

Q1 Same-day acceptance rate in the last 7 days.

SELECT SUM(if(TIMESTAMPDIFF(hour,send_time,accept_time)<=24,1,0))*1.0 / COUNT(*) as acpt_rate
FROM Friending
WHERE send_time > CURDATE() - INTERVAL 7 DAY

Q2 Average requests sent per user for each age groups.
SELECT AVG(group_count)
FROM
(SELECT b.age_group, COUNT(*) as group_count
FROM Friending a JOiN Age b ON a.send_id = b.user_id
GROUP BY b.age_group
) t


