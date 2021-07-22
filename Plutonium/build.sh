#! /bin/bash

wait-for-device() {
until adb shell true
do
sleep 1
done
}

#replace $MY_CROSS_COMPILE below with path to your cross compiler
#example:
#export CROSS_COMPILE=/home/user/Desktop/arm-eabi-8.x/bin/arm-eabi-;
export CROSS_COMPILE=$MY_CROSS_COMPILE;
export ARCH=arm && SUBARCH=arm;
#replace 4 with number of threads your host CPU has
export CORECOUNT=4;

echo "PlutoniumKernel build script.";
echo ;
echo "Press:";
echo "c to compile";
echo "m to open menuconfig";
echo "p to pack 'ready to flash' zip (compile first)";
echo "f to test image using fastboot";
echo "a to flash kernel zip using adb (twrp only)";
echo "q to exit";
source=$(pwd)/..;
here=$(pwd);
zipsrc=$here/.zip;
zipout=$here/zip;
imgout=$here/imgraw;

if [ -d $zipout ]; then
  rm $zipout/* 2&> /dev/null;
else
  mkdir $zipout;
fi
if [ -d $imgout ]; then
  rm $imgout/* 2&> /dev/null;
else
  mkdir $imgout;
fi

if [ -f $zipsrc/zImage-dtb ]; then
  rm $zipsrc/zImage-dtb 2&> /dev/null;
fi;


while [[ $input != "q" ]]; do
  input=" ";
  read -N 1 input;
  clear;
  if [[ $input == "c" ]]; then
    clear;
    cd $source;
    make -j$CORECOUNT;
    cd $here;
    rm $imgout/* 2&> /dev/null;
    rm -rf $zipsrc/temp 2&> /dev/null;
    rm $zipout/* 2&> /dev/null;
    cp $source/arch/arm/boot/zImage-dtb $imgout/;
  elif [[ $input == "m" ]]; then
    clear;
    cd $source;
    make menuconfig;
    cd $here;
  elif [[ $input == "p" ]]; then
    if [ -f $imgout/zImage-dtb ]; then
      rm -rf $zipsrc/temp 2&> /dev/null;
      rm $zipout/* 2&> /dev/null;
      cd $zipsrc;
      unzip -qq template.zip -d temp;
      cd temp;
      cp $imgout/zImage-dtb ./;
      zip -r PlutoniumKernel.zip ./* 2&> /dev/null;
      cd $here;
      mv $zipsrc/temp/PlutoniumKernel.zip $zipout/;
      rm -rf $zipsrc/temp 2&> /dev/null;
    else
      echo "You must compile first";
      continue;
    fi

  elif [[ $input == "f" ]]; then
    if [ -f $imgout/zImage-dtb ]; then
      clear;
      adb wait-for-device;
      adb reboot bootloader;
      fastboot boot $imgout/zImage-dtb;
    else
      echo "You must compile first";
      continue;
    fi
  elif [[ $input == "a" ]]; then
      if [ -f $zipout/PlutoniumKernel.zip ]; then
        clear;
        echo "Waiting for device...";
        wait-for-device 2&> /dev/null;
        echo "Device found, flashing...";
        adb reboot recovery;
        wait-for-device 2&> /dev/null;
        sleep 4;
        adb shell twrp sideload 2&> /dev/null;
        sleep 3;
        adb sideload $zipout/PlutoniumKernel.zip;
        sleep 5;
        adb reboot device;
      else
        echo "You must pack the zip first";
        continue;
      fi
    fi
  echo "Done!";
done;

clear;
