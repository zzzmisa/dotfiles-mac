dirs=`find $PWD -depth 1 -type d -not -name '.git'`

for dir in $dirs;
do
  echo 📁 $dir
  sh $dir/installer.sh
done