source "common.sh"                                                      
                                                                        
############################### CLI Params ###################################
ip_type=$1                                                                              
############################ USER-DEFINED Params ##############################
# Try to avoid defining values here, instead see if possible                   
# to determine the value dynamically                                           
CRYPTO_IP=''
case $ARCH in                                                        
esac                                                                 
case $DRIVER in                                                      
esac                                                              
case $SOC in                                  
am654)
      CRYPTO_IP='udma'
esac              
case $MACHINE in                                                              
esac
case $ip_type in
aes)
;;
esac
case $ip_type in                                                              
des|3des)
	if [ $SOC = "am43xx" ]
	then
		# the . is necesssary for not matching omap-dma-engine
		CRYPTO_IP='\.dma'
	else
		CRYPTO_IP='omap-dma-engine'
	fi
	;;
*)
	if [ $SOC != "am654" ]
	then
		# the . is necesssary for not matching omap-dma-engine
		CRYPTO_IP='\.dma'
	fi
	;;
esac                                                                          

echo $CRYPTO_IP
