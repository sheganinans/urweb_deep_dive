killall $1
psql -f dropall.sql test
psql -f step7.sql test
./$1 -q &
touch watchfile
