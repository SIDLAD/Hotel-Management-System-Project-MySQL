drop database if exists Hotel_Mgmt; -- To ensure that if Hotel_Mgmt database already exists on the server, it is dropped as we are going to redefine the tables in it

create database Hotel_Mgmt;
use Hotel_Mgmt;

create table Guest (
EmailID varchar(50) NOT NULL,
Fname varchar(50) NOT NULL,
MInit char,
Lname varchar(50) NOT NULL,
GuestID INTEGER unsigned NOT NULL AUTO_INCREMENT,
PhoneNum NUMERIC constraint CHECK (length(PhoneNum)=10) NOT NULL, -- Phone Number has to be 10 digits long and not starting with a zero
Gender char NOT NULL,											  -- m for male and f for female, o for others; case insensitive
BDate date,
Address varchar(255) NOT NULL,
PRIMARY KEY (GuestID)
);

create table Staff (
EmailID varchar(50) NOT NULL,
Fname varchar(50) NOT NULL,
Minit char,
Lname varchar(50) NOT NULL,
StaffID INTEGER unsigned NOT NULL AUTO_INCREMENT,
PhoneNum numeric constraint CHECK (length(PhoneNum)=10) NOT NULL, -- Phone Number has to be 10 digits long and not starting with a zero
Gender char NOT NULL,											  -- m for male and f for female, o for others; case insensitive
BDate date,
Address varchar(255) NOT NULL,
Position varchar(30) DEFAULT "Unallocated", 					  -- If Position is null, then the staff member is an ex-employee and not currently working in the Hotel
PRIMARY KEY (StaffID)
);

create table RoomTypeDetails (
DailyCost FLOAT(10,2) NOT NULL constraint CHECK (DailyCost > 0),  -- by default also, float is to be 10 digits long and will have two decimal points
RoomCapacity INTEGER,											  -- number of members that can be accomodated at max in that type of room
RoomType varchar(20),
PRIMARY KEY (RoomType)
);

create table Room (
RoomStatus bool default false, 									   -- a false RoomStatus means that the room is unoccupied, and a true RoomStatus means that the room is occupied
RoomType varchar(20),
RoomNum INTEGER constraint CHECK (length(RoomNum)=4) NOT NULL,     -- a room number has to be 4 digits long
PRIMARY KEY (RoomNum),
FOREIGN KEY (RoomType) REFERENCES RoomTypeDetails(RoomType)
);

create table Reservation_Billing (
RoomNum INTEGER,
GuestID INTEGER unsigned,
BookingID INTEGER unsigned NOT NULL AUTO_INCREMENT,
CheckIn TIMESTAMP NOT NULL default current_timestamp,			   -- When the room is booked at the reception, CheckIn is auto-filled with the current date and time
CheckOut TIMESTAMP default NULL,								   -- a null CheckOut means that the Guest(s) have not yet checked out
MiscCharges FLOAT(10,2) default 0,								   -- Miscellaneous Charges that are not included in Room Service Charges or Room Charges
PRIMARY KEY (BookingID),
FOREIGN KEY (GuestID) REFERENCES Guest(GuestID),
FOREIGN KEY (RoomNum) REFERENCES Room(RoomNum)
);

create table RoomService (
ServiceDescription varchar(255) NOT NULL,							-- A short description or phrase on what type of Room Service is provided
StaffID INTEGER unsigned,
BookingID INTEGER unsigned,
RoomServiceID integer unsigned NOT NULL AUTO_INCREMENT,
ServiceCost FLOAT(10,2),
PRIMARY KEY (RoomServiceID),
FOREIGN KEY (StaffID) REFERENCES Staff(StaffID),
FOREIGN KEY (BookingID) REFERENCES Reservation_Billing(BookingID)
);

create view Reservation as 											-- Reservation view created from Reservation_Billing,Guest,Room tables
select BookingID, Fname, MInit, Lname, RoomNum, RoomType, 
CheckIn as CheckInTime,
CheckOut as CheckOutTime
from ((Guest NATURAL JOIN Reservation_Billing) NATURAL JOIN Room) NATURAL JOIN RoomTypeDetails;

create view Billing as												-- Billing view consists of derived attributes such as Room Service Cost, Room Cost and Total Cost
select Reservation_Billing.BookingID as BookingID,
(TIMESTAMPDIFF(DAY,CheckIn,CheckOut)+1) * DailyCost as RoomCharges,
COALESCE(SUM(ServiceCost),0) as RoomServiceCharges,
MiscCharges,
(TIMESTAMPDIFF(DAY,CheckIn,CheckOut)+1) * DailyCost + COALESCE(SUM(ServiceCost),0) + MiscCharges as TotalCharges
from ((Reservation_Billing NATURAL JOIN Room) NATURAL JOIN RoomTypeDetails) LEFT JOIN RoomService ON RoomService.BookingID = Reservation_Billing.BookingID
GROUP BY Reservation_Billing.BookingID;								 -- COALESCE function returns the first non-null parameter passed from left to right

create view EmptyRoomList as										 -- a view for quickly viewing the rooms that are empty, used by ADMINS
select roomnum, roomtype, dailycost
from (select * from room where roomstatus = false) as emptyrooms natural join roomtypedetails
order by dailycost desc, roomtype asc;

create view OccupiedRoomList as										-- a view for quickly viewing the rooms that are full, used by ADMINS
select roomnum, roomtype, dailycost
from (select * from room where roomstatus = true) as occupiedrooms natural join roomtypedetails
order by dailycost desc, roomtype asc;

-- all views and tables have been created above. Triggers, functions and procedures have been defined below

delimiter $$
create definer = root@localhost procedure insert_guest_details(in fname varchar(50),in minit char,in lname varchar(50),
in phonenum numeric,in gender char, in bdate date,in address varchar(255),in emailid varchar(50))
modifies sql data																	-- a procedure to insert new guest and details into database
begin
	INSERT INTO Guest (fname, minit, lname, phonenum, gender, bdate, address, emailid)
    VALUES (fname, minit, lname, phonenum, gender, bdate, address,emailid);
end $$
delimiter ;

delimiter $$
create definer = root@localhost procedure insert_staff_details(in fname varchar(50),in minit char,in lname varchar(50),
in phonenum numeric,in gender char, in bdate date,in address varchar(255),in emailid varchar(50),
in position varchar(30))
modifies sql data																	-- a procedure to insert new staff member and details into database
begin
	INSERT INTO Staff (fname, minit, lname, phonenum, gender, bdate, address,emailid,position)
    VALUES (fname, minit, lname, phonenum, gender, bdate, address,emailid,position);
end $$
delimiter ;

delimiter $$
create definer = root@localhost procedure update_guest_details(in gid integer,in fn varchar(50),in mi char,in ln varchar(50),
in pno numeric,in gndr char, in bd date,in addr varchar(255),in eid varchar(50))
modifies sql data																	-- a procedure to update existing guest's details into database
begin
	START TRANSACTION;
    
    if fn is NOT NULL
		then update Guest set fname = fn where Guest.GuestID = gid;
	end if;
	if mi is NOT NULL
		then update Guest set minit = mi where Guest.GuestID = gid;
	end if;
	if ln is NOT NULL
		then update Guest set lname = ln where Guest.GuestID = gid;
	end if;
	if pno is NOT NULL
		then update Guest set PhoneNum = pno where Guest.GuestID = gid;
	end if;
	if gndr is NOT NULL
		then update Guest set gender = gndr where Guest.GuestID = gid;
	end if;
	if bd is NOT NULL
		then update Guest set bdate = bd where Guest.GuestID = gid;
	end if;
	if addr is NOT NULL
		then update Guest set address = addr where Guest.GuestID = gid;
	end if;
	if eid is NOT NULL
		then update Guest set emailid = eid where Guest.GuestID = gid;
	end if;
    
    COMMIT;
end $$
delimiter ;


-- for the following update functions, null will be passed into the fields that do not have to be changed

delimiter $$
create definer = root@localhost procedure update_staff_details(in sid integer,in fn varchar(50),in mi char,in ln varchar(50),
in pno numeric,in gndr char, in bd date,in addr varchar(255),in eid varchar(50),
in pos varchar(30))
modifies sql data																	-- a procedure to update existing staff member's details into database
begin
	START TRANSACTION;
    
    if fn is NOT NULL
		then update Staff set fname = fn where Staff.StaffID = sid;
	end if;
	if mi is NOT NULL
		then update Staff set minit = mi where Staff.StaffID = sid;
	end if;
	if ln is NOT NULL
		then update Staff set lname = ln where Staff.StaffID = sid;
	end if;
	if pno is NOT NULL
		then update Staff set PhoneNum = pno where Staff.StaffID = sid;
	end if;
	if gndr is NOT NULL
		then update Staff set gender = gndr where Staff.StaffID = sid;
	end if;
	if bd is NOT NULL
		then update Staff set bdate = bd where Staff.StaffID = sid;
	end if;
	if addr is NOT NULL
		then update Staff set address = addr where Staff.StaffID = sid;
	end if;
	if eid is NOT NULL
		then update Staff set emailid = eid where Staff.StaffID = sid;
	end if;
    if pos is NOT NULL
		then update Staff set position = pos where Staff.StaffID = sid;
	end if;
    
    COMMIT;
end $$
delimiter ;

delimiter $$
create definer = root@localhost trigger on_checkout											-- this trigger is executed when an update on the reservation_billing table is done directly or indirectly through a view, and it updates the room status based on the checkout values
after update on reservation_billing
for each row
begin
	update room set roomstatus = true;
    update room natural join reservation_billing set roomstatus = false where checkout is null;
end $$
delimiter ;

delimiter $$
create definer = root@localhost procedure check_in_reservation(in rno integer, in gid integer)
modifies sql data																	-- a procedure to create reservation for a guest
begin
	START TRANSACTION;
    
	select exists(select * from room where rno = Roomnum) into @isValidRoom;
	select NOT RoomStatus into @isEmptyRoom from room where RoomNum = rno;
    
	if (@isValidRoom is FALSE)
		THEN select "Room number does not exist, please check the list of empty rooms from the EmptyRoomList view" as ProcedureStatus;
    elseif (@isEmptyRoom is FALSE)
		THEN select "Room is not empty, please check the list of empty rooms from the EmptyRoomList view (or call ADMIN_viewemptyrooms)" as ProcedureStatus;
	elseif (@isValidRoom is TRUE AND @isEmptyRoom is TRUE)
		THEN insert into reservation_billing (RoomNum,GuestID,MiscCharges) values (rno,gid,0);
		update room set roomstatus = true where RoomNum = rno;
	END IF;
    
    COMMIT;
end$$
delimiter ;

delimiter $$
create definer = root@localhost procedure check_out_generate_bill(in bid INTEGER)
modifies sql data																	-- this procedure is called when the guest is checking out of the hotel. The bill is generated, and the on_check_out trigger is automatically invoked
begin
	START TRANSACTION;
    
    select exists(select * from reservation_billing where bookingid = bid) into @doesExist;
	select checkout IS NULL from reservation_billing where bookingid = bid into @isValid;
    
	IF @isValid is true AND @doesExist is true
		THEN update reservation_billing set checkout = current_timestamp() where bookingid = bid;
		select * from billing where bookingid = bid;
	ELSE
		select "Invalid BookingID or Room already checked out and billed" as ProcedureStatus;
    END IF;
    
    COMMIT;
end$$
delimiter ;

delimiter $$
create definer = root@localhost procedure cancel_booking(in bid INTEGER)							-- a procedure to cancel the booking created, maybe because the guest decided to not stay soon after on-spot booking 
modifies sql data
begin
	START transaction;
	
    select RoomNum from reservation_billing where BookingID = bid into @roomnumber;
    select CheckOut IS NULL from reservation_billing where BookingID = bid into @changeroomstatustofalse;
    if @changeroomstatustofalse
		THEN update Room set RoomStatus = false where RoomNum = @roomnumber; -- if room is currently occupied and then cancelled then change room status to false,
																	   -- otherwise no change to room status
    END IF;
    delete from reservation_billing where BookingID = bid;
    
    COMMIT;
end$$
delimiter ;

delimiter $$
create definer = root@localhost procedure provide_service(in sid integer, in bid integer, in servicedescription varchar(255), in cost int) 
modifies sql data																	-- RoomService entity is created and a staff is allocated to it
begin
	START TRANSACTION;
    select position from Staff where StaffID = sid into @staffmember;
    
    if exists(select * from Staff where StaffID = sid) and @staffmember is not null
		then insert into roomservice (servicedescription, staffid, bookingid, servicecost) values (servicedescription, sid, bid, cost);
	else
		select "Staff member does not exist or is currently not working in the hotel" as ProcedureStatus;
	end if;
    
    COMMIT;
end $$
delimiter ;

delimiter $$
create definer = root@localhost procedure add_to_misc_charges(in bid integer, in addtn float(10,2))
modifies sql data															-- procedure adds to miscellaneous charges in the billing
begin
	START TRANSACTION;
    
    if exists(select CheckOut from reservation_billing where BookingID = bid) and (select CheckOut from reservation_billing where BookingID = bid) is NULL
		THEN update reservation_billing set MiscCharges = MiscCharges + addtn where BookingID = bid;
	else
		select "Cannot add to MiscCharges as Reservation does not exist or Billing is already done" as ProcedureStatus;
    END IF;
    
    COMMIT;
end$$
delimiter ;

delimiter $$
create definer = root@localhost procedure ADMIN_viewemptyrooms()
reads sql data
begin
	select * from emptyroomlist;
end$$
delimiter ;

delimiter $$
create definer = root@localhost procedure ADMIN_viewoccupiedrooms()
reads sql data
begin
	select * from occupiedroomlist;
end$$
delimiter ;

delimiter $$
create definer = root@localhost function ADMIN_revenuefromtype(rtype varchar(20))
returns float (10,2)											
reads sql data														-- this function returns the total revenues (inclusive of room service charges and misc charges) that have been generated for a given type of room, PROVIDED THAT THE GUEST HAS ALREADY CHECKED OUT
begin
	select coalesce(sum(totalcharges),0) from billing natural join reservation natural join room where Roomtype = rtype and totalcharges is not null into @totalrevenue;
    return @totalrevenue;
end$$
delimiter ;

-- all procedures, functions and triggers have been defined above

insert into roomtypedetails (DailyCost,RoomCapacity,RoomType)
values (2500,2,'standard') ,(3500,2,'deluxe') ,(5000,4,'premium') ,(7000,6,'suite');

insert into room (RoomStatus,RoomType,RoomNum)
values (false,'standard',1001),(false,'standard',1002),(false,'deluxe',1003),(false,'premium',1004),(false,'suite',1005),
	   (false,'standard',2001),(false,'standard',2002),(false,'deluxe',2003),(false,'premium',2004),(false,'suite',2005),
       (false,'standard',3001),(false,'standard',3002),(false,'deluxe',3003),(false,'premium',3004),(false,'suite',3005),
       (false,'standard',4001),(false,'standard',4002),(false,'deluxe',4003),(false,'premium',4004),(false,'suite',4005),
       (false,'standard',5001),(false,'standard',5002),(false,'deluxe',5003),(false,'premium',5004),(false,'suite',5005);

call insert_guest_details('Rijul', '', 'Bassamboo', 9811234566, 'm', '2002-10-07', 'Karol Bagh, New Delhi', 'rb@gmail.com');
call insert_guest_details('Siddharth', 'S', 'Shah', 9811234346, 'm', '2001-08-30', 'Bengaluru', 'ss@gmail.com');
call insert_guest_details('Amandeep', '', 'Singh', 9814444566, 'm', '2002-06-05', 'Moradabad, UP', 'as@gmail.com');
call insert_guest_details('Rakshit', '', 'Jain', 9811589566, 'm', '2003-02-26', 'DEF,FHG', 'rj@gmail.com');
call insert_guest_details('Raghav', '', 'Kashyap', 9809034566, 'm', '2003-07-04', 'abc,xyz', 'rk@gmail.com');
call insert_guest_details('Aadeesh', '', 'Garg', 9811123566, 'm', '2002-12-07', 'Karol Bagh, New Delhi', 'ag@gmail.com');
call insert_guest_details('Aryan', '', 'Bakshi', 9811909566, 'm', '2002-11-07', 'Ambala, Haryana', 'ab@gmail.com');
call insert_guest_details('Aryan', '', 'Wadhwa', 9811000566, 'm', '2002-10-27', 'GK1, South Delhi', 'aw@gmail.com');
call insert_guest_details('Aakash', '', 'Bhagat', 9815554566, 'm', '2002-10-17', 'Rohini, Delhi', 'ab@gmail.com');
call insert_guest_details('Kunal', 'S', 'Dhingra', 9887834566, 'm', '2002-10-27', 'Noida,UP', 'ksd@gmail.com');

call insert_staff_details('ABC', 'H', 'ZXY', 9876543210, 'F', '1990-08-02', 'DEF,JHK', 'ABC@GMAIL.COM', 'JANITOR');
call insert_staff_details('NWL', 'R', 'BBM', 1270936062, 'm', '1996-07-12', 'SCD,XRJ', 'MOW@GMAIL.COM', 'JANITOR');
call insert_staff_details('FRX', 'S', 'JYB', 9478450361, 'm', '1990-12-16', 'XXP,KLO', 'REL@GMAIL.COM', 'MANAGER');
call insert_staff_details('LNM', 'P', 'APQ', 4307868843, 'f', '1991-11-16', 'WHS,QMG', 'BBU@GMAIL.COM', 'ATTENDANT');
call insert_staff_details('QCL', 'J', 'JIV', 6106159490, 'f', '1999-06-11', 'JPT,NSN', 'FWZ@GMAIL.COM', 'UNALLOCATED');
call insert_staff_details('QFJ', 'M', 'AFA', 9088509638, 'm', '1995-03-19', 'SAQ,XWP', 'QCA@GMAIL.COM', 'ATTENDANT');
call insert_staff_details('CEH', 'C', 'HZV', 6217857418, 'f', '1995-01-18', 'ITZ,YXA', 'CBH@GMAIL.COM', 'JANITOR');
call insert_staff_details('HKI', 'C', 'QCO', 7764303092, 'm', '1995-10-14', 'QVK,UYT', 'DLC@GMAIL.COM', 'SECURITY');
call insert_staff_details('GDE', 'W', 'HTA', 2105110850, 'm', '1996-12-18', 'OQM,SBO', 'AGU@GMAIL.COM', 'CHEF');
call insert_staff_details('WNN', 'Y', 'QXN', 9340391969, 'm', '1993-10-16', 'UGU,UMO', 'QCD@GMAIL.COM', 'CHEF');
call insert_staff_details('RUB', 'E', 'TOK', 9602761321, 'f', '1995-11-19', 'LMN,DQT', 'UKW@GMAIL.COM', 'SECURITY');

call check_in_reservation(1005, 1);
call check_in_reservation(1003, 4);
call check_in_reservation(3001, 5);
call check_in_reservation(4001, 6);
call check_in_reservation(1002, 7);
call check_in_reservation(2002, 8);
call check_in_reservation(3003, 9);
call check_in_reservation(2004, 10);
call check_in_reservation(1001, 3);
call check_in_reservation(5005, 2);

select * from reservation_billing; -- displays the reservation_billing details immediately after the above reservations are created

call cancel_booking(10);			-- Reservations having booking ids 9 and 10
call cancel_booking(9);				--  are cancelled as the guests decide not to stay in the hotel after all

select * from reservation_billing; -- displays the reservations after the above two have been cancelled

call provide_service(1, 4, 'Cleaning Room', 190);
call provide_service(1, 8, 'Cleaning Room', 190);
call provide_service(1, 1, 'Cleaning Room', 190);
call provide_service(3, 2, 'Cleaning Room', 190);
call provide_service(3, 2, 'Cleaning Room', 190);
call provide_service(3, 6,'Cleaning Room', 190);
call provide_service(7, 1, 'Food & Beverages', 1900);
call provide_service(7, 8, 'Food & Beverages', 1400);
call provide_service(7, 2, 'Food & Beverages', 1300);
call provide_service(7, 1, 'Food & Beverages', 1800);
call provide_service(1, 5, 'Food & Beverages', 1200);

-- let us display all views and tables once after having populated the room service table

select * from room;
select * from roomservice;
select * from guest;
select * from staff;
select * from reservation_billing;
select * from roomtypedetails;
select * from billing;
select * from emptyroomlist;
select * from occupiedroomlist;
select * from reservation;

call ADMIN_viewoccupiedrooms(); -- ADMIN wishes to know which rooms are occupied and their corresponding types
call ADMIN_viewemptyrooms();	-- ADMIN wishes to know which rooms are empty and their corresponding types

call update_guest_details(2, null, null, 'Gupta', 9916161616, null, null, null, null);
call update_guest_details(3, null,null,null, null,null,null, 'asd,gfd', null);

select * from guest;	-- details of all guests after the above two decide to update their details ie. their surname (maybe got newly married), their Phone number, and the second one changing his address

call update_staff_details(2, null, null, null, 9916161616, null, null, null, null,null);
call update_staff_details(3, null,null,null, null,null,null, 'asd,xyt', null,'CEO');

select * from staff;	-- details of all staff members after the above two decide to update their details, and the manager gets promoted to CEO!

call add_to_misc_charges(5, 1000);
call add_to_misc_charges(3, 2000);
call add_to_misc_charges(2, 1300);
call add_to_misc_charges(1, 3400);
call add_to_misc_charges(4, 2500);

select * from billing; 	-- billing details after addition of misc charges

call check_out_generate_bill(1);
call check_out_generate_bill(3);
call check_out_generate_bill(5);
call check_out_generate_bill(7);
call check_out_generate_bill(8);


-- the above guests are satisfied with their stay and wish to leave

select * from billing; -- billing details are generated and printed on the screen for all guests. Total Charges have only been computed for the ones that have checked out; for the others it remains null

select ADMIN_revenuefromtype('suite') as RevenueFromSuite,ADMIN_revenuefromtype('premium') as RevenueFromPremium,ADMIN_revenuefromtype('standard') as RevenueFromStandard,ADMIN_revenuefromtype('deluxe') as RevenueFromDeluxe;
-- and finally, the ADMINS wish to know the Revenue generated from each type of Room so that they can plan their future projects