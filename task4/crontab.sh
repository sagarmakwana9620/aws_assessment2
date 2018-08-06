touch crontab.txt
echo "enter the minute time you want to start the instance"
read startm
echo "enter the hour time you want to start the instance"
read starth
echo "$startm $starth * * * sh start.sh" > crontab.txt
echo "enter the minute time you want to stop the instance"
read stopm
echo "enter the hour time you want to stop the instance"
read stoph
echo "$stopm $stoph * * * sh stop.sh" >> crontab.txt
crontab crontab.txt