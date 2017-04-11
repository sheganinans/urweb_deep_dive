loop () {    
    ./$1 -q &
    notifyloop $1 ./loop.sh $1
}

loop step7.exe
