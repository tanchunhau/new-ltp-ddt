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
      rtn="cam_pwrdm:OFF,mpu_pwrdm:RET,vpe_pwrdm:OFF,cpu0_pwrdm:RET,gpu_pwrdm:OFF,dss_pwrdm:OFF,iva_pwrdm:OFF,dsp1_pwrdm:OFF,dsp2_pwrdm:OFF" ;;
    am335x*|beagle*|am43*)
      rtn="mpu_pwrdm:OFF,per_pwrdm:RET,gfx_pwrdm:OFF" ;;
  esac

  if [ -z "$rtn" ]; then
    die "Could not get power domain states requirements on suspend for $platform"
  fi

  echo "$rtn"
}

# Return max latency accepted for given use case and SoC
# $1: use case
get_acceptable_latency()
{
  local usecase=$1
  local max_latency
  case $usecase in
  *)
      case $SOC in
      *)
          max_latency=50 ;;
      esac
  esac
  echo "$max_latency"
}
