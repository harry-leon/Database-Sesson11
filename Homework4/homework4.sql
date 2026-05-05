drop table if exists transactions;
drop table if exists accounts;

create table accounts (
  account_id serial primary key,
  customer_name varchar(100) not null,
  balance numeric(12, 2) not null check (balance >= 0)
);

create table transactions (
  trans_id serial primary key,
  account_id int not null references accounts(account_id),
  amount numeric(12, 2) not null check (amount > 0),
  trans_type varchar(20) not null,
  created_at timestamp not null default now()
);

-- du lieu mau
insert into accounts (customer_name, balance)
values
  ('nguyen van a', 1000.00),
  ('tran thi b', 500.00);

select * from accounts order by account_id;

-- ============================================================
-- 1) transaction rut tien thanh cong (begin -> commit)
-- rut 200 tu tai khoan id = 1
-- ============================================================
begin;

-- khoa dong tai khoan trong luc xu ly
select balance
from accounts
where account_id = 1
for update;

-- tru tien (chi tru neu du so du)
update accounts
set balance = balance - 200.00
where account_id = 1
  and balance >= 200.00;

-- neu update khong tru duoc (0 rows) thi dung rollback bang tay
-- (trong psql co the xem ket qua "update 0")

insert into transactions (account_id, amount, trans_type)
values (1, 200.00, 'withdraw');

commit;

-- kiem tra ket qua
select * from accounts where account_id = 1;
select * from transactions where account_id = 1 order by trans_id desc;

-- ============================================================
-- 2) mo phong loi va rollback
-- co y ghi log sai account_id (999) de gay loi fk
-- ky vong: sau rollback, so du khong doi va khong co log moi
-- ============================================================
select balance as balance_before_fail
from accounts
where account_id = 1;

begin;

select balance
from accounts
where account_id = 1
for update;

update accounts
set balance = balance - 100.00
where account_id = 1
  and balance >= 100.00;

-- dong nay se fail (fk violation) -> transaction bi abort, can rollback
insert into transactions (account_id, amount, trans_type)
values (999, 100.00, 'withdraw');

-- neu ban chay tren ide ma no dung ngay khi gap loi, hay chay rieng lenh rollback ben duoi
rollback;

select balance as balance_after_fail
from accounts
where account_id = 1;

select *
from transactions
where account_id = 1
order by trans_id desc;

-- ============================================================
-- 3) kiem tra tinh toan ven du lieu
-- chay rut tien nhieu lan: moi log phai tuong ung 1 lan giam balance
-- ============================================================
begin;
select balance from accounts where account_id = 1 for update;
update accounts set balance = balance - 50.00 where account_id = 1 and balance >= 50.00;
insert into transactions (account_id, amount, trans_type) values (1, 50.00, 'withdraw');
commit;

begin;
select balance from accounts where account_id = 1 for update;
update accounts set balance = balance - 25.00 where account_id = 1 and balance >= 25.00;
insert into transactions (account_id, amount, trans_type) values (1, 25.00, 'withdraw');
commit;

-- doi chieu: so tien da tru = tong amount cua transactions
select
  a.account_id,
  a.customer_name,
  a.balance as current_balance,
  1000.00 - a.balance as deducted_from_start,
  coalesce(sum(t.amount), 0) as sum_logged_withdraw
from accounts a
left join transactions t
  on t.account_id = a.account_id
  and t.trans_type = 'withdraw'
where a.account_id = 1
group by a.account_id, a.customer_name, a.balance;
