(echo 1; sleep 1;
echo 2; sleep 1;
echo 3; sleep 1) &

pid=$!
start=$(date +%s)
while ps aux | awk '{print $2 }' | grep -q $pid 2> /dev/null; do
  [ $(expr $(date +%s) - $start) -gt 1 ] && (kill -9 $pid; exit 1)
  sleep 1
done
wait $pid
echo $?
