CREATE TABLE uw_Step14_counters(uw_id int8 NOT NULL, uw_count int8 NOT NULL, 
                                 uw_show bool NOT NULL,
 PRIMARY KEY (uw_id),
  CONSTRAINT uw_Step14_counters_KeyRangeLower CHECK (uw_id > 0::int8),
                                                                      
   CONSTRAINT uw_Step14_counters_KeyRangeUpper CHECK (uw_id <= 500::int8)
 );
 
 CREATE TABLE uw_Step14_prevCounters(uw_id int8 NOT NULL, 
                                      uw_count int8 NOT NULL, 
                                      uw_show bool NOT NULL,
  PRIMARY KEY (uw_id),
   CONSTRAINT uw_Step14_prevCounters_Keys
    FOREIGN KEY (uw_id) REFERENCES uw_Step14_counters (uw_id)
  );
  
  CREATE TABLE uw_Step14_limits(uw_mods int8 NOT NULL, uw_clears int8 NOT NULL
   
   );
   
   CREATE TABLE uw_Step14_id_pool(uw_id int8 NOT NULL,
    CONSTRAINT uw_Step14_id_pool_RefCounter
     FOREIGN KEY (uw_id) REFERENCES uw_Step14_counters (uw_id),
                                                               
     CONSTRAINT uw_Step14_id_pool_MaxId CHECK (uw_id <= 500::int8)
    );
    
    CREATE TABLE uw_Step14_users(uw_client int4 NOT NULL, uw_chan int8 NOT NULL,
     PRIMARY KEY (uw_client)
      
     );
     
     