CREATE SEQUENCE uw_Step10_counter_seq;
 
 CREATE TABLE uw_Step10_counters(uw_id int8 NOT NULL, uw_count int8 NOT NULL,
  PRIMARY KEY (uw_id)
   
  );
  
  CREATE TABLE uw_Step10_users(uw_client int4 NOT NULL, uw_chan int8 NOT NULL,
   PRIMARY KEY (uw_client)
    
   );
   
   