```sql
SELECT COUNT(*) FROM "wsi-glue-db"."wsi-glue-table" WHERE year='2023' and month='09' and "date"='04';
SELECT COUNT(*), hour FROM "wsi-glue-db"."wsi-glue-table" WHERE year='2023' and month='09' and "date"='04' group by hour;
```
