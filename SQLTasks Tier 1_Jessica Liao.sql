/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 1 of the case study, which means that there'll be more guidance for you about how to 
setup your local SQLite connection in PART 2 of the case study. 

The questions in the case study are exactly the same as with Tier 2. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */
SELECT name
FROM Facilities
WHERE membercost !=0


/* Q2: How many facilities do not charge a fee to members? */
SELECT COUNT( * )
FROM Facilities
WHERE membercost =0

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */
SELECT facid , name , membercost , monthlymaintenance
FROM Facilities
WHERE membercost !=0
AND membercost < 0.2 * monthlymaintenance

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */
SELECT *
FROM Facilities
WHERE facid
IN ( 1, 5 )

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */
SELECT CASE WHEN monthlymaintenance >=100
THEN expensive
WHEN monthlymaintenance <100
THEN cheap
END AS label, name , monthlymaintenance
FROM Facilities

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */
SELECT firstname,surname
FROM Members
WHERE joindate = (SELECT MAX( joindate ) FROM Members )

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

select m.membername, f.facilityname
from
(SELECT DISTINCT memid, facid FROM Bookings WHERE facid IN ( 0, 1 ) ORDER BY memid) as b
left join
(SELECT memid , CONCAT( firstname , ' ', surname ) AS membername FROM Members) as m on b.memid = m .memid 
left join
(SELECT facid , name as facilityname FROM Facilities) as f on b.facid = f.facid
order by m.membername

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

select CONCAT(m.firstname , ' ', m.surname ) AS membername, f.name,  case when b.memid = 0 then b.slots * f.guestcost when b.memid != 0 then b.slots * f.membercost end as cost 
from Bookings as b
left join Members as m on b.memid = m.memid
left join Facilities as f on b.facid = f.facid
where date(cast(b.starttime as datetime))  = '2012-09-14' 
and (case when b.memid = 0 then b.slots * f.guestcost when b.memid != 0 then b.slots * f.membercost end) > 30
order by cost

/* Q9: This time, produce the same result as in Q8, but using a subquery. */

select m.membername, f.name,  case when b.memid = 0 then b.slots * f.guestcost when b.memid != 0 then b.slots * f.membercost end as cost
from
(SELECT bookid, facid, memid, starttime, slots FROM Bookings where date(cast(starttime as datetime))  = '2012-09-14') as b
left join
(SELECT memid , CONCAT( firstname , ' ', surname ) AS membername FROM Members) as m on b.memid = m .memid 
left join
(SELECT facid , name, membercost, guestcost FROM Facilities) as f on b.facid = f.facid
where (case when b.memid = 0 then b.slots * f.guestcost when b.memid != 0 then b.slots * f.membercost end) > 30
order by cost

/* PART 2: SQLite
/* We now want you to jump over to a local instance of the database on your machine. 

Copy and paste the LocalSQLConnection.py script into an empty Jupyter notebook, and run it. 

Make sure that the SQLFiles folder containing thes files is in your working directory, and
that you haven't changed the name of the .db file from 'sqlite\db\pythonsqlite'.

You should see the output from the initial query 'SELECT * FROM FACILITIES'.

Complete the remaining tasks in the Jupyter interface. If you struggle, feel free to go back
to the PHPMyAdmin interface as and when you need to. 

You'll need to paste your query into value of the 'query1' variable and run the code block again to get an output.
 
QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

Select l.Facility, sum(l.Revenue) as TotalRevenue
from
(select f.name as Facility, b.Role, case when b.Role = 'Guest' then b.TotalSlots * f.guestcost when b.Role = 'Member' then b.TotalSlots * f.membercost end as Revenue
from
(SELECT facid, case when memid = 0 then 'Guest' when memid != 0 then 'Member' end as Role, sum(slots) as TotalSlots FROM Bookings Group by facid, Role) as b
left join Facilities f on b.facid = f.facid) as l
Group by l.Facility
Order by TotalRevenue

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

SELECT surname, firstname, r.fullname as recommendedBy
FROM Members as m
left join 
(select m1.recommendedby as recid, m2.firstname||' '||m2.surname as fullname
from(select distinct recommendedby from Members where recommendedby != '') as m1
left join Members as m2 on m1.recommendedby = m2.memid) as r on r.recid = m.recommendedby
order by surname, firstname

/* Q12: Find the facilities with their usage by member, but not guests */

select m.firstname||' '||m.surname as fullname, f.name, a.totalslots
from
(select memid, facid, sum(slots) as totalslots from Bookings where memid != 0 Group by memid, facid) as a
left join Facilities as f on a.facid = f.facid
left join Members as m on a.memid = m.memid

/* Q13: Find the facilities usage by month, but not guests */

select a.month, f.name, a.totalslots
from 
(select facid, strftime('%m',starttime) as month, sum(slots) as totalslots
from Bookings group by month, facid) as a
left join Facilities as f on f.facid = a.facid
