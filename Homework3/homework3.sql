CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    stock INT,
    price NUMERIC(10,2)
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    total_amount NUMERIC(10,2),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT,
    subtotal NUMERIC(10,2)
);

INSERT INTO products (product_id, product_name, price, stock_qty) VALUES
(1, 'Product 1', 100000, 10),
(2, 'Product 2',  50000,  5);

DELIMITER $$
CREATE PROCEDURE sp_place_order(IN p_customer_name VARCHAR(100))
BEGIN
  DECLARE v_order_id INT;
  DECLARE v_total DECIMAL(12, 2) DEFAULT 0;
  DECLARE v_stock_1 INT;
  DECLARE v_stock_2 INT;
  DECLARE v_price_1 DECIMAL(12, 2);
  DECLARE v_price_2 DECIMAL(12, 2);

  START TRANSACTION;

  -- Khoa 2 dong san pham de tranh tranh chap ton kho (concurrency)
  SELECT stock_qty, price INTO v_stock_1, v_price_1
  FROM products
  WHERE product_id = 1
  FOR UPDATE;

  SELECT stock_qty, price INTO v_stock_2, v_price_2
  FROM products
  WHERE product_id = 2
  FOR UPDATE;

  -- Kiem tra ton kho
  IF v_stock_1 IS NULL OR v_stock_2 IS NULL THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found';
  END IF;

  IF v_stock_1 < 2 OR v_stock_2 < 1 THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Out of stock';
  END IF;

  -- Tru ton kho
  UPDATE products SET stock_qty = stock_qty - 2 WHERE product_id = 1;
  UPDATE products SET stock_qty = stock_qty - 1 WHERE product_id = 2;

  -- Tao order
  INSERT INTO orders (customer_name, total_amount) VALUES (p_customer_name, 0);
  SET v_order_id = LAST_INSERT_ID();

  -- Them order items
  INSERT INTO order_items (order_id, product_id, quantity, unit_price, line_total)
  VALUES
    (v_order_id, 1, 2, v_price_1, v_price_1 * 2),
    (v_order_id, 2, 1, v_price_2, v_price_2 * 1);

  -- Tinh tong tien va cap nhat
  SELECT COALESCE(SUM(line_total), 0) INTO v_total
  FROM order_items
  WHERE order_id = v_order_id;

  UPDATE orders SET total_amount = v_total WHERE order_id = v_order_id;

  COMMIT;

  -- Tra ket qua nhanh
  SELECT v_order_id AS order_id, v_total AS total_amount;
END$$
DELIMITER ;

-- Chay transaction dat hang thanh cong
CALL sp_place_order('Nguyen Van A');

-- Kiem tra ket qua (sau COMMIT)
SELECT * FROM products ORDER BY product_id;
SELECT * FROM orders ORDER BY order_id DESC;
SELECT * FROM order_items ORDER BY order_item_id DESC;

-- ============================================================
-- 4) Mo phong loi (set stock = 0) va chay lai transaction
-- ============================================================
UPDATE products SET stock_qty = 0 WHERE product_id = 2;
SELECT * FROM products ORDER BY product_id;

-- Ky vong: procedure se bao loi "Out of stock" va ROLLBACK
-- Luu y: query nay se ERROR (do SIGNAL). Sau do, kiem tra du lieu.
CALL sp_place_order('Nguyen Van A');

-- Kiem tra: ton kho KHONG bi tru them, orders/order_items KHONG co ban ghi moi
SELECT * FROM products ORDER BY product_id;
SELECT * FROM orders ORDER BY order_id DESC;
SELECT * FROM order_items ORDER BY order_item_id DESC;

-- ============================================================
-- 5) So sanh khi KHONG dung Transaction (de thay tac hai)
-- ============================================================
-- Reset ton kho de demo
UPDATE products SET stock_qty = 1 WHERE product_id = 2; -- KHONG du de mua (can 1 thi du, nhung minh se tao loi FK o buoc insert)
SELECT * FROM products ORDER BY product_id;

-- KHONG dung transaction: tru ton kho truoc, sau do insert order_items sai -> ton kho bi tru nhung order fail => du lieu sai lech
-- (Hay chay tung lenh, vi khi gap loi insert, tool se dung script)
UPDATE products SET stock_qty = stock_qty - 1 WHERE product_id = 2;

INSERT INTO orders (customer_name, total_amount) VALUES ('Nguyen Van A (no tx)', 0);
SET @order_id_no_tx = LAST_INSERT_ID();

-- Co y nhap sai product_id = 999 -> loi FK
INSERT INTO order_items (order_id, product_id, quantity, unit_price, line_total)
VALUES (@order_id_no_tx, 999, 1, 1, 1);

-- Kiem tra: stock_qty da bi tru, nhung order_items khong them duoc (data bi sai)
SELECT * FROM products ORDER BY product_id;
SELECT * FROM orders ORDER BY order_id DESC;
SELECT * FROM order_items ORDER BY order_item_id DESC;
