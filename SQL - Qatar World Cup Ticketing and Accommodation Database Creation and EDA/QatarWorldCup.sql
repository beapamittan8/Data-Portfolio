CREATE DATABASE QatarWorldCup;
USE QatarWorldCup;

#1 Customer Data
CREATE TABLE CUSTOMER 
(Cust_ID varchar(10) PRIMARY KEY,
FirstName char(50),
LastName char(50),
Email varchar(50),
Gender varchar(50),
Age int,
CountryRes char(50));

#2 BooksFor Data
CREATE TABLE BOOKSFORUnary
(BookingCust_ID varchar(10),
TicketHolder_ID varchar(10),
FOREIGN KEY (BookingCust_ID) REFERENCES CUSTOMER(Cust_ID),
FOREIGN KEY (TicketHolder_ID) REFERENCES CUSTOMER(Cust_ID));

#3 Venue Data
CREATE TABLE VENUE
(VenueID varchar(50) PRIMARY KEY,
VenueName char(50),
Capacity int,
VenueCost int,
NoOfSecurity int,
NoOfCaterers int,
NoOfEventStaff int,
PayPerHour int);

#4  Game Data
CREATE TABLE GAME
(GameID varchar(10) PRIMARY KEY,
Team1ID varchar(20),
Team2ID varchar(20),
VenueID varchar(50),
GameDate date,
GameTime time,
FOREIGN KEY (VenueID) REFERENCES VENUE(VenueID));

#5 TrainStation Data
CREATE TABLE TRAINSTATION
(TrainStationID varchar(20) PRIMARY KEY,
StationName varchar(50),
VenueID varchar(50),
TrainOpsCost int,
StationStaffCost int,
FOREIGN KEY (VenueID) REFERENCES VENUE(VenueID));

#6 SeatCategory Data
CREATE TABLE SEATCATEGORY
(SeatCatID varchar(50) PRIMARY KEY,
SeatCategory char(5),
Price int,
Quantity int,
VenueID varchar(50),
FOREIGN KEY (VenueID) REFERENCES VENUE(VenueID));

#7 Seat Data
CREATE TABLE SEAT
(SeatID varchar(50) PRIMARY KEY,
SeatCatID varchar(50));

Alter Table SEAT 
ADD CONSTRAINT
FOREIGN KEY (SeatCatID) REFERENCES SEATCATEGORY(SeatCatID);

#8 Tickets Data
CREATE TABLE TICKET
(Ticket_ID varchar(50) PRIMARY KEY,
GameID varchar(50),
SeatID varchar(50),
FOREIGN KEY (GameID) REFERENCES GAME(GameID),
FOREIGN KEY (SeatID) REFERENCES SEAT(SeatID));

#9 Booking Data
CREATE TABLE BOOKING
(Booking_ID varchar(50) PRIMARY KEY,
BookingDate date,
BookingCust_ID varchar(50),
FOREIGN KEY (BookingCust_ID) REFERENCES CUSTOMER(Cust_ID));

#10 TicketBooking Data
CREATE TABLE TICKETBOOKING
(Booking_ID varchar(20),
TicketHolder_ID varchar(50),
Ticket_ID varchar(50),
PaymentType char(10),
FOREIGN KEY (Booking_ID) REFERENCES BOOKING(Booking_ID),
FOREIGN KEY (Ticket_ID) REFERENCES TICKET(Ticket_ID));

Alter Table TICKETBOOKING 
ADD CONSTRAINT
FOREIGN KEY (TicketHolder_ID) REFERENCES BOOKSFORUnary(TicketHolder_ID);

Alter Table TICKETBOOKING 
ADD CONSTRAINT
FOREIGN KEY (TicketHolder_ID) REFERENCES CUSTOMER(Cust_ID);

#11 Reservation Data
CREATE TABLE RESERVATION
(Reservation_ID varchar(20) PRIMARY KEY,
ReservationDate date,
Booking_ID varchar(20),
CheckInDate date,
CheckOutDate date,
StayDuration int,
FOREIGN KEY (Booking_ID) REFERENCES BOOKING(Booking_ID));

#12 Room Data
CREATE TABLE ROOM
(Room_No varchar(10) PRIMARY KEY,
RmCapacity int,
Price int,
HouseKeepingCost int,
UtilitiesCost int);

#13 RoomReservation Data
CREATE TABLE ROOMRESERVATION
(Reservation_ID varchar(20),
Room_No varchar(10),
PaymentType char(10),
FOREIGN KEY (Reservation_ID) REFERENCES RESERVATION(Reservation_ID),
FOREIGN KEY (Room_No) REFERENCES ROOM(Room_No));

# Checking if all tables loaded properly
Select * from CUSTOMER; 
Select * from BOOKSFORUnary;
Select * from VENUE; 
Select * from GAME;
Select * from TRAINSTATION; 
Select * from SEATCATEGORY;
Select * from SEAT; 
Select * from TICKET; 
Select * from BOOKING;
Select * from TICKETBOOKING; 
Select * from RESERVATION;
Select * from ROOM;
Select * from ROOMRESERVATION; 

###################### Descriptive Analytics #######################

# Total Number of Ticket Holders
SELECT COUNT(DISTINCT TicketHolder_ID) AS NoOfTicketHolders
FROM TICKETBOOKING;

# Number of Male and Female TicketHolders
SELECT CUSTOMER.Gender, COUNT(DISTINCT TICKETBOOKING.TicketHolder_ID) as Count
FROM CUSTOMER
RIGHT JOIN TICKETBOOKING ON CUSTOMER.Cust_ID = TICKETBOOKING.TicketHolder_ID
GROUP BY CUSTOMER.Gender;
    
#Number of Domestic vs International Attendees   
SELECT AttendeeType, COUNT(*) as Count
FROM (
SELECT DISTINCT(TICKETBOOKING.TicketHolder_ID),
	CASE WHEN CountryRes = 'Qatar' THEN 'Domestic' ELSE 'International'
	END AS AttendeeType
FROM CUSTOMER
RIGHT JOIN TICKETBOOKING ON CUSTOMER.Cust_ID = TICKETBOOKING.TicketHolder_ID
) as subquery_0
GROUP BY AttendeeType;


#################### Organizational Issues / Queries ######################

# 1 Number of Trains to Arrange
SELECT GameID, Attendees, ROUND(Attendees/30) as NoOfTrainsBefore,  ROUND(Attendees/30) as NoOfTrainsAfter
FROM( 
SELECT TICKET.GameID, COUNT(DISTINCT TICKETBOOKING.Ticket_ID) AS Attendees
FROM TICKETBOOKING
RIGHT JOIN TICKET on TICKETBOOKING.Ticket_ID = TICKET.Ticket_ID
GROUP BY TICKET.GameID)
as subquery_1;

# 2 Cost of Resources / Overhead for Trains Each Game
SELECT GameID, GameDate, GameTime, VenueName, Attendees, TotalNoOfTrains, TrainOpsCost, StationStaffCost, CostofTrainOps, 
(CostofTrainOps+StationStaffCost) as TotalOHTrainCost
FROM (
SELECT GameID, GameDate, GameTime, VenueName, Attendees, (NoOfTrainsBefore+NoOfTrainsAfter) as TotalNoOfTrains, TrainOpsCost, 
StationStaffCost, (TrainOpsCost*(NoOfTrainsBefore+NoOfTrainsAfter)) as CostofTrainOps
FROM (
SELECT GameID, GameDate, GameTime, VenueName, Attendees, ROUND(Attendees/30) as NoOfTrainsBefore,  ROUND(Attendees/30) as NoOfTrainsAfter, 
TrainOpsCost, StationStaffCost
FROM (
SELECT GAME.GameID, GAME.GameDate, GAME.GameTime, VENUE.VenueName, COUNT(TICKETBOOKING.TicketHolder_ID) as Attendees, TRAINSTATION.TrainOpsCost, 
TRAINSTATION.StationStaffCost
FROM TICKET
INNER JOIN TICKETBOOKING ON TICKET.Ticket_ID = TICKETBOOKING.Ticket_ID
RIGHT JOIN GAME  ON TICKET.GameID = GAME.GameID
RIGHT JOIN VENUE on GAME.VenueID = VENUE.VenueID
RIGHT JOIN TRAINSTATION on VENUE.VenueID = TRAINSTATION.VenueID
GROUP BY GAME.GameID, GAME.GameDate, GAME.GameTime, VENUE.VenueName, TRAINSTATION.TrainOpsCost, TRAINSTATION.StationStaffCost
ORDER BY GameDate)
as subquery_2)
as subquery_3)
as subquery_4;


# 3 Utilization of Venues based on Attendance per Game
SELECT GAME.GameID, GAME.GameDate, GAME.GameTime, VENUE.VenueName, COUNT(TICKETBOOKING.TicketHolder_ID) as Attendees, VENUE.Capacity, 
(COUNT(TICKETBOOKING.TicketHolder_ID)/Capacity) as Utilization
FROM TICKET
INNER JOIN TICKETBOOKING ON TICKET.Ticket_ID = TICKETBOOKING.Ticket_ID
RIGHT JOIN GAME  ON TICKET.GameID = GAME.GameID
RIGHT JOIN VENUE on GAME.VenueID = VENUE.VenueID
RIGHT JOIN TRAINSTATION on VENUE.VenueID = TRAINSTATION.VenueID
GROUP BY GAME.GameID, GAME.GameDate, GAME.GameTime, VENUE.VenueName, VENUE.Capacity
ORDER BY GameDate;


# 4 Variable Cost of Resources (Staff) based on Utilization of Venue & when the venue is at full capacity
SELECT GameID, TotalStaff, PayPerHour, TotalVarCost, Utilization, (TotalVarCost * Utilization) as ActualNeededVarCost, 
(TotalVarCost-ActualNeededVarCost) as Difference
FROM(
SELECT GameID, TotalStaff, PayPerHour, TotalVarCost, Utilization, (TotalVarCost * Utilization) as ActualNeededVarCost
FROM (
SELECT GameID, TotalStaff, PayPerHour, (TotalStaff*PayPerHour) as TotalVarCost, Utilization
FROM (
SELECT GAME.GameID, VENUE.VenueName, COUNT(TICKETBOOKING.TicketHolder_ID) as Attendees, VENUE.Capacity, 
(COUNT(TICKETBOOKING.TicketHolder_ID)/Capacity) as Utilization, VENUE.VenueCost, 
(VENUE.NoOfSecurity + VENUE.NoOfCaterers +VENUE.NoOfEventStaff) as TotalStaff, VENUE.PayPerHour
FROM TICKET
INNER JOIN TICKETBOOKING ON TICKET.Ticket_ID = TICKETBOOKING.Ticket_ID
RIGHT JOIN GAME  ON TICKET.GameID = GAME.GameID
RIGHT JOIN VENUE on GAME.VenueID = VENUE.VenueID
RIGHT JOIN TRAINSTATION on VENUE.VenueID = TRAINSTATION.VenueID
GROUP BY GAME.GameID, GAME.GameDate, GAME.GameTime, VENUE.VenueName, VENUE.Capacity, VENUE.VenueCost, VENUE.NoOfSecurity, 
VENUE.NoOfCaterers, VENUE.NoOfEventStaff, VENUE.PayPerHour
ORDER BY GameID
) as subquery_5
) as subquery_6
) as subquery_7;

# 5 Identify Peak Booking Dates / Months 
SELECT MONTH(BookingDate) AS Month, COUNT(MONTH(BookingDate)) AS NoOfBookings
FROM BOOKING
GROUP BY MONTH(BookingDate)
ORDER BY MONTH(BookingDate); 


# 6 Identify overhead cost percentage of game against revenue
SELECT GameID, TotalStaff, PayPerHour, TotalVarCost, Revenue, (TotalVarCost/Revenue) as OHPercentage
FROM (
SELECT GameID, TotalStaff, PayPerHour, (TotalStaff*PayPerHour) as TotalVarCost, Revenue
FROM (
SELECT GAME.GameID, (VENUE.NoOfSecurity + VENUE.NoOfCaterers +VENUE.NoOfEventStaff) as TotalStaff, VENUE.PayPerHour, 
SUM(SEATCATEGORY.Price) as Revenue
FROM TICKET
INNER JOIN TICKETBOOKING ON TICKET.Ticket_ID = TICKETBOOKING.Ticket_ID
RIGHT JOIN SEAT ON TICKET.SeatID = SEAT.SeatID
RIGHT JOIN SEATCATEGORY ON SEAT.SeatCatID = SEATCATEGORY.SeatCatID
RIGHT JOIN GAME  ON TICKET.GameID = GAME.GameID
RIGHT JOIN VENUE on GAME.VenueID = VENUE.VenueID
RIGHT JOIN TRAINSTATION on VENUE.VenueID = TRAINSTATION.VenueID
GROUP BY GAME.GameID, GAME.GameDate, GAME.GameTime, VENUE.VenueName, VENUE.Capacity, VENUE.VenueCost, VENUE.NoOfSecurity, 
VENUE.NoOfCaterers, VENUE.NoOfEventStaff, VENUE.PayPerHour
ORDER BY GameID
) as subquery_5
) as subquery_6;

######## FAN CAMP ############
# 7 Number of Rooms to give Priority to Ticket Holders
SELECT RmCapacity, COUNT(Room_No) as NoOfRooms, (RmCapacity*COUNT(Room_No)) as MaxGuests
FROM ROOM 
GROUP BY RmCapacity; 

# 8 Identify overhead cost of fan camp
SELECT RmCapacity, NoOfReservations, TotalHouseKeepingCost, TotalUtilitiesCost, TotalRevenue, 
((TotalHouseKeepingCost+TotalUtilitiesCost)/(TotalRevenue)) as OverheadCostPercentage
FROM(
SELECT COUNT(ROOMRESERVATION.Reservation_ID) as NoOfReservations, ROOM.RmCapacity, SUM(ROOM.HouseKeepingCost) as TotalHouseKeepingCost, 
SUM(ROOM.UtilitiesCost) as TotalUtilitiesCost, SUM(ROOM.Price) as TotalRevenue
FROM ROOMRESERVATION
INNER JOIN ROOM on ROOMRESERVATION.Room_No = ROOM.Room_No
GROUP BY ROOM.RmCapacity)
as subquery_7;


# 9 Identify fan camp utilization
SELECT TotalReservations, RmCapacity, TotalRoomsAvail, (TotalReservations/TotalRoomsAvail) as FanCampUtilization
FROM(
SELECT COUNT(Reservation_ID) as TotalReservations, ROOM.RmCapacity, COUNT(ROOM.Room_No) as TotalRoomsAvail
FROM ROOMRESERVATION
RIGHT JOIN ROOM ON ROOMRESERVATION.Room_No = ROOM.Room_No
GROUP BY ROOM.RmCapacity)
as subquery_8;





