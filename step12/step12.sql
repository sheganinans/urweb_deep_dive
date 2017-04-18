CREATE SEQUENCE uw_Step12_counter_seq;
 
 CREATE TABLE uw_Step12_counters(uw_id int8 NOT NULL, uw_count int8 NOT NULL,
  PRIMARY KEY (uw_id)
   
  );
  
  CREATE TABLE uw_Step12_changed(uw_change bool NOT NULL
   );
   
   CREATE TABLE uw_Step12_users(uw_client int4 NOT NULL, uw_chan int8 NOT NULL,
    PRIMARY KEY (uw_client)
     
    );
    
    