
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
      MSIX=$6
      FUNCDIR=$CONFIGFS/pci_ep/functions/pci_epf_test/pf$IDX
      mkdir -p $FUNCDIR
      echo $VID > $FUNCDIR/vendorid
      echo $DEVID > $FUNCDIR/deviceid
      echo $MSI > $FUNCDIR/msi_interrupts
      echo $MSIX > $FUNCDIR/msix_interrupts
      ln -s $FUNCDIR $CONFIGFS/pci_ep/controllers/$EPCTRL/
      cat $FUNCDIR/deviceid
      [ "$(cat $FUNCDIR/deviceid)" != "$DEVID" ] && return 1 || return 0
}

create_epf_test_virt_func()
{
      PF=$1
      IDX=$2
      VID=$3
      DEVID=$4
      MSI=$5
      MSIX=$6
      FUNCDIR=$CONFIGFS/pci_ep/functions/pci_epf_test/vf$IDX
      mkdir -p $FUNCDIR
      echo $VID > $FUNCDIR/vendorid
      echo $DEVID > $FUNCDIR/deviceid
      echo $MSI > $FUNCDIR/msi_interrupts
      echo $MSIX > $FUNCDIR/msix_interrupts
      mkdir -p $CONFIGFS/pci_ep/functions/pci_epf_test/pf$PF
      ln -s $FUNCDIR $CONFIGFS/pci_ep/functions/pci_epf_test/pf$PF
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

get_msi_num_for_dev()
{
      IRQ_ARRAY=$1
      DEV=$2
      DEV_NUM=$(echo $DEV | cut -d'.' -f2)
      LOW=$(echo $IRQ_ARRAY | cut -d'.' -f $((DEV_NUM + 1)))
      HIGH=$(echo $IRQ_ARRAY | cut -d'.' -f $((DEV_NUM + 2)))
      echo $((HIGH -LOW))
}

get_msi_base()
{
      IRQ_ARRAY=$1
      DEV=$2
      DEV_NUM=$(echo $DEV | cut -d'.' -f2)
      echo $IRQ_ARRAY | cut -d'.' -f $((DEV_NUM + 1))
}

get_msi_interrupt_count()
{
      MSI=$1
      cat /proc/interrupts | grep MSI | sort -n -k 5 | sed -n "${MSI}p" | awk '{ print $2 }'
}

ep_test_msi()
{
      MSI=$1
      DEV=$2
      OFFSET=$(get_msi_base $MSI_ARRAY $DEV)
      OLD_COUNT=$(get_msi_interrupt_count $((MSI + OFFSET)))
      pcitest -D $DEV -m$MSI || return 1
      NEW_COUNT=$(get_msi_interrupt_count $((MSI + OFFSET)))
      if [ "$((OLD_COUNT + 1))" == "$NEW_COUNT" ]; then
              return 0
      else
              echo unexpected interrupt count for MSI \#$MSI
              echo expected $((OLD_COUNT + 1)), got $NEW_COUNT
              cat /proc/interrupts | grep MSI
              return 1
      fi
}


ep_test_msix()
{
      MSIX=$1
      DEV=$2
      OFFSET=$(get_msi_base $MSIX_ARRAY $DEV)
      OLD_COUNT=$(get_msi_interrupt_count $((MSIX + OFFSET)))
      pcitest -D $DEV -x$MSIX || return 1
      NEW_COUNT=$(get_msi_interrupt_count $((MSIX + OFFSET)))
      if [ "$((OLD_COUNT + 1))" == "$NEW_COUNT" ]; then
              return 0
      else
              echo unexpected interrupt count for MSI-X \#$MSIX
              echo expected $((OLD_COUNT + 1)), got $NEW_COUNT
              cat /proc/interrupts | grep MSI
              return 1
      fi
}

single_func_pcie_setup()
{
      mount_configfs
      [ $? !=  0 ] && return 1
      cleanup
      #create endpoint function
      EP_CTRL=$(ls /sys/class/pci_epc) #this logic assumes only one EP ctrl
      create_epf_test_func $EP_CTRL 1 0x104c 0xb500 16 16
      [ $? !=  0 ] && return 1
      export MSI_ARRAY="0.16"
      export MSIX_ARRAY="0.16"
      #start pcie ep ctrl
      pcie_ep_start $EP_CTRL
      # Remove bridge
      pci_remove_device 17cd 0200
      # rescan PCI
      echo 1 > /sys/bus/pci/rescan
}

multi_func_pcie_setup()
{
      mount_configfs
      [ $? !=  0 ] && return 1
      cleanup
      #create 2 endpoint functions (physical)
      EP_CTRL=$(ls /sys/class/pci_epc) #this logic assumes only one EP ctrl
      create_epf_test_func $EP_CTRL 1 0x104c 0xb500 16 16
      create_epf_test_func $EP_CTRL 2 0x104c 0xb500 16 16
      [ $? !=  0 ] && return 1
      export MSI_ARRAY="0.16.32"
      export MSIX_ARRAY="0.16.32"
      #start pcie ep ctrl
      pcie_ep_start $EP_CTRL
      # Remove bridge
      pci_remove_device 17cd 0200
      # rescan PCI
      echo 1 > /sys/bus/pci/rescan
}

virtual_func_pcie_setup()
{
      mount_configfs
      [ $? !=  0 ] && return 1
      cleanup
      #create endpoint functions (physical and virtual)
      EP_CTRL=$(ls /sys/class/pci_epc) #this logic assumes only one EP ctrl
      create_epf_test_virt_func 1 0   0x104c 0xb500 4 8
      create_epf_test_virt_func 1 1   0x104c 0xb500 4 8
      create_epf_test_func $EP_CTRL 1 0x104c 0xb500 16 16
      [ $? !=  0 ] && return 1
      export MSI_ARRAY="0.16.20.24"
      export MSIX_ARRAY="0.16.24.32"
      #start pcie ep ctrl
      pcie_ep_start $EP_CTRL
      # Remove bridge
      pci_remove_device 17cd 0200
      # rescan PCI
      echo 1 > /sys/bus/pci/rescan
      for f in /sys/bus/pci/devices/*/sriov_numvfs
      do
          echo 2 > $f
      done
}

cleanup()
{
      rm -f $CONFIGFS/pci_ep/controllers/*/pf* 2> /dev/null
      rm -f $CONFIGFS/pci_ep/functions/pci_epf_test/pf*/vf* 2> /dev/null
      rm -rf $CONFIGFS/pci_ep/functions/pci_epf_test/vf* 2> /dev/null
      rm -rf $CONFIGFS/pci_ep/functions/pci_epf_test/pf* 2> /dev/null
      # Remove bridge
      pci_remove_device 17cd 0200
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
            for t in $TEST_DEV
            do
                  do_cmd pcitest -b$i -D $t
            done
      done
}

msi_tests()
{
      for t in $TEST_DEV
      do
            LAST=$(get_msi_num_for_dev $MSI_ARRAY $t)
            [ -z "$LAST" ] && LAST=16
            for i in $(seq 1 1 $LAST)
            do
                  do_cmd ep_test_msi $i $t
            done
      done
}

msix_tests()
{
      for t in $TEST_DEV
      do
            LAST=$(get_msi_num_for_dev $MSIX_ARRAY $t)
            [ -z "$LAST" ] && LAST=16
            for i in $(seq 1 1 $LAST)
            do
                  do_cmd ep_test_msix $i $t
            done
      done
}

irq_tests()
{
      for t in $TEST_DEV
      do
            do_cmd pcitest $t -l -D $t
      done
}

read_tests()
{
      for s in 4 1024 1024000
      do
            for t in $TEST_DEV
            do
                  do_cmd pcitest -r -s$s -D $t
            done
      done
}

write_tests()
{
      for s in 4 1024 1024000
      do
            for t in $TEST_DEV
            do
                 do_cmd pcitest -w -s$s -D $t
            done
      done
}

copy_tests()
{
      for s in 4 1024 1024000
      do
            for t in $TEST_DEV
            do
                 do_cmd pcitest -c -s$s -D $t
            done
      done
}

read_unaligned_tests()
{
      for s in 1 5 1025 1024001
      do
            for t in $TEST_DEV
            do
                 do_cmd pcitest -r -s$s -D $t
            done
      done
}

write_unaligned_tests()
{
      for s in 1 5 1025 1024001
      do
            for t in $TEST_DEV
            do
                 do_cmd pcitest -w -s$s -D $t
            done
      done
}

copy_unaligned_tests()
{
      for s in 1 5 1025 1024001
      do
            for t in $TEST_DEV
            do
                 do_cmd pcitest -c -s$s -D $t
            done
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
        -x run MSIX tests
        -l run legacy IRQ tests
        -r run read tests
        -w run write tests
        -c run copy tests
        -s setup single function EP (if one of PCIe controllers is configured as an endpoint)
        -f setup multiple functions (if one of PCIe controllers is configured as an endpoint)
        -v setup virtual functions (if one of PCIe controllers is configured as an endpoint)
        -C cleanup
        -u allow unaligned sizes for read/write/copy tests
        -h Help      print this usage
EOF
exit 0
}

############################ Script Variables ##################################

TRIALS=1
IRQTYPE=1
TEST_DEV=""

################################ CLI Params ####################################
while getopts  :d:n:hbxmlrwcusfvC arg
do case $arg in
        n)      TRIALS="$OPTARG";;
        d)      TEST_DEV="$TEST_DEV $OPTARG";;
        b)      DO_BAR_TEST=1;;
        x)      IRQTYPE=2; DO_MSIX_TEST=1;;
        m)      IRQTYPE=1; DO_MSI_TEST=1;;
        l)      IRQTYPE=0; DO_IRQ_TEST=1;;
        r)      DO_READ_TEST=1;;
        w)      DO_WRITE_TEST=1;;
        c)      DO_COPY_TEST=1;;
        u)      export UNALIGNED=1;;
        s)      single_func_pcie_setup;;
        f)      multi_func_pcie_setup;;
        v)      virtual_func_pcie_setup;;
        C)      cleanup;;
        h)      usage;;
        \?)     die "Invalid Option -$OPTARG ";;
esac
done

[ -z "$TEST_DEV" ] && TEST_DEV="/dev/pci-endpoint-test.0"

########################### REUSABLE TEST LOGIC ###############################
# DO NOT HARDCODE any value. If you need to use a specific value for your setup
# use USER-DEFINED Params section above.

if [[ $TRIALS -le 0 ]]
then
  usage
fi

for t in /dev/pci-endpoint-test.* ; do pcitest -D $t -i$IRQTYPE; done

[ ! -z "$DO_BAR_TEST" ] && bar_tests
[ ! -z "$DO_MSIX_TEST" ] && msix_tests
[ ! -z "$DO_MSI_TEST" ] && msi_tests
[ ! -z "$DO_IRQ_TEST" ] && irq_tests
[ ! -z "$DO_READ_TEST" ] && read_tests
[ ! -z "$DO_READ_TEST" ] && [ "$UNALIGNED" == "1" ] && read_unaligned_tests
[ ! -z "$DO_WRITE_TEST" ] && write_tests
[ ! -z "$DO_WRITE_TEST" ] && [ "$UNALIGNED" == "1" ] && write_unaligned_tests
[ ! -z "$DO_COPY_TEST" ] && copy_tests
[ ! -z "$DO_COPY_TEST" ] && [ "$UNALIGNED" == "1" ] && copy_unaligned_tests

 exit 0
