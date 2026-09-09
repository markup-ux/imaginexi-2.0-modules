-- Imagine XI 2.0: auction house gift locker.
-- Sellers are not mailed gil. Catalog is only items players currently have listed.
-- Revert with ixi20_REVERT.sql on xidb_ixi20 only.

DELETE FROM `auction_house` WHERE `buyer_name` IS NOT NULL OR `sale` <> 0 OR `seller` = 0;
DELETE FROM `auction_house_items`;
INSERT IGNORE INTO `auction_house_items` (`itemid`)
SELECT DISTINCT `itemid` FROM `auction_house` WHERE `buyer_name` IS NULL AND `sale` = 0 AND `seller` <> 0;
UPDATE `auction_house` SET `price` = 0 WHERE `buyer_name` IS NULL AND `sale` = 0 AND `price` <> 0;

DROP TRIGGER IF EXISTS auction_house_buy;
DELIMITER $$
CREATE TRIGGER auction_house_buy
    BEFORE UPDATE ON auction_house
    FOR EACH ROW
BEGIN
    -- Gift AH: do not insert gil into the seller delivery box.
    IF FALSE THEN SET NEW.sale = NEW.sale; END IF;
END $$
DELIMITER ;
