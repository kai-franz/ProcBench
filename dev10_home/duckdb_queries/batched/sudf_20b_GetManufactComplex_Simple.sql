DROP TABLE IF EXISTS state;
CREATE TEMPORARY TABLE state
(
    item         INT,
    man          CHAR(50),
    cnt1         INT,
    cnt2         INT,
    p            BOOLEAN,
    multiplicity INT,
    result       CHAR(50),
    returned     BOOLEAN DEFAULT FALSE
);
INSERT INTO state(item, multiplicity)
SELECT ws_item_sk, COUNT(*) AS multiplicity
  FROM (SELECT ws_item_sk, COUNT(*) cnt FROM web_sales GROUP BY ws_item_sk ORDER BY cnt DESC, ws_item_sk LIMIT 25000) t1
 GROUP BY ws_item_sk;

UPDATE state
   SET man = ''
 WHERE NOT returned;
UPDATE state
   SET cnt1 = (SELECT COUNT(*)
                 FROM store_sales_history,
                      date_dim
                WHERE ss_item_sk = item
                  AND d_date_sk = ss_sold_date_sk
                  AND d_year = 2003)
 WHERE NOT returned;
UPDATE state
   SET cnt2 = (SELECT COUNT(*)
                 FROM catalog_sales_history,
                      date_dim
                WHERE cs_item_sk = item
                  AND d_date_sk = cs_sold_date_sk
                  AND d_year = 2003)
 WHERE NOT returned;

UPDATE state
   SET p = COALESCE(cnt1 > 0 AND cnt2 > 0, FALSE)
 WHERE NOT returned;

UPDATE state
   SET man = (SELECT i_manufact FROM item WHERE i_item_sk = state.item)
 WHERE NOT returned
   AND p;

UPDATE state
   SET result   = man,
       returned = TRUE
 WHERE NOT returned
   AND p;

UPDATE state
   SET man = 'outdated item'
 WHERE NOT returned
   AND NOT p;

UPDATE state
   SET result   = man,
       returned = TRUE
 WHERE NOT returned
   AND NOT p;

SELECT s.item
  FROM state AS s, LATERAL UNNEST(GENERATE_SERIES(1, s.multiplicity))
 WHERE s.result = 'oughtn st';
