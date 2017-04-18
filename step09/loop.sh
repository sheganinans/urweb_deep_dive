killall $1.exe
psql -f dropall.sql test
psql -f $1.sql test
./$1.exe -q &
touch watchfile
