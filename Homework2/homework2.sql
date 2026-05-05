Create table accounts (
    account_id serial primary key,
    owner_name varchar(100),
    balance numeric(10, 2)
);

insert into accounts(owner_name, balance)
values ('A', 500.00), ('B', 300.00);

-- Bắt đầu transaction bằng BEGIN;
begin;
-- Chuyển 100 từ tài khoản A sang tài khoản B
update accounts set balance = balance - 100 
where account_id = 1 and balance >= 100;

-- Kiểm tra nếu tài khoản A đã trừ tiền thành công, sau đó cộng tiền vào tài khoản B
update accounts set balance = balance + 100
where account_id = 2 and (
    select balance
    from accounts
    where account_id = 1
) balance >= 100;
-- Kết thúc bằng COMMIT;
Commit;

-- Kiem tra ket qua
select * from accounts;

-- Them du lieu mau
insert into accounts(owner_name, balance) values ('C', 0), ('D', 100.00);
-- Mô phỏng lỗi và Rollback
begin;
update accounts set balance = balance - 100
where account_id = 3 and balance >= 100;

update accounts set balance = balance + 100
where account_id = 4 and (
    select balance
    from accounts
    where account_id = 3
) >= 100;
-- Rollback khi có lỗi xảy ra
commit;
ROLLBACK;
-- Kiem tra ket qua
select * from accounts;