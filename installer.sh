dirs=`find $PWD -depth 1 -type d -not -name '.git'`

for dir in $dirs;
do
  echo 📁 $dir
  #sh $dir/installer.sh
done

# Macの再起動
read -p "Reboot system? (y/n) :  " restart_env
if [ "$restart_env" = "y" ]; then
  sudo shutdown -r now
fi