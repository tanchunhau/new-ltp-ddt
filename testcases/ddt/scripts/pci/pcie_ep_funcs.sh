
source "common.sh"  # Import do_cmd(), die() and other functions

export CONFIGFS="/sys/kernel/config"

mount_configfs()
{
    if ! grep -q -w $CONFIGFS /proc/mounts; then
        mount -t configfs none /sys/kernel/config
        [ $? !=  0 ] && return 1
    fi
    return 0
}

create_epf_test_func()
{
      EPCTRL=$1
      IDX=$2
      VID=$3
      DEVID=$4
      MSI=$5
      FUNCDIR=$CONFIGFS/pci_ep/functions/pci_epf_test/func$IDX
      mkdir -p $FUNCDIR
      echo $VID > $FUNCDIR/vendorid
      echo $DEVID > $FUNCDIR/deviceid
      echo $MSI > $FUNCDIR/msi_interrupts
      ln -s $FUNCDIR $CONFIGFS/pci_ep/controllers/$EPCTRL/
      cat $FUNCDIR/deviceid
      [ "$(cat $FUNCDIR/deviceid)" != "$DEVID" ] && return 1 || return 0
}


pcie_ep_start()
{
      EPCTRL=$1
      echo 1 > $CONFIGFS/pci_ep/controllers/$EPCTRL/start
}

pci_remove_device()
{
      VENDORID=$1
      DEVICEID=$2
      POS=$(lspci -n | grep "$VENDORID\:$DEVICEID" | cut -f1 -d' ')
      if [ ! -z "$POS" ] ; then
              for r in /sys/bus/pci/devices/*${POS}/remove ; do
                      echo 1 > $r
              done
      fi
}

get_msi_interrupt_count()
{
      MSI=$1
      FIRST_MSI=$(cat /proc/interrupts | grep MSI | head -n 1 | cut -f1 -d':')
      IRQ=$((FIRST_MSI + MSI -1))
      cat /proc/interrupts | grep " *$IRQ:" | awk '{print $2}'
}

ep_test_msi()
{
      MSI=$1
      OLD_COUNT=$(get_msi_interrupt_count $MSI)
      pcitest $TEST_DEV -m$MSI || return 1
      NEW_COUNT=$(get_msi_interrupt_count $MSI)
      if [ "$((OLD_COUNT + 1))" == "$NEW_COUNT" ]; then
              return 0
      else
              echo unexpected interrupt count for MSI \#$MSI
              echo expected $((OLD_COUNT + 1)), got $NEW_COUNT
              cat /proc/interrupts | grep MSI
              return 1
      fi
}

single_func_pcie_setup()
{
      mount_configfs
      [ $? !=  0 ] && return 1
      #create endpoint function
      EP_CTRL=$(ls /sys/class/pci_epc) #this logic assumes only one EP ctrl
      create_epf_test_func $EP_CTRL 1 0x104c 0xb500 16
      [ $? !=  0 ] && return 1
      #start pcie ep ctrl
      pcie_ep_start $EP_CTRL
      # Remove bridge
      pci_remove_device 17cd 0200
      # rescan PCI
      echo 1 > /sys/bus/pci/rescan
}

execute_multiple()
{
      for i in seq 1 $TRIALS
      do
              $*
      done
}

bar_tests()
{
      for i in $(seq 0 1 5)
      do
              do_cmd pcitest $TEST_DEV -b$i
      done
}

msi_tests()
{
      for i in $(seq 1 1 16)
      do
              do_cmd ep_test_msi $i
      done
}

irq_tests()
{
      do_cmd pcitest $TEST_DEV -l
}

read_tests()
{
      for s in 4 1024 1024000
      do
              do_cmd pcitest -r -s$s
      done
}

write_tests()
{
      for s in 4 1024 1024000
      do
              do_cmd pcitest -w -s$s
      done
}

copy_tests()
{
      for s in 4 1024 1024000
      do
              do_cmd pcitest -c -s$s
      done
}

read_unaligned_tests()
{
      for s in 1 5 1025 1024001
      do
              do_cmd pcitest -r -s$s
      done
}

write_unaligned_tests()
{
      for s in 1 5 1025 1024001
      do
              do_cmd pcitest -w -s$s
      done
}

copy_unaligned_tests()
{
      for s in 1 5 1025 1024001
      do
              do_cmd pcitest -c -s$s
      done
}

usage()
{
cat <<-EOF >&1
        usage: ./${0##*/} [-n TRIALS]
        -n TRIALS    Number of times to run the test
        -d device to test (ex: /dev/pci-endpoint-test.1)
        -b run BAR tests
        -m run MSI tests
        -l run legacy IRQ tests
        -r run read tests
        -w run write tests
        -c run copy tests
        -s setup single function EP (if one of PCIe controllers is configured as an endpoint)
        -u allow unaligned sizes for read/write/copy tests
        -h Help      print this usage
EOF
exit 0
}

############################ Script Variables ##################################

TRIALS=1
################################ CLI Params ####################################
while getopts  :d:n:hbmlrwcus arg
do case $arg in
        n)      export TRIALS="$OPTARG";;
        d)      export TEST_DEV="-D $OPTARG";;
        b)      DO_BAR_TEST=1;;
        m)      echo msi; DO_MSI_TEST=1;;
        l)      DO_IRQ_TEST=1;;
        r)      DO_READ_TEST=1;;
        w)      DO_WRITE_TEST=1;;
        c)      DO_COPY_TEST=1;;
        u)      export UNALIGNED=1;;
        s)      single_func_pcie_setup;;
        h)      usage;;
        \?)     die "Invalid Option -$OPTARG ";;
esac
done

########################### REUSABLE TEST LOGIC ###############################
# DO NOT HARDCODE any value. If you need to use a specific value for your setup
# use USER-DEFINED Params section above.

if [[ $TRIALS -le 0 ]]
then
  usage
fi

[ ! -z "$DO_BAR_TEST" ] && bar_tests
[ ! -z "$DO_MSI_TEST" ] && msi_tests
[ ! -z "$DO_IRQ_TEST" ] && irq_tests
[ ! -z "$DO_READ_TEST" ] && read_tests
[ ! -z "$DO_READ_TEST" ] && [ "$UNALIGNED" == "1" ] && read_unaligned_tests
[ ! -z "$DO_WRITE_TEST" ] && write_tests
[ ! -z "$DO_WRITE_TEST" ] && [ "$UNALIGNED" == "1" ] && write_unaligned_tests
[ ! -z "$DO_COPY_TEST" ] && copy_tests
[ ! -z "$DO_COPY_TEST" ] && [ "$UNALIGNED" == "1" ] && copy_unaligned_tests

 exit 0
