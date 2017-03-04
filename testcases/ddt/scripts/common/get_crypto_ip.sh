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
esac              
case $MACHINE in                                                              
esac
case $ip_type in                                                              
des|3des)
	if [ $SOC = "am43xx" ]
	then
		CRYPTO_IP='edma'
	else
		CRYPTO_IP='omap-dma-engine'
	fi;;
*)
	CRYPTO_IP='edma';;
esac                                                                          

echo $CRYPTO_IP
