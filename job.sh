make cleanall
make
if [ $? -eq 0 ];
  then
  echo "Launch to server"
  qsub launch.pbs
  make extract
fi
