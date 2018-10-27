echo "Available drives"
sudo fdisk -l
while true; do
    read -p "Which drive do you want to (un)mount? " drive
    break
done
echo "Would you like to mount (m) or unmount(u)?"
select u in "u" "m"; do
    case $u in
	u ) echo "Unmounting"; sudo umount /media/usb; break;; 
	m ) echo "Mounting";   sudo mount /dev/$drive /media/usb; break;;
    esac
done
echo "Done"
