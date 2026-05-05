Create table flights (
    flight_id serial primary key, 
    flight_name varchar(100),
    available_seats int
);

create table bookings (
    booking_id serial primary key,
    flight_id int references flights(flight_id),
    customer_name varchar(100)
);

insert into flights (flight_name, available_seats)
values('VN123', 3), ('VN456', 2);

-- Bắt đầu transaction bằng BEGIN;
begin;
-- Giảm số ghế của chuyến bay 'VN123' đi 1
update flights set available_seats = available_seats -1
where flight_id = 1 and available_seats > 0;
-- Thêm bản ghi đặt vé của khách hàng 'Nguyen Van A'
insert into bookings(flight_id, customer_name) 
values (1, 'Nguyen Van A');
-- Kết thúc bằng COMMIT;
Commit;

-- Kiem tra ket qua
SELECT * FROM flights;
SELECT * FROM bookings WHERE flight_id = 1 ORDER BY booking_id DESC;

-- Mô phỏng lỗi và Rollback
begin;
update flights set available_seats = available_seats -1
where flight_name = 'VN123' and available_seats > 0;
-- Thêm bản ghi đặt vé của khách hàng 'Nguyen Van A'
insert into bookings(flight_id, customer_name) 
values (123, 'Nguyen Van A');
ROLLBACK;


-- Kiem tra ket qua
SELECT * FROM flights;
SELECT * FROM bookings WHERE flight_id = 1:

