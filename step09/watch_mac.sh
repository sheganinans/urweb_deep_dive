loop () {    
    ./$1.exe -q &
    notifyloop $1.exe ./loop.sh $1
}

loop step9
