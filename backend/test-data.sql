-- اضافه کردن مشتری تست با شماره تلفن
INSERT INTO customers (id, name, phone, phone_numbers, address, is_active) 
VALUES (
  UUID(),
  'خلیلی',
  '09123456789',
  JSON_ARRAY('09123456789', '12345678', '02112345678'),
  'تهران، میدان آزادی',
  1
) ON DUPLICATE KEY UPDATE 
  phone_numbers = JSON_ARRAY('09123456789', '12345678', '02112345678');

-- بررسی
SELECT id, name, phone_numbers FROM customers WHERE phone_numbers IS NOT NULL;
