# Single place to define test requirements associated with
# different platforms.

source "common.sh"

# Return names of power domain and its corresponding state that
# must be hit during system suspend.
# $1: platform
get_power_domain_states_on_suspend()
{
  platform=$1

  case $platform in
    dra7xx*|dra72x*|am57xx*)
      rtn="cam_pwrdm:OFF,mpu_pwrdm:RET,vpe_pwrdm:RET,cpu0_pwrdm:RET,gpu_pwrdm:OFF,l4per_pwrdm:RET,dss_pwrdm:RET,rtc_pwrdm:OFF,iva_pwrdm:OFF" ;;
    am335x*|beagle*|am43*)
      rtn="mpu_pwrdm:OFF,per_pwrdm:RET,gfx_pwrdm:OFF" ;;
  esac

  if [ -z "$rtn" ]; then
    die "Could not get power domain states requirements on suspend for $platform"
  fi

  echo "$rtn"
}
