#!/bin/sh





#Displays account of the user
disp_account(){
echo "Your Wallet is:"
./geth --testnet --fast -exec "eth.accounts" attach 
}


#Check geth location
ETH=$(which geth)  
check_geth() {
    STATUS=""
    if [ -z $ETH ] && [ ! "$(ps -A | grep ether*)" ];  
    then
        STATUS="You need to install Ethereum CLI based on GoLang, or run Ethereum Wallet App"
    else 
        STATUS="OK"
    fi
    echo $STATUS
}

#Run ETHER server
run_server() {
    # execute eth and redirect all output to /dev/null
    if ! $ETH --testnet --exec 'console.log("OK")' attach 2&>/dev/null  
    then
        # run eth webserver 
        $ETH --testnet --ws --fast 2&> /tmp/wallet-server.log & 
        # get server process PID
        PID=`jobs -p`
        echo $1
        # until webserver is not created look for it
        until grep -q 'WebSocket endpoint opened:' /tmp/wallet-server.log
        do
            sleep 3
        done
        # save the URL of server for future requests
        URL=`grep 'WebSocket endpoint opened:'  /tmp/wallet-server.log | sed 's/^.*WebSocket endpoint opened: //'`
        echo $URL,$PID
    fi
}


#Unlock user account and send certain number of 'ether' 
send(){
SENDER=$1
RECEIVER=$2
AMOUNT=$3
PASSWD=$4


./geth --exec "personal.unlockAccount('$SENDER', '$PASSWD')" attach > /dev/null
TRANSACTION=`./geth --testnet --fast -exec "eth.sendTransaction({from: '$SENDER', to: '$RECEIVER', value: web3.toWei('$AMOUNT', 'ether')})" attach`
echo $TRANSACTION
}

#Help
help () {
    printf "Script: "$0" provides the possibility to send ether from one account to another\n"
}


cli_main(){

if [ ! -z $1 ] && [ $1 = "-h" ];
    then
        help
        exit
fi

STATUS=$(check_geth)
    if [[ $STATUS != *"OK" ]] || $([ ! -z $1 ] );
    then
        echo $STATUS
        exit 
fi

#Start server if Ethereum app is not running
if [ ! "$(ps -A | grep ether*)" ];
	then
	    SERVER=$(run_server)
	fi


while true
do
	printf "Please enter your account number:\n"
	read SENDER
	
	printf "Please enter the account of RECEIVER:\n"
        read RECEIVER

	printf "Please enter the AMOUNT to send:\n"
        read AMOUNT
        
        printf "Please enter your Account PASSWORD to Authorize:\n"
        read PASSWD


	TRANSACTION="$(send $SENDER $RECEIVER $AMOUNT $PASSWD)"
	echo "Transaction code is:"
	echo $TRANSACTION
	
	printf "Do you want make another transaction? Yes? press ( y ) or any letter and press enter.\n"
	read ANS
	if [ "$ANS" != "y" ];
        then
        printf "Thank you for choosing our service\n ************* \n"

            exit
	fi

done

} 


cli_main $*

